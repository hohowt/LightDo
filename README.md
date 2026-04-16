# LightDo

![Flutter](https://img.shields.io/badge/Flutter-3.41.6-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20Android-4C8CBF)
![Release](https://img.shields.io/badge/Release-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

一个以**本地优先**为核心设计理念的极简待办应用。数据始终存储在你的设备上，不依赖任何云服务或账号。局域网同步是可选的点对点能力，断网时应用完整可用。

## 本地优先

LightDo 的所有数据以 JSON 文件形式保存在本地：

- macOS：`~/Library/Application Support/LightDo/`
- Windows：`%APPDATA%\LightDo\`
- Linux：`~/.lightdo/`
- Android：应用私有目录（无需存储权限）

没有账号，没有云端，没有订阅。卸载即删除。

局域网同步基于 CRDT 算法，PC 与手机直接通信，数据不经过任何第三方服务器。离线时本地正常编辑，重新连接后自动合并。

## 功能

**待办管理**
- 新增、编辑、删除、完成 / 取消完成
- 未完成任务拖拽排序
- 已完成区折叠 / 展开、一键清空
- 截止时间与重复任务（每天 / 每周 / 每月）
- 临期与逾期状态提醒

**桌面体验（macOS / Windows / Linux）**
- 启动即显示悬浮球，点击展开主界面
- 悬浮球可自由拖动，支持多显示器
- 全局快捷键 `Alt+Shift+T`
- 主界面置顶、关闭回到悬浮球
- Windows：系统托盘、开机自启

**局域网同步（可选）**
- PC 端设置中开启同步，生成二维码
- Android 扫码连接，双向实时同步
- 基于 CRDT last-write-wins，离线编辑后自动合并
- 关闭开关即停止服务，无后台常驻

## 下载

前往 [GitHub Releases](../../releases) 下载对应平台产物：

| 平台 | 文件 |
|------|------|
| macOS (Apple Silicon) | `lightdo-vX.Y.Z-macos-arm64.zip` |
| macOS (Intel) | `lightdo-vX.Y.Z-macos-x64.zip` |
| Windows x64 | `lightdo-vX.Y.Z-windows-x64.zip` |
| Linux x64 | `lightdo-vX.Y.Z-linux-x64.tar.gz` |
| Android arm64 | `lightdo-vX.Y.Z-android-arm64.apk` |

## 本地开发

```bash
flutter pub get
flutter run -d macos      # 或 windows / linux / android
flutter analyze
flutter test
```

## 发布

在 `main` 分支打 tag 即可触发 GitHub Actions 自动构建所有平台：

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 技术栈

| 用途 | 包 |
|------|------|
| 跨平台框架 | Flutter 3.41.6 |
| 本地存储 | dart:io JSON |
| 局域网同步 | crdt + WebSocket |
| 悬浮球多窗口 | desktop_multi_window + window_manager |
| macOS 窗口定制 | bitsdojo_window |
| 全局快捷键 | hotkey_manager |
| Windows 托盘 | system_tray |
| 开机自启 | launch_at_startup |
| QR 显示 | qr_flutter |
| QR 扫描 | mobile_scanner |

## 项目结构

```
lib/
├── desktop/          # 悬浮球窗口、多窗口参数
├── models/           # 数据模型
├── services/         # 存储、桌面集成、同步、设备 ID
├── widgets/          # QR 扫描页
└── main.dart         # 主入口与主界面
```
