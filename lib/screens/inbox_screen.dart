import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_input_button.dart';

class InboxScreen extends StatefulWidget {
  final List<Task> tasks;
  final List<Tag> tags;
  final TaskRepository repository;
  final Function(String) onAddToInbox;
  final Function({Task? existingTask}) onEdit;
  final Function(Task) onDelete;
  final VoidCallback onOpenDrawer;

  const InboxScreen({
    super.key,
    required this.tasks,
    required this.tags,
    required this.repository,
    required this.onAddToInbox,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenDrawer,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _captureController = TextEditingController();
  final FocusNode _captureFocusNode = FocusNode();

  @override
  void dispose() {
    _captureController.dispose();
    _captureFocusNode.dispose();
    super.dispose();
  }

  List<Task> get _inboxItems {
    final items = widget.repository.getInboxTasks(widget.tasks);
    return widget.repository.sortInboxItems(items);
  }

  void _addToInbox() {
    final text = _captureController.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onAddToInbox(text);
      _captureController.clear();
      _captureFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: widget.onOpenDrawer,
        ),
        title: const Text(
          'Inbox',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_inboxItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.notUrgentImportant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_inboxItems.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.notUrgentImportant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick capture input
          _buildQuickCapture(colors),

          // Inbox items list
          Expanded(
            child: _inboxItems.isEmpty
                ? _buildEmptyState(colors)
                : _buildInboxList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCapture(AppColorTheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _captureController,
              focusNode: _captureFocusNode,
              style: TextStyle(
                fontSize: 16,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addToInbox(),
            ),
          ),
          const SizedBox(width: 8),
          // Voice input button
          VoiceInputButton(
            onResult: (text) {
              // Append transcribed text to existing input
              final currentText = _captureController.text;
              if (currentText.isEmpty) {
                _captureController.text = text;
              } else {
                _captureController.text = '$currentText $text';
              }
              _captureController.selection = TextSelection.fromPosition(
                TextPosition(offset: _captureController.text.length),
              );
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: colors.error,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Material(
            color: colors.notUrgentImportant,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _addToInbox,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(
                  Icons.add_rounded,
                  color: colors.isDark ? colors.textPrimary : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
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
            Icons.inbox_rounded,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Inbox is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture thoughts without worrying\nabout priority right now',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxList(AppColorTheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _inboxItems.length,
      itemBuilder: (context, index) {
        final item = _inboxItems[index];
        return _buildInboxItem(item, colors);
      },
    );
  }

  Widget _buildInboxItem(Task item, AppColorTheme colors) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(
          Icons.delete_rounded,
          color: colors.error,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        return await _showDeleteConfirmation(item, colors);
      },
      onDismissed: (direction) => widget.onDelete(item),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onEdit(existingTask: item);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textSecondary.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(Task item, AppColorTheme colors) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.surface,
            title: const Text('Delete Item'),
            content: Text('Delete "${item.title}"?'),
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
        ) ??
        false;
  }
}
