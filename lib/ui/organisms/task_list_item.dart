import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('d MMM', 'id_ID').format(widget.task.startDate);
    String dateStr;
    if (widget.task.endDate != null) {
      final endStr = DateFormat(
        'd MMM yyyy',
        'id_ID',
      ).format(widget.task.endDate!);
      dateStr = '$startStr - $endStr';
    } else {
      dateStr = DateFormat('d MMM yyyy', 'id_ID').format(widget.task.startDate);
    }
    final badgeClass = widget.task.isCompleted
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEF3C7);
    final badgeColor = widget.task.isCompleted
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);
    final badgeText = widget.task.isCompleted ? 'Selesai' : 'Tertunda';

    return InkWell(
      onTap: widget.task.description != null
          ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: widget.task.isCompleted,
                    onChanged: widget.onToggle,
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.task.title,
                              style: TextStyle(
                                color: widget.task.isCompleted
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5)
                                    : Theme.of(context).colorScheme.onSurface,
                                decoration: widget.task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (widget.task.description != null) ...[
                            Icon(
                              _isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeClass,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (widget.task.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.task.category!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Hapus Tugas',
                ),
              ],
            ),
            if (_isExpanded && widget.task.description != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.task.description!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
