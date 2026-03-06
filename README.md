# 🎯 LightDo - 轻量级桌面待办应用

![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-Windows-0078D4)
![Electron](https://img.shields.io/badge/Electron-28.1.4-47848F?logo=electron&logoColor=white)
![React](https://img.shields.io/badge/React-18.2.0-61DAFB?logo=react&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-5.3.3-3178C6?logo=typescript&logoColor=white)

> 一个采用**悬浮球交互**设计的极简桌面待办应用。开箱即用，无需繁琐配置。

[English](./README_EN.md) | [中文](./README.md)

## ✨ 核心特性

- 🎯 **悬浮球交互** - 桌面右上角半透明悬浮球，点击即可快速访问待办列表
- ⚡ **开箱即用** - 解压即用，无需 Node.js、npm 等开发工具
- ✅ **完整待办功能** - 添加、编辑、删除、标记完成、拖拽排序
- 🎨 **毛玻璃 UI** - Windows Acrylic 玻璃效果，现代简约设计
- ⌨️ **全局快捷键** - `Alt+Shift+T` 一键呼出/隐藏待办窗口
- 💾 **本地存储** - JSON 文件自动保存，隐私安全无云上传
- 🚀 **后台运行** - 支持开机自启，静默后台运行不打扰工作
- 🪟 **深度集成** - 完美适配 Windows 10/11，占用资源极少

## 🚀 快速开始

### 方式一：便携版（推荐 - 最简单）

1. **下载最新版本**
   - 前往 [Releases](https://github.com/HappiLife-oh/LightDo/releases/latest)
   - 下载 `LightDo-portable.zip` 文件

2. **解压并运行**
   ```bash
   # Windows 资源管理器中解压文件
   # 双击 LightDo.exe 即可运行
   ```

3. **设置快捷键**（可选）
   - 运行 `创建快捷方式.vbs` 文件
   - 之后按 `Ctrl+Alt+L` 快速启动应用

### 方式二：开发者模式（需要 Node.js）

```bash
# 1. 克隆仓库
git clone https://github.com/HappiLife-oh/LightDo.git
cd LightDo

# 2. 安装依赖
npm install

# 3. 启动开发环境
npm run dev

# 4. 构建生产版本
npm run dist
```

## 💡 使用指南

### 基础操作

| 操作 | 说明 |
|------|------|
| 点击浮动球 | 显示/隐藏待办列表 |
| `Alt+Shift+T` | 全局快捷键，快速显示/隐藏 |
| 双击任务文本 | 编辑任务内容 |
| 拖拽任务 | 重新排序任务列表 |
| 勾选任务 | 标记任务完成/未完成 |
| 悬停任务 | 显示删除按钮 |

### 浮动球交互

- **位置**：屏幕右上角，可自由拖动
- **样式**：半透明紫色圆球（60×60 像素）
- **功能**：点击打开待办窗口，再点击或按快捷键隐藏

### 设置选项

- **开机自启** - 系统启动时自动运行应用
- **设置面板** - 点击主窗口右上角齿轮图标

## 🔧 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Electron | 28.1.4 | 跨平台桌面应用框架 |
| React | 18.2.0 | UI 框架 |
| TypeScript | 5.3.3 | 类型安全 |
| Vite | 5.0.11 | 前端构建工具 |
| @dnd-kit | 6.1.0 | 拖拽排序库 |

## 📂 项目结构

```
LightDo/
├── src/
│   ├── main/                # Electron 主进程
│   │   ├── index.ts         # 窗口管理、IPC
│   │   ├── preload.ts       # IPC 安全桥接
│   │   └── storage.ts       # 本地数据存储
│   ├── renderer/            # React 渲染进程
│   │   ├── components/      # React 组件
│   │   ├── styles/          # 样式文件
│   │   ├── App.tsx          # 主组件
│   │   └── floating-ball.tsx # 浮动球组件
│   └── shared/              # 共享类型定义
├── index.html               # 主窗口
├── floating-ball.html       # 浮动球窗口
├── package.json
├── vite.config.ts
└── electron-builder.yml     # 打包配置
```

## 🛠️ 开发

### 环境要求

- Node.js >= 16
- npm >= 7

### 开发命令

```bash
# 启动开发环境（包含热更新）
npm run dev

# 构建生产版本
npm run build

# 打包为便携版（无需安装）
npm run pack

# 打包为安装程序
npm run dist

# 类型检查
npm run type-check
```

### 开发工具

- 按 `F12` 打开开发者工具
- 按 `Ctrl+R` 刷新窗口
- 代码修改自动热更新

这将：
1. 编译主进程 TypeScript 代码
2. 启动 Vite 开发服务器 (http://localhost:5173)
3. 启动 Electron 应用

### 构建

```bash
# 构建（不打包）
npm run build

# 打包为可执行文件（开发测试）
npm run pack

# 打包为安装程序
npm run dist
```

打包后的文件位于 `release/` 目录。

## 📂 项目结构

```
LightDo/
├── src/
│   ├── main/              # Electron 主进程
│   │   ├── index.ts       # 主进程入口，窗口管理
│   │   ├── preload.ts     # Preload 脚本，IPC 桥接
│   │   └── storage.ts     # 本地数据存储
│   ├── renderer/          # React 渲染进程
│   │   ├── components/    # React 组件
│   │   │   ├── TodoInput.tsx
│   │   │   ├── TodoItem.tsx
│   │   │   ├── TodoList.tsx
│   │   │   ├── FloatingBall.tsx
│   │   │   └── Settings.tsx
│   │   ├── styles/        # 样式文件
│   │   │   ├── main.css
│   │   │   └── floating-ball.css
│   │   ├── App.tsx        # 主应用组件
│   │   ├── main.tsx       # 主窗口入口
│   │   ├── floating-ball.tsx  # 悬浮球入口
│   │   └── types.d.ts     # 类型声明
│   └── shared/            # 共享类型定义
│       └── types.ts
├── index.html             # 主窗口 HTML
├── floating-ball.html     # 悬浮球 HTML
├── package.json
├── tsconfig.json          # 渲染进程 TS 配置
├── tsconfig.main.json     # 主进程 TS 配置
├── vite.config.ts         # Vite 配置
└── electron-builder.yml   # 打包配置
```

## 🎨 功能说明

### 待办管理

- **添加任务** - 在输入框输入任务内容，按回车添加
- **完成任务** - 点击复选框标记为完成，任务变灰并显示删除线
- **编辑任务** - 双击任务文字进行编辑（已完成的任务不可编辑）
- **删除任务** - 鼠标悬停在任务上时显示删除按钮
- **拖拽排序** - 拖动任务左侧的拖拽手柄 (⋮⋮) 调整顺序
- **已完成任务** - 自动收纳到折叠区域，可展开查看或一键清空

### 窗口控制

- **悬浮球** - 可拖动到任意位置，点击弹出主窗口
- **主窗口** - 智能定位在悬浮球附近，不会超出屏幕边界
- **透明度** - 默认半透明，鼠标悬停时自动变为不透明
- **置顶显示** - 窗口始终置顶，不被其他窗口遮挡
- **点击外部隐藏** - 点击窗口外部区域自动隐藏

### 设置

- **开机自启** - 在设置面板中开启后，系统启动时自动运行（以隐藏模式）
- **全局快捷键** - Alt+Shift+T（已注册，无法修改）

## 💾 数据存储

所有待办数据保存在本地 JSON 文件中（**零云上传，完全私密**）：

**Windows 存储位置**：
```
C:\Users\<用户名>\AppData\Roaming\lightdo\lightdo-data.json
```

**数据格式**：
```json
{
  "todos": [
    {
      "id": "1234567890",
      "text": "完成项目文档",
      "completed": false,
      "createdAt": 1234567890000,
      "order": 0
    }
  ]
}
```

## ❓ 常见问题

### Q: 为什么启动时有缓存错误提示？
A: 这是 Chromium 的正常行为，不影响应用使用。提示会自动消失。

### Q: 能否在 Mac/Linux 上运行？
A: 目前仅支持 Windows。Electron 框架支持跨平台，后续可扩展到 macOS/Linux。

### Q: 数据会被上传到云端吗？
A: 不会。所有数据都存储在本地，完全隐私，无网络请求。

### Q: 能否修改快捷键？
A: 目前快捷键固定为 `Alt+Shift+T`。如需修改，可编辑源码中的 `src/main/index.ts` 文件。

### Q: 多用户环境下数据会冲突吗？
A: 不会。每个 Windows 用户各有独立的 AppData 目录，数据互不影响。

### Q: 如何完全卸载？
A: 便携版：直接删除文件夹即可。已安装版：使用 Windows 控制面板的"添加或删除程序"卸载。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 报告问题

如遇到 Bug，请在 [Issues](https://github.com/HappiLife-oh/LightDo/issues) 中提交，包含：
- 问题描述
- 复现步骤
- 截图或视频
- Windows 版本号

### 贡献代码

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交修改 (`git commit -m 'Add AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 🗺️ 规划路线

- [ ] **v1.1** - 任务分类/标签功能
- [ ] **v1.2** - 任务优先级和截止日期
- [ ] **v1.3** - 数据导出/导入（CSV、JSON）
- [ ] **v1.4** - 任务提醒（系统通知）
- [ ] **v2.0** - 跨设备同步（可选云端同步）
- [ ] **v2.1** - macOS/Linux 支持

## 📄 许可证

本项目采用 [MIT 许可证](./LICENSE) - 详见 LICENSE 文件

## 👨‍💻 作者

**HappiLife-oh** - [GitHub 主页](https://github.com/HappiLife-oh)

## 🙏 致谢

- [Electron](https://www.electronjs.org/) - 桌面应用框架
- [React](https://react.dev/) - UI 库
- [Vite](https://vitejs.dev/) - 构建工具
- [dnd-kit](https://docs.dndkit.com/) - 拖拽库

## 📞 联系方式

- 🐛 **报告 Bug**：[GitHub Issues](https://github.com/HappiLife-oh/LightDo/issues)
- 💬 **讨论功能**：[GitHub Discussions](https://github.com/HappiLife-oh/LightDo/discussions)
- ⭐ **喜欢本项目**？请给个 Star！

---

**如有帮助，请给予 Star ⭐ 支持！** 感谢！

## 🐛 常见问题

### 应用无法启动

- 确保已安装 Node.js 和 npm
- 运行 `npm install` 重新安装依赖
- 检查是否有其他 Electron 应用占用端口 5173

### 悬浮球不显示

- 检查悬浮球是否被移动到屏幕外
- 尝试按 Alt+Shift+T 唤出主窗口
- 重启应用

### 快捷键不生效

- 确保没有其他应用占用 Alt+Shift+T 组合键
- 以管理员权限运行应用

### 数据丢失

- 检查 `AppData/Roaming/lightdo/lightdo-data.json` 文件是否存在
- 定期备份该文件

## 📝 待实现功能

- [ ] 多种显示模式切换（悬浮球/边缘停靠/固定桌面）
- [ ] 浅色/深色主题切换
- [ ] 数据导出/导入功能
- [ ] 任务分类和标签
- [ ] 任务搜索功能
- [ ] 任务提醒和截止时间
- [ ] 云端同步支持

## 📄 许可

MIT License

## 🙏 致谢

- [Electron](https://www.electronjs.org/)
- [React](https://reactjs.org/)
- [Vite](https://vitejs.dev/)
- [@dnd-kit](https://dndkit.com/)
