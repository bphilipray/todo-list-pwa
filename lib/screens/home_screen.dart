import 'package:flutter/material.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../widgets/quadrant_section.dart';
import '../widgets/filter_tabs.dart';

class HomeContent extends StatefulWidget {
  final List<Task> tasks;
  final List<Tag> tags;
  final String? selectedTagId;
  final TaskRepository repository;
  final Function(Task) onToggleComplete;
  final Function({Task? existingTask}) onEdit;
  final Function(Task) onDelete;
  final Function(Task) onToggleUrgent;
  final Function(Task) onToggleImportant;
  final VoidCallback onOpenDrawer;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddTask;
  final VoidCallback onClearTagFilter;

  const HomeContent({
    super.key,
    required this.tasks,
    required this.tags,
    required this.selectedTagId,
    required this.repository,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleUrgent,
    required this.onToggleImportant,
    required this.onOpenDrawer,
    required this.onRefresh,
    required this.onAddTask,
    required this.onClearTagFilter,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  TaskFilter _currentFilter = TaskFilter.all;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // Only count non-inbox tasks
  List<Task> get _nonInboxTasks {
    return widget.tasks.where((t) => t.quadrant != null).toList();
  }

  List<Task> _getFilteredTasks() {
    var filtered = widget.repository.filterTasks(widget.tasks, _currentFilter);

    // Apply tag filter
    if (widget.selectedTagId != null) {
      filtered = filtered.where((task) => task.tagIds.contains(widget.selectedTagId)).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final titleMatch = task.title.toLowerCase().contains(_searchQuery);
        final descriptionMatch =
            task.description?.toLowerCase().contains(_searchQuery) ?? false;
        return titleMatch || descriptionMatch;
      }).toList();
    }

    return filtered;
  }

  Tag? get _selectedTag {
    if (widget.selectedTagId == null) return null;
    return widget.tags.where((t) => t.id == widget.selectedTagId).firstOrNull;
  }

  List<Task> _getTasksForQuadrant(Quadrant quadrant) {
    final filtered = _getFilteredTasks();
    final quadrantTasks =
        widget.repository.getTasksByQuadrant(filtered, quadrant);
    return widget.repository.sortTasks(quadrantTasks);
  }

  Map<TaskFilter, int> _getFilterCounts() {
    return {
      TaskFilter.all: _nonInboxTasks.length,
      TaskFilter.active: _nonInboxTasks.where((t) => !t.completed).length,
      TaskFilter.completed: _nonInboxTasks.where((t) => t.completed).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _stopSearch,
              )
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: widget.onOpenDrawer,
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 18,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  filled: false,
                ),
              )
            : const Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _searchController.clear();
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: _startSearch,
            ),
            if (_nonInboxTasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    '${_nonInboxTasks.where((t) => t.completed).length}/${_nonInboxTasks.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: colors.surfaceLight,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Filter tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilterTabs(
                  currentFilter: _currentFilter,
                  onFilterChanged: (filter) {
                    setState(() => _currentFilter = filter);
                  },
                  counts: _getFilterCounts(),
                ),
              ),
            ),

            // Tag filter indicator
            if (_selectedTag != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTag!.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedTag!.color,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _selectedTag!.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTag!.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedTag!.color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onClearTagFilter,
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: _selectedTag!.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Quadrant sections
            SliverList(
              delegate: SliverChildListDelegate([
                QuadrantSection(
                  quadrant: Quadrant.urgentImportant,
                  tasks: _getTasksForQuadrant(Quadrant.urgentImportant),
                  allTags: widget.tags,
                  onToggleComplete: widget.onToggleComplete,
                  onEdit: (task) => widget.onEdit(existingTask: task),
                  onDelete: widget.onDelete,
                  onToggleUrgent: widget.onToggleUrgent,
                  onToggleImportant: widget.onToggleImportant,
                ),
                const SizedBox(height: 8),
                QuadrantSection(
                  quadrant: Quadrant.notUrgentImportant,
                  tasks: _getTasksForQuadrant(Quadrant.notUrgentImportant),
                  allTags: widget.tags,
                  onToggleComplete: widget.onToggleComplete,
                  onEdit: (task) => widget.onEdit(existingTask: task),
                  onDelete: widget.onDelete,
                  onToggleUrgent: widget.onToggleUrgent,
                  onToggleImportant: widget.onToggleImportant,
                ),
                const SizedBox(height: 8),
                QuadrantSection(
                  quadrant: Quadrant.urgentNotImportant,
                  tasks: _getTasksForQuadrant(Quadrant.urgentNotImportant),
                  allTags: widget.tags,
                  onToggleComplete: widget.onToggleComplete,
                  onEdit: (task) => widget.onEdit(existingTask: task),
                  onDelete: widget.onDelete,
                  onToggleUrgent: widget.onToggleUrgent,
                  onToggleImportant: widget.onToggleImportant,
                ),
                const SizedBox(height: 8),
                QuadrantSection(
                  quadrant: Quadrant.notUrgentNotImportant,
                  tasks: _getTasksForQuadrant(Quadrant.notUrgentNotImportant),
                  allTags: widget.tags,
                  onToggleComplete: widget.onToggleComplete,
                  onEdit: (task) => widget.onEdit(existingTask: task),
                  onDelete: widget.onDelete,
                  onToggleUrgent: widget.onToggleUrgent,
                  onToggleImportant: widget.onToggleImportant,
                ),
                const SizedBox(height: 100), // Space for FAB
              ]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddTask,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
      ),
    );
  }
}
