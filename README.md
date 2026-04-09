# LightDo

LightDo 当前分支为 Flutter 重构版，一个面向桌面场景的轻量待办应用。它优先实现稳定可交付的任务管理能力，而不是继续停留在原先 Electron 文档中的未验证设想。

## 当前已实现

- Flutter 桌面应用基础结构
- 待办新增、编辑、删除、完成/取消完成
- 未完成与已完成分组展示
- 未完成任务拖拽排序
- 已完成区域折叠/展开
- 一键清空已完成任务
- 本地 JSON 持久化
- 顶部统计信息与空状态展示
- 基础设置面板
- Windows 启动即悬浮球入口
- 悬浮球点击展开主窗口，关闭主窗口回到悬浮球
- Windows 托盘隐藏与恢复
- Windows 全局快捷键 `Alt+Shift+T`
- Windows 窗口置顶
- Windows 开机自启设置
- 主窗口改为非透明窗口，避免中文输入法异常
- `flutter analyze` 与 `flutter test` 通过

## 当前未实现

以下能力仍保留在规划中，本分支没有把它们伪装成已完成：

- 点击外部自动隐藏
- 智能贴边定位

## 开发环境

- Flutter 3.41.6
- Dart 3.11.4

## 本地运行

```bash
flutter pub get
flutter run -d macos
```

如果要构建桌面版本：

```bash
flutter build macos
flutter build windows
```

## 项目结构

```text
LightDo/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── app_settings.dart
│   │   ├── app_snapshot.dart
│   │   └── todo_item.dart
│   └── services/
│       └── lightdo_storage.dart
├── test/
│   └── widget_test.dart
├── macos/
├── windows/
└── docs/
    ├── 项目能力分析.md
    └── flutter重构-todolist.md
```

## 说明

- 原有 Electron 配置文件仍保留在仓库中，便于对照历史方案。
- 这条分支以 Flutter 版可运行待办应用为目标，不再把旧 README 中的桌面系统能力视为已实现事实。
- Windows 能力当前通过 Flutter 桌面插件实现，入口逻辑在 `lib/services/desktop_integration.dart`。
- 中文输入问题本轮通过取消主窗口透明背景并恢复正常窗口态处理。
