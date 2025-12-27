import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TagsScreen extends StatefulWidget {
  final List<Tag> tags;
  final List<Task> tasks;
  final Function(String name) onCreateTag;
  final Function(Tag tag, String newName) onUpdateTag;
  final Function(Tag tag) onDeleteTag;
  final VoidCallback onOpenDrawer;

  const TagsScreen({
    super.key,
    required this.tags,
    required this.tasks,
    required this.onCreateTag,
    required this.onUpdateTag,
    required this.onDeleteTag,
    required this.onOpenDrawer,
  });

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  bool _isAddingTag = false;
  final TextEditingController _newTagController = TextEditingController();
  final FocusNode _newTagFocus = FocusNode();
  String? _editingTagId;
  final TextEditingController _editTagController = TextEditingController();

  @override
  void dispose() {
    _newTagController.dispose();
    _newTagFocus.dispose();
    _editTagController.dispose();
    super.dispose();
  }

  int _getTaskCountForTag(String tagId) {
    return widget.tasks.where((t) => t.tagIds.contains(tagId)).length;
  }

  void _startAdding() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAddingTag = true;
      _editingTagId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newTagFocus.requestFocus();
    });
  }

  void _cancelAdding() {
    setState(() {
      _isAddingTag = false;
      _newTagController.clear();
    });
  }

  void _submitNewTag() {
    final colors = context.appColors;
    final name = _newTagController.text.trim();
    if (name.isEmpty) {
      _cancelAdding();
      return;
    }

    final duplicate = widget.tags.any(
      (t) => t.name.toLowerCase() == name.toLowerCase(),
    );

    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('A tag with this name already exists'),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    widget.onCreateTag(name);
    setState(() {
      _isAddingTag = false;
      _newTagController.clear();
    });
  }

  void _startEditing(Tag tag) {
    HapticFeedback.selectionClick();
    setState(() {
      _editingTagId = tag.id;
      _editTagController.text = tag.name;
      _isAddingTag = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingTagId = null;
      _editTagController.clear();
    });
  }

  void _submitEdit(Tag tag) {
    final colors = context.appColors;
    final newName = _editTagController.text.trim();
    if (newName.isEmpty) {
      _cancelEditing();
      return;
    }

    if (newName.toLowerCase() == tag.name.toLowerCase()) {
      _cancelEditing();
      return;
    }

    final duplicate = widget.tags.any(
      (t) => t.id != tag.id && t.name.toLowerCase() == newName.toLowerCase(),
    );

    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('A tag with this name already exists'),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    widget.onUpdateTag(tag, newName);
    setState(() {
      _editingTagId = null;
      _editTagController.clear();
    });
  }

  Future<void> _confirmDelete(Tag tag, AppColorTheme colors) async {
    final taskCount = _getTaskCountForTag(tag.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Delete Tag'),
        content: Text(
          taskCount > 0
              ? 'Delete "${tag.name}"? This will remove it from $taskCount task${taskCount > 1 ? 's' : ''}.'
              : 'Delete "${tag.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDeleteTag(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sortedTags = List<Tag>.from(widget.tags)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: widget.onOpenDrawer,
        ),
        title: const Text(
          'Manage Tags',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isAddingTag)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _startAdding,
            ),
        ],
      ),
      body: sortedTags.isEmpty && !_isAddingTag
          ? _buildEmptyState(colors)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Add new tag input
                if (_isAddingTag) ...[
                  _buildNewTagInput(colors),
                  const SizedBox(height: 16),
                ],

                // Existing tags
                ...sortedTags.map((tag) => _buildTagItem(tag, colors)),
              ],
            ),
    );
  }

  Widget _buildEmptyState(AppColorTheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_outline_rounded,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No tags yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create tags to organize your tasks',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startAdding,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Tag'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.notUrgentImportant,
              foregroundColor: colors.isDark ? colors.textPrimary : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTagInput(AppColorTheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Color preview (next color)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: TagColors.palette[widget.tags.length % TagColors.palette.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Input
            Expanded(
              child: TextField(
                controller: _newTagController,
                focusNode: _newTagFocus,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Tag name',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (_) => _submitNewTag(),
              ),
            ),
            // Confirm
            IconButton(
              onPressed: _submitNewTag,
              icon: const Icon(Icons.check_rounded),
              color: colors.success,
              iconSize: 22,
            ),
            // Cancel
            IconButton(
              onPressed: _cancelAdding,
              icon: const Icon(Icons.close_rounded),
              color: colors.textSecondary,
              iconSize: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagItem(Tag tag, AppColorTheme colors) {
    final taskCount = _getTaskCountForTag(tag.id);
    final isEditing = _editingTagId == tag.id;

    return Dismissible(
      key: Key(tag.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_rounded, color: colors.error, size: 24),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.lightImpact();
        await _confirmDelete(tag, colors);
        return false; // Handle deletion manually
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => _startEditing(tag),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Color dot
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: tag.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),

                // Name (or edit input)
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: _editTagController,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _submitEdit(tag),
                        )
                      : Text(
                          tag.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                ),

                // Task count or edit actions
                if (isEditing) ...[
                  IconButton(
                    onPressed: () => _submitEdit(tag),
                    icon: const Icon(Icons.check_rounded),
                    color: colors.success,
                    iconSize: 22,
                  ),
                  IconButton(
                    onPressed: _cancelEditing,
                    icon: const Icon(Icons.close_rounded),
                    color: colors.textSecondary,
                    iconSize: 22,
                  ),
                ] else ...[
                  // Task count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tag.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$taskCount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tag.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
