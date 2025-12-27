import 'package:shared_preferences/shared_preferences.dart';
import '../models/tag.dart';

class TagRepository {
  static const String _storageKey = 'task_matrix_tags';
  int _nextColorIndex = 0;

  Future<List<Tag>> loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final tags = Tag.decodeList(jsonString);
      // Update next color index based on existing tags
      if (tags.isNotEmpty) {
        _nextColorIndex = (tags.map((t) => t.colorIndex).reduce((a, b) => a > b ? a : b) + 1) % TagColors.palette.length;
      }
      return tags;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTags(List<Tag> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = Tag.encodeList(tags);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Creates a new tag with auto-assigned color
  Tag createTag(String name) {
    final tag = Tag(
      id: Tag.generateId(),
      name: name.trim(),
      colorIndex: _nextColorIndex,
    );
    _nextColorIndex = (_nextColorIndex + 1) % TagColors.palette.length;
    return tag;
  }

  /// Get the next color that will be assigned
  int getNextColorIndex() => _nextColorIndex;

  /// Sort tags alphabetically by name
  List<Tag> sortTags(List<Tag> tags) {
    final sorted = List<Tag>.from(tags);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  /// Get count of tasks using a specific tag
  int getTagTaskCount(List<String> taskTagIds, String tagId) {
    return taskTagIds.where((id) => id == tagId).length;
  }
}
