import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import '../theme/colors.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.todos});

  final List<TodoItem> todos;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final completed = todos.where((t) => t.isCompleted && !t.isDeleted).toList();
    final active = todos.where((t) => !t.isCompleted && !t.isDeleted).toList();
    final overdue =
        active.where((t) => t.deadlineStateAt(now) == TodoDeadlineState.overdue).length;

    final weekCompletions = _weekCompletionCounts(completed, now);
    final maxWeek = weekCompletions.fold<int>(0, (a, b) => a > b ? a : b);
    final streakDays = _currentStreak(completed, now);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBody,
      appBar: AppBar(
        title: const Text('统计'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatCard(label: '总完成', value: '${completed.length}', color: AppColors.emptyIcon),
                const SizedBox(width: 12),
                _StatCard(label: '进行中', value: '${active.length}', color: AppColors.composerIconActive),
                const SizedBox(width: 12),
                _StatCard(label: '已过期', value: '$overdue', color: AppColors.cardOverdueBadgeText),
              ],
            ),
            const SizedBox(height: 20),
            if (streakDays > 0) ...[
              _StatCard(
                label: '连续打卡',
                value: '$streakDays 天',
                color: AppColors.composerIconActive,
                fullWidth: true,
              ),
              const SizedBox(height: 20),
            ],
            Text('本周完成趋势', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            )),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final count = weekCompletions[i];
                  final dayNames = ['一', '二', '三', '四', '五', '六', '日'];
                  final isToday = (now.weekday - 1) == i;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$count', style: TextStyle(
                            fontSize: 11,
                            color: isToday ? AppColors.composerIconActive : AppColors.textMuted,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          )),
                          const SizedBox(height: 4),
                          Container(
                            height: maxWeek > 0 ? (count / maxWeek * 60).clamp(4.0, 60.0) : 4,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.composerIconActive
                                  : AppColors.composerIconActive.withValues(alpha: 0.3),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(dayNames[i], style: TextStyle(
                            fontSize: 11,
                            color: isToday ? AppColors.composerIconActive : AppColors.textMuted,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          )),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            Text('本月活跃热力图', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            )),
            const SizedBox(height: 12),
            _MonthlyHeatmap(todos: todos, now: now),
          ],
        ),
      ),
    );
  }

  List<int> _weekCompletionCounts(List<TodoItem> completed, DateTime now) {
    final counts = List.filled(7, 0);
    final monday = now.subtract(Duration(days: now.weekday - 1));
    for (final todo in completed) {
      final diff = todo.updatedAt.difference(monday).inDays;
      if (diff >= 0 && diff < 7) counts[diff]++;
    }
    return counts;
  }

  int _currentStreak(List<TodoItem> completed, DateTime now) {
    var streak = 0;
    var check = now;
    final completedDates = completed
        .map((t) => DateTime(t.updatedAt.year, t.updatedAt.month, t.updatedAt.day))
        .toSet();
    final today = DateTime(now.year, now.month, now.day);
    if (!completedDates.contains(today)) {
      check = now.subtract(const Duration(days: 1));
      final yesterday = DateTime(check.year, check.month, check.day);
      if (!completedDates.contains(yesterday)) return 0;
    }
    while (true) {
      final day = DateTime(check.year, check.month, check.day);
      if (completedDates.contains(day)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
    if (fullWidth) return SizedBox(width: double.infinity, child: child);
    return Expanded(child: child);
  }
}

class _MonthlyHeatmap extends StatelessWidget {
  const _MonthlyHeatmap({required this.todos, required this.now});

  final List<TodoItem> todos;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
    final completionCounts = <int, int>{};
    for (final todo in todos) {
      if (!todo.isCompleted && todo.isDeleted) continue;
      if (todo.updatedAt.year == now.year && todo.updatedAt.month == now.month) {
        final day = todo.updatedAt.day;
        completionCounts[day] = (completionCounts[day] ?? 0) + 1;
      }
    }
    final maxCount = completionCounts.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (var i = 1; i < firstWeekday; i++) const SizedBox(width: 16, height: 16),
        for (var day = 1; day <= daysInMonth; day++)
          Tooltip(
            message: '$day日: ${completionCounts[day] ?? 0} 项活动',
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _heatColor(completionCounts[day] ?? 0, maxCount),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }

  Color _heatColor(int count, int max) {
    if (count == 0) return AppColors.sectionBorder.withValues(alpha: 0.3);
    final intensity = max > 0 ? (count / max).clamp(0.1, 1.0) : 0.1;
    return Color.lerp(
      AppColors.emptyIcon.withValues(alpha: 0.2),
      AppColors.emptyIcon,
      intensity,
    )!;
  }
}
