import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/tag.dart';
import '../theme/app_theme.dart';

class TagPicker extends StatefulWidget {
  final List<Tag> availableTags;
  final List<String> selectedTagIds;
  final Function(List<String>) onTagsChanged;
  final Function(String name) onCreateTag;

  const TagPicker({
    super.key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onTagsChanged,
    required this.onCreateTag,
  });

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  bool _isCreating = false;
  final TextEditingController _newTagController = TextEditingController();
  final FocusNode _newTagFocus = FocusNode();

  @override
  void dispose() {
    _newTagController.dispose();
    _newTagFocus.dispose();
    super.dispose();
  }

  void _toggleTag(String tagId) {
    HapticFeedback.selectionClick();
    final newSelection = List<String>.from(widget.selectedTagIds);
    if (newSelection.contains(tagId)) {
      newSelection.remove(tagId);
    } else {
      newSelection.add(tagId);
    }
    widget.onTagsChanged(newSelection);
  }

  void _startCreating() {
    HapticFeedback.selectionClick();
    setState(() {
      _isCreating = true;
    });
    // Focus the text field after the widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newTagFocus.requestFocus();
    });
  }

  void _cancelCreating() {
    setState(() {
      _isCreating = false;
      _newTagController.clear();
    });
  }

  void _submitNewTag() {
    final colors = context.appColors;
    final name = _newTagController.text.trim();
    if (name.isEmpty) {
      _cancelCreating();
      return;
    }

    // Check for duplicate names
    final duplicate = widget.availableTags.any(
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
      _isCreating = false;
      _newTagController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Existing tags
        ...widget.availableTags.map((tag) => _buildTagChip(tag, colors)),

        // Create new tag button or input
        if (_isCreating)
          _buildNewTagInput(colors)
        else
          _buildAddTagButton(colors),
      ],
    );
  }

  Widget _buildTagChip(Tag tag, AppColorTheme colors) {
    final isSelected = widget.selectedTagIds.contains(tag.id);

    return GestureDetector(
      onTap: () => _toggleTag(tag.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? tag.color.withValues(alpha: 0.3)
              : colors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? tag.color : colors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            // Tag name
            Text(
              tag.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? tag.color : colors.textSecondary,
              ),
            ),
            // Checkmark for selected
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: tag.color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddTagButton(AppColorTheme colors) {
    return GestureDetector(
      onTap: _startCreating,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.surfaceLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'New',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTagInput(AppColorTheme colors) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: TextField(
              controller: _newTagController,
              focusNode: _newTagFocus,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Tag name',
                hintStyle: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colors.surfaceLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: colors.notUrgentImportant,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _submitNewTag(),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _submitNewTag,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.notUrgentImportant.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: colors.notUrgentImportant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _cancelCreating,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.surfaceLight.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
