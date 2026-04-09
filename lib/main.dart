import 'dart:async';

import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'models/app_snapshot.dart';
import 'models/todo_item.dart';
import 'services/lightdo_storage.dart';

void main() {
  runApp(const LightDoApp());
}

class LightDoApp extends StatelessWidget {
  const LightDoApp({super.key, this.storage});

  final LightDoStorage? storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LightDo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D6F5F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F1E8),
        fontFamily: 'SF Pro Display',
      ),
      home: LightDoHomePage(storage: storage ?? const FileLightDoStorage()),
    );
  }
}

class LightDoHomePage extends StatefulWidget {
  const LightDoHomePage({super.key, required this.storage});

  final LightDoStorage storage;

  @override
  State<LightDoHomePage> createState() => _LightDoHomePageState();
}

class _LightDoHomePageState extends State<LightDoHomePage> {
  final TextEditingController _inputController = TextEditingController();

  List<TodoItem> _todos = const [];
  AppSettings _settings = AppSettings.defaults();
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    try {
      final snapshot = await widget.storage.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _todos = snapshot.todos;
        _settings = snapshot.settings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = '本地数据读取失败，已回退为空列表。';
      });
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 240), () async {
      try {
        await widget.storage.save(
          AppSnapshot(todos: _todos, settings: _settings),
        );
        if (!mounted || _errorMessage == null) {
          return;
        }
        setState(() {
          _errorMessage = null;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage = '本地数据保存失败，请检查目录权限。';
        });
      }
    });
  }

  void _addTodo() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final nextTodo = TodoItem.create(title: text);
    setState(() {
      _todos = [nextTodo, ..._todos];
      _inputController.clear();
    });
    _scheduleSave();
  }

  void _toggleTodo(String id, bool selected) {
    setState(() {
      _todos = _todos
          .map((todo) => todo.id == id ? todo.copyWith(isCompleted: selected) : todo)
          .toList(growable: false);
    });
    _scheduleSave();
  }

  Future<void> _editTodo(TodoItem todo) async {
    final controller = TextEditingController(text: todo.title);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑任务'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '任务内容',
              hintText: '输入新的任务描述',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    final trimmed = nextTitle?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == todo.title) {
      return;
    }
    setState(() {
      _todos = _todos
          .map((item) => item.id == todo.id ? item.copyWith(title: trimmed) : item)
          .toList(growable: false);
    });
    _scheduleSave();
  }

  void _deleteTodo(String id) {
    setState(() {
      _todos = _todos.where((todo) => todo.id != id).toList(growable: false);
    });
    _scheduleSave();
  }

  Future<void> _clearCompleted() async {
    if (_settings.confirmBeforeClearingCompleted) {
      final shouldClear = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('清空已完成任务'),
                content: const Text('该操作只会删除已完成项，且无法恢复。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('清空'),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!shouldClear) {
        return;
      }
    }

    setState(() {
      _todos = _todos.where((todo) => !todo.isCompleted).toList(growable: false);
    });
    _scheduleSave();
  }

  void _reorderActiveTodos(int oldIndex, int newIndex) {
    final activeTodos = _activeTodos.toList(growable: true);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = activeTodos.removeAt(oldIndex);
    activeTodos.insert(newIndex, item);
    final completedTodos = _completedTodos;

    setState(() {
      _todos = [...activeTodos, ...completedTodos];
    });
    _scheduleSave();
  }

  void _updateSettings(AppSettings nextSettings) {
    setState(() {
      _settings = nextSettings;
    });
    _scheduleSave();
  }

  List<TodoItem> get _activeTodos =>
      _todos.where((todo) => !todo.isCompleted).toList(growable: false);

  List<TodoItem> get _completedTodos =>
      _todos.where((todo) => todo.isCompleted).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final activeTodos = _activeTodos;
    final completedTodos = _completedTodos;
    final completedRate = _todos.isEmpty ? 0 : ((completedTodos.length / _todos.length) * 100).round();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5EFE2),
              Color(0xFFE3EDE7),
              Color(0xFFDCE8F2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeaderSection(
                            totalCount: _todos.length,
                            activeCount: activeTodos.length,
                            completedCount: completedTodos.length,
                            completedRate: completedRate,
                            onOpenSettings: () => _openSettingsSheet(context),
                          ),
                          const SizedBox(height: 20),
                          _ComposerCard(
                            controller: _inputController,
                            onSubmit: _addTodo,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _InlineNotice(message: _errorMessage!),
                          ],
                          const SizedBox(height: 20),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 780;
                                final listPanel = _TaskPanel(
                                  title: '进行中',
                                  subtitle: '拖拽排序只作用于未完成任务',
                                  child: activeTodos.isEmpty
                                      ? const _EmptyState()
                                      : ReorderableListView.builder(
                                          buildDefaultDragHandles: false,
                                          itemCount: activeTodos.length,
                                          onReorder: _reorderActiveTodos,
                                          itemBuilder: (context, index) {
                                            final todo = activeTodos[index];
                                            return _TodoCard(
                                              key: ValueKey(todo.id),
                                              todo: todo,
                                              compact: _settings.compactMode,
                                              onToggle: (selected) => _toggleTodo(
                                                todo.id,
                                                selected,
                                              ),
                                              onEdit: () => _editTodo(todo),
                                              onDelete: () => _deleteTodo(todo.id),
                                              handle: ReorderableDragStartListener(
                                                index: index,
                                                child: const Icon(
                                                  Icons.drag_indicator_rounded,
                                                  color: Color(0xFF52796F),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                );

                                final completedPanel = _CompletedPanel(
                                  completedTodos: completedTodos,
                                  expanded: _settings.expandCompletedByDefault,
                                  compact: _settings.compactMode,
                                  onToggleExpanded: (value) => _updateSettings(
                                    _settings.copyWith(expandCompletedByDefault: value),
                                  ),
                                  onClearCompleted: completedTodos.isEmpty ? null : _clearCompleted,
                                  onToggleTodo: (todo, selected) =>
                                      _toggleTodo(todo.id, selected),
                                  onEditTodo: _editTodo,
                                  onDeleteTodo: (todo) => _deleteTodo(todo.id),
                                );

                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: listPanel),
                                      const SizedBox(width: 18),
                                      Expanded(flex: 2, child: completedPanel),
                                    ],
                                  );
                                }

                                return ListView(
                                  children: [
                                    SizedBox(height: 420, child: listPanel),
                                    const SizedBox(height: 18),
                                    completedPanel,
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettingsSheet(BuildContext context) async {
    final nextSettings = await showDialog<AppSettings>(
      context: context,
      builder: (context) => _SettingsDialog(settings: _settings),
    );
    if (nextSettings == null) {
      return;
    }
    _updateSettings(nextSettings);
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.completedRate,
    required this.onOpenSettings,
  });

  final int totalCount;
  final int activeCount;
  final int completedCount;
  final int completedRate;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LightDo',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF163832),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '桌面风格的 Flutter 待办应用，聚焦任务录入、整理与回顾。',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF4C635D),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.tune_rounded),
                tooltip: '设置',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatPill(label: '总任务', value: '$totalCount'),
              _StatPill(label: '进行中', value: '$activeCount'),
              _StatPill(label: '已完成', value: '$completedCount'),
              _StatPill(label: '完成率', value: '$completedRate%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: '输入新任务，回车即可添加',
                prefixIcon: Icon(Icons.add_task_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173C35),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF66807A),
                ),
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CompletedPanel extends StatelessWidget {
  const _CompletedPanel({
    required this.completedTodos,
    required this.expanded,
    required this.compact,
    required this.onToggleExpanded,
    required this.onClearCompleted,
    required this.onToggleTodo,
    required this.onEditTodo,
    required this.onDeleteTodo,
  });

  final List<TodoItem> completedTodos;
  final bool expanded;
  final bool compact;
  final ValueChanged<bool> onToggleExpanded;
  final Future<void> Function(TodoItem todo) onEditTodo;
  final Future<void> Function()? onClearCompleted;
  final void Function(TodoItem todo, bool selected) onToggleTodo;
  final void Function(TodoItem todo) onDeleteTodo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已完成',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF173C35),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '支持折叠查看与批量清理。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF66807A),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onToggleExpanded(!expanded),
                icon: Icon(
                  expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                ),
                tooltip: expanded ? '折叠' : '展开',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expanded) ...[
            if (completedTodos.isEmpty)
              const _MiniEmptyState(message: '已完成任务会收纳在这里。')
            else
              Column(
                children: completedTodos
                    .map(
                      (todo) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TodoCard(
                          todo: todo,
                          compact: compact,
                          onToggle: (selected) => onToggleTodo(todo, selected),
                          onEdit: () => onEditTodo(todo),
                          onDelete: () => onDeleteTodo(todo),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ] else
            const _MiniEmptyState(message: '已折叠，点击右上角展开查看。'),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onClearCompleted,
            icon: const Icon(Icons.delete_sweep_rounded),
            label: const Text('清空已完成'),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    super.key,
    required this.todo,
    required this.compact,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.handle,
  });

  final TodoItem todo;
  final bool compact;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? handle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: todo.isCompleted ? const Color(0xFF6F837D) : const Color(0xFF203B35),
          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      child: Row(
        children: [
          if (handle != null) ...[
            handle!,
            const SizedBox(width: 8),
          ],
          Checkbox(
            value: todo.isCompleted,
            onChanged: (value) => onToggle(value ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(todo.title, style: titleStyle),
                const SizedBox(height: 4),
                Text(
                  todo.summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF728781),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '删除',
          ),
        ],
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.settings});

  final AppSettings settings;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late AppSettings _draft = widget.settings;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: _draft.expandCompletedByDefault,
              title: const Text('默认展开已完成区域'),
              subtitle: const Text('控制已完成任务区是否默认展开。'),
              onChanged: (value) {
                setState(() {
                  _draft = _draft.copyWith(expandCompletedByDefault: value);
                });
              },
            ),
            SwitchListTile(
              value: _draft.confirmBeforeClearingCompleted,
              title: const Text('清空已完成前弹出确认'),
              subtitle: const Text('避免误删已完成任务。'),
              onChanged: (value) {
                setState(() {
                  _draft = _draft.copyWith(
                    confirmBeforeClearingCompleted: value,
                  );
                });
              },
            ),
            SwitchListTile(
              value: _draft.compactMode,
              title: const Text('紧凑显示'),
              subtitle: const Text('减小列表项间距，适合窄窗口。'),
              onChanged: (value) {
                setState(() {
                  _draft = _draft.copyWith(compactMode: value);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_draft),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF70837E),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF183A33),
                ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD29A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFAF6700)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checklist_rounded,
                size: 40,
                color: Color(0xFF2E6C60),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '现在没有进行中的任务',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173C35),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '从上方输入框添加第一条任务，或把已完成任务重新勾回进行中。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6D827C),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniEmptyState extends StatelessWidget {
  const _MiniEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF70837E),
            ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.76),
        Colors.white.withValues(alpha: 0.58),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF28443F).withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 16),
      ),
    ],
  );
}
