import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/tag.dart';
import '../models/task.dart';

/// Backup data structure for export/import
class BackupData {
  final int version;
  final DateTime exportedAt;
  final List<Task> tasks;
  final List<Tag> tags;

  BackupData({
    required this.version,
    required this.exportedAt,
    required this.tasks,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'tags': tags.map((t) => t.toJson()).toList(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as int,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      tasks: (json['tasks'] as List<dynamic>)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>)
          .map((t) => Tag.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Result of an import operation
class ImportResult {
  final bool success;
  final BackupData? data;
  final String? error;

  ImportResult.success(this.data)
      : success = true,
        error = null;

  ImportResult.failure(this.error)
      : success = false,
        data = null;
}

/// Service for exporting and importing backup data
class BackupService {
  static const int currentVersion = 1;

  /// Export tasks and tags to a shareable JSON file
  Future<bool> exportData({
    required List<Task> tasks,
    required List<Tag> tags,
  }) async {
    try {
      // Create backup data
      final backup = BackupData(
        version: currentVersion,
        exportedAt: DateTime.now(),
        tasks: tasks,
        tags: tags,
      );

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup.toJson());

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'task_matrix_backup_$timestamp.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Quadrant Backup',
        text: 'Quadrant backup from ${DateTime.now().toString().split('.').first}',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Import data from a JSON backup file
  Future<ImportResult> importData() async {
    try {
      // Pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult.failure('No file selected');
      }

      final file = result.files.first;

      String jsonString;

      // Handle file reading based on platform
      if (file.bytes != null) {
        // Web or memory-based file
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        // File system path available
        jsonString = await File(file.path!).readAsString();
      } else {
        return ImportResult.failure('Could not read file');
      }

      // Parse JSON
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return ImportResult.failure('Invalid JSON format');
      }

      // Validate structure
      if (!json.containsKey('version') ||
          !json.containsKey('tasks') ||
          !json.containsKey('tags')) {
        return ImportResult.failure('Invalid backup file format');
      }

      // Check version
      final version = json['version'] as int;
      if (version > currentVersion) {
        return ImportResult.failure(
            'Backup file is from a newer version of the app. Please update the app.');
      }

      // Parse backup data
      final backup = BackupData.fromJson(json);

      return ImportResult.success(backup);
    } catch (e) {
      return ImportResult.failure('Error reading backup: $e');
    }
  }

  /// Get backup file info without fully importing
  String getBackupSummary(BackupData backup) {
    final taskCount = backup.tasks.length;
    final tagCount = backup.tags.length;
    final completedCount = backup.tasks.where((t) => t.completed).length;

    return '$taskCount tasks ($completedCount completed), $tagCount tags';
  }
}
