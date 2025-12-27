import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tag.dart';
import '../models/task.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncResult {
  final bool success;
  final String? error;
  final int tasksUploaded;
  final int tagsUploaded;
  final int tasksDownloaded;
  final int tagsDownloaded;

  SyncResult({
    required this.success,
    this.error,
    this.tasksUploaded = 0,
    this.tagsUploaded = 0,
    this.tasksDownloaded = 0,
    this.tagsDownloaded = 0,
  });

  factory SyncResult.failure(String error) => SyncResult(
        success: false,
        error: error,
      );

  factory SyncResult.success({
    int tasksUploaded = 0,
    int tagsUploaded = 0,
    int tasksDownloaded = 0,
    int tagsDownloaded = 0,
  }) =>
      SyncResult(
        success: true,
        tasksUploaded: tasksUploaded,
        tagsUploaded: tagsUploaded,
        tasksDownloaded: tasksDownloaded,
        tagsDownloaded: tagsDownloaded,
      );
}

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isAuthenticated => _userId != null;

  // Get user's tasks collection reference
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('tasks');
  }

  // Get user's tags collection reference
  CollectionReference<Map<String, dynamic>> get _tagsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('tags');
  }

  // Get user's metadata document reference
  DocumentReference<Map<String, dynamic>> get _metadataDoc {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId);
  }

  // Upload all tasks and tags to cloud (full sync)
  Future<SyncResult> uploadAll({
    required List<Task> tasks,
    required List<Tag> tags,
  }) async {
    if (!isAuthenticated) {
      return SyncResult.failure('Not authenticated');
    }

    try {
      final batch = _firestore.batch();

      // Upload tasks
      for (final task in tasks) {
        final docRef = _tasksCollection.doc(task.id);
        batch.set(docRef, _taskToFirestore(task));
      }

      // Upload tags
      for (final tag in tags) {
        final docRef = _tagsCollection.doc(tag.id);
        batch.set(docRef, _tagToFirestore(tag));
      }

      // Update metadata
      batch.set(_metadataDoc, {
        'lastSyncAt': FieldValue.serverTimestamp(),
        'taskCount': tasks.length,
        'tagCount': tags.length,
      }, SetOptions(merge: true));

      await batch.commit();

      return SyncResult.success(
        tasksUploaded: tasks.length,
        tagsUploaded: tags.length,
      );
    } catch (e) {
      return SyncResult.failure('Upload failed: $e');
    }
  }

  // Download all tasks and tags from cloud
  Future<({List<Task> tasks, List<Tag> tags, SyncResult result})> downloadAll() async {
    if (!isAuthenticated) {
      return (
        tasks: <Task>[],
        tags: <Tag>[],
        result: SyncResult.failure('Not authenticated'),
      );
    }

    try {
      // Download tasks
      final tasksSnapshot = await _tasksCollection.get();
      final tasks = tasksSnapshot.docs
          .map((doc) => _taskFromFirestore(doc.id, doc.data()))
          .toList();

      // Download tags
      final tagsSnapshot = await _tagsCollection.get();
      final tags = tagsSnapshot.docs
          .map((doc) => _tagFromFirestore(doc.id, doc.data()))
          .toList();

      return (
        tasks: tasks,
        tags: tags,
        result: SyncResult.success(
          tasksDownloaded: tasks.length,
          tagsDownloaded: tags.length,
        ),
      );
    } catch (e) {
      return (
        tasks: <Task>[],
        tags: <Tag>[],
        result: SyncResult.failure('Download failed: $e'),
      );
    }
  }

  // Sync: merge local and cloud data
  Future<({List<Task> tasks, List<Tag> tags, SyncResult result})> sync({
    required List<Task> localTasks,
    required List<Tag> localTags,
  }) async {
    if (!isAuthenticated) {
      return (
        tasks: localTasks,
        tags: localTags,
        result: SyncResult.failure('Not authenticated'),
      );
    }

    try {
      // Download cloud data
      final cloudData = await downloadAll();
      if (!cloudData.result.success) {
        return (
          tasks: localTasks,
          tags: localTags,
          result: cloudData.result,
        );
      }

      // Merge tasks (local wins for conflicts based on task ID)
      final mergedTasks = _mergeTasks(localTasks, cloudData.tasks);

      // Merge tags (local wins for conflicts based on tag ID)
      final mergedTags = _mergeTags(localTags, cloudData.tags);

      // Upload merged data
      final uploadResult = await uploadAll(
        tasks: mergedTasks,
        tags: mergedTags,
      );

      if (!uploadResult.success) {
        return (
          tasks: localTasks,
          tags: localTags,
          result: uploadResult,
        );
      }

      return (
        tasks: mergedTasks,
        tags: mergedTags,
        result: SyncResult.success(
          tasksUploaded: mergedTasks.length,
          tagsUploaded: mergedTags.length,
          tasksDownloaded: cloudData.tasks.length,
          tagsDownloaded: cloudData.tags.length,
        ),
      );
    } catch (e) {
      return (
        tasks: localTasks,
        tags: localTags,
        result: SyncResult.failure('Sync failed: $e'),
      );
    }
  }

  // Delete all cloud data for current user
  Future<bool> deleteAllCloudData() async {
    if (!isAuthenticated) return false;

    try {
      // Delete all tasks
      final tasksSnapshot = await _tasksCollection.get();
      for (final doc in tasksSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all tags
      final tagsSnapshot = await _tagsCollection.get();
      for (final doc in tagsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Update metadata
      await _metadataDoc.set({
        'lastSyncAt': FieldValue.serverTimestamp(),
        'taskCount': 0,
        'tagCount': 0,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _metadataDoc.get();
      if (!doc.exists) return null;

      final timestamp = doc.data()?['lastSyncAt'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      return null;
    }
  }

  // Merge tasks: combine local and cloud, local wins for same ID
  List<Task> _mergeTasks(List<Task> local, List<Task> cloud) {
    final Map<String, Task> merged = {};

    // Add cloud tasks first
    for (final task in cloud) {
      merged[task.id] = task;
    }

    // Override with local tasks (local wins)
    for (final task in local) {
      merged[task.id] = task;
    }

    return merged.values.toList();
  }

  // Merge tags: combine local and cloud, local wins for same ID
  List<Tag> _mergeTags(List<Tag> local, List<Tag> cloud) {
    final Map<String, Tag> merged = {};

    // Add cloud tags first
    for (final tag in cloud) {
      merged[tag.id] = tag;
    }

    // Override with local tags (local wins)
    for (final tag in local) {
      merged[tag.id] = tag;
    }

    return merged.values.toList();
  }

  // Convert Task to Firestore document
  Map<String, dynamic> _taskToFirestore(Task task) {
    final json = task.toJson();
    // Convert DateTime to Timestamp for Firestore
    if (json['createdAt'] != null) {
      json['createdAt'] = Timestamp.fromDate(DateTime.parse(json['createdAt']));
    }
    if (json['dueDate'] != null) {
      json['dueDate'] = Timestamp.fromDate(DateTime.parse(json['dueDate']));
    }
    return json;
  }

  // Convert Firestore document to Task
  Task _taskFromFirestore(String id, Map<String, dynamic> data) {
    // Convert Timestamps back to ISO strings
    final json = Map<String, dynamic>.from(data);
    if (json['createdAt'] is Timestamp) {
      json['createdAt'] = (json['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (json['dueDate'] is Timestamp) {
      json['dueDate'] = (json['dueDate'] as Timestamp).toDate().toIso8601String();
    }
    json['id'] = id;
    return Task.fromJson(json);
  }

  // Convert Tag to Firestore document
  Map<String, dynamic> _tagToFirestore(Tag tag) {
    return tag.toJson();
  }

  // Convert Firestore document to Tag
  Tag _tagFromFirestore(String id, Map<String, dynamic> data) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id;
    return Tag.fromJson(json);
  }
}
