import 'dart:convert';
import 'dart:io';

import '../models/app_snapshot.dart';
import '../models/todo_item.dart';
import 'lightdo_storage.dart';

Future<String> exportToJson(FileLightDoStorage storage) async {
  final snapshot = await storage.load();
  return const JsonEncoder.withIndent('  ').convert({
    'todos': snapshot.todos
        .where((t) => !t.isDeleted)
        .map((t) => t.toJson())
        .toList(growable: false),
    'settings': snapshot.settings.toJson(),
    'tags': snapshot.tags,
    'exportedAt': DateTime.now().toIso8601String(),
  });
}

String exportToMarkdown(AppSnapshot snapshot) {
  final buf = StringBuffer();
  buf.writeln('# LightDo 任务导出');
  buf.writeln();
  buf.writeln('导出时间: ${_formatDateTime(DateTime.now())}');
  buf.writeln();

  final active =
      snapshot.todos.where((t) => !t.isCompleted && !t.isDeleted).toList();
  final completed =
      snapshot.todos.where((t) => t.isCompleted && !t.isDeleted).toList();

  if (active.isNotEmpty) {
    buf.writeln('## 进行中 (${active.length})');
    buf.writeln();
    for (final todo in active) {
      buf.write('- ');
      if (todo.dueAt != null) {
        buf.write('**截止 ${_formatDateTime(todo.dueAt!)}** — ');
      }
      buf.write(todo.title);
      if (todo.tags.isNotEmpty) {
        buf.write(' `#${todo.tags.join(' #')}`');
      }
      if (todo.subTasks.isNotEmpty) {
        buf.writeln();
        for (final st in todo.subTasks) {
          buf.writeln('  - [${st.isCompleted ? 'x' : ' '}] ${st.title}');
        }
      } else {
        buf.writeln();
      }
    }
    buf.writeln();
  }

  if (completed.isNotEmpty) {
    buf.writeln('## 已完成 (${completed.length})');
    buf.writeln();
    for (final todo in completed) {
      buf.writeln('- ~~${todo.title}~~');
    }
    buf.writeln();
  }

  return buf.toString();
}

Future<bool> importFromJson(FileLightDoStorage storage, String content) async {
  try {
    final json = jsonDecode(content) as Map<String, dynamic>;
    final incomingTodos = (json['todos'] as List<dynamic>?)
            ?.map((t) => TodoItem.fromJson(t as Map<String, dynamic>))
            .toList(growable: false) ??
        [];
    if (incomingTodos.isEmpty) return false;

    final existing = await storage.load();
    final merged = <TodoItem>[...existing.todos, ...incomingTodos];

    await storage.save(AppSnapshot(
      todos: merged,
      settings: existing.settings,
      tags: json['tags'] as List<Map<String, dynamic>>? ?? existing.tags,
    ));
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> createBackup(FileLightDoStorage storage) async {
  final file = await storage.resolveFile();
  final backupFile = File(
    '${file.parent.path}${Platform.pathSeparator}lightdo_backup_${DateTime.now().millisecondsSinceEpoch}.json',
  );
  await file.copy(backupFile.path);
}

String _formatDateTime(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final h = value.hour.toString().padLeft(2, '0');
  final min = value.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}
