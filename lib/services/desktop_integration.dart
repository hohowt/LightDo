import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_settings.dart';

enum DesktopSurfaceMode {
  main,
  floatingBall,
}

DesktopIntegration createDesktopIntegration() {
  if (Platform.isWindows) {
    return WindowsDesktopIntegration();
  }
  return NoopDesktopIntegration();
}

abstract class DesktopIntegration {
  const DesktopIntegration();

  ValueListenable<DesktopSurfaceMode> get modeListenable;

  bool get supportsFloatingBallLauncher;

  Future<void> initialize(AppSettings settings);

  Future<void> applySettings(AppSettings settings);

  Future<void> showMainWindow();

  Future<void> showFloatingBall();

  Future<void> dispose();
}

class NoopDesktopIntegration extends DesktopIntegration {
  NoopDesktopIntegration();

  final ValueNotifier<DesktopSurfaceMode> _modeNotifier =
      ValueNotifier(DesktopSurfaceMode.main);

  @override
  ValueListenable<DesktopSurfaceMode> get modeListenable => _modeNotifier;

  @override
  bool get supportsFloatingBallLauncher => false;

  @override
  Future<void> applySettings(AppSettings settings) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize(AppSettings settings) async {}

  @override
  Future<void> showFloatingBall() async {}

  @override
  Future<void> showMainWindow() async {}
}

class WindowsDesktopIntegration extends DesktopIntegration with WindowListener {
  WindowsDesktopIntegration();

  static const Size _floatingBallSize = Size(76, 76);
  static const Size _mainWindowSize = Size(1180, 780);
  static const Size _mainWindowMinSize = Size(900, 620);
  static const double _screenPadding = 28;

  final WindowManager _windowManager = windowManager;
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  final ValueNotifier<DesktopSurfaceMode> _modeNotifier =
      ValueNotifier(DesktopSurfaceMode.floatingBall);
  final HotKey _toggleHotKey = HotKey(
    key: PhysicalKeyboardKey.keyT,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
  );

  AppSettings _settings = AppSettings.defaults();
  bool _initialized = false;
  bool _disposed = false;
  bool _exiting = false;

  @override
  ValueListenable<DesktopSurfaceMode> get modeListenable => _modeNotifier;

  @override
  bool get supportsFloatingBallLauncher => true;

  @override
  Future<void> initialize(AppSettings settings) async {
    if (_initialized) {
      await applySettings(settings);
      return;
    }

    _settings = settings;
    await _setupLaunchAtStartup();
    await _setupTray();
    _windowManager.addListener(this);
    _initialized = true;
    await applySettings(settings);
    await showFloatingBall();
  }

  @override
  Future<void> applySettings(AppSettings settings) async {
    _settings = settings;
    if (!_initialized || _disposed) {
      return;
    }

    await _windowManager.setPreventClose(settings.minimizeToTrayOnClose);
    await _syncLaunchAtStartup();
    await _syncHotKey();

    if (_modeNotifier.value == DesktopSurfaceMode.main) {
      await _windowManager.setAlwaysOnTop(settings.alwaysOnTop);
    }

    await _syncTrayMenu();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _windowManager.removeListener(this);
    await hotKeyManager.unregisterAll();
    await _systemTray.destroy();
  }

  @override
  Future<void> onWindowClose() async {
    if (_exiting || !_settings.minimizeToTrayOnClose) {
      await _cleanupAndDestroy();
      return;
    }
    await showFloatingBall();
  }

  Future<void> toggleSurface() async {
    if (_modeNotifier.value == DesktopSurfaceMode.floatingBall) {
      await showMainWindow();
      return;
    }
    await showFloatingBall();
  }

  @override
  Future<void> showMainWindow() async {
    final bounds = await _calculateMainWindowBounds();
    await _windowManager.setBackgroundColor(const Color(0xFFF4F1E8));
    await _windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await _windowManager.setResizable(true);
    await _windowManager.setMinimumSize(_mainWindowMinSize);
    await _windowManager.setBounds(bounds);
    await _windowManager.setAlwaysOnTop(_settings.alwaysOnTop);
    await _windowManager.setSkipTaskbar(false);
    await _windowManager.show();
    await _windowManager.focus();
    _modeNotifier.value = DesktopSurfaceMode.main;
    await _syncTrayMenu();
  }

  @override
  Future<void> showFloatingBall() async {
    final bounds = await _calculateFloatingBallBounds();
    await _windowManager.setBackgroundColor(Colors.transparent);
    await _windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await _windowManager.setResizable(false);
    await _windowManager.setMinimumSize(_floatingBallSize);
    await _windowManager.setBounds(bounds);
    await _windowManager.setAlwaysOnTop(true);
    await _windowManager.setSkipTaskbar(true);
    await _windowManager.show();
    await _windowManager.focus();
    _modeNotifier.value = DesktopSurfaceMode.floatingBall;
    await _syncTrayMenu();
  }

  Future<void> exitApplication() async {
    _exiting = true;
    await _cleanupAndDestroy();
  }

  Future<void> _cleanupAndDestroy() async {
    await hotKeyManager.unregisterAll();
    await _systemTray.destroy();
    await _windowManager.destroy();
  }

  Future<void> _setupLaunchAtStartup() async {
    launchAtStartup.setup(
      appName: 'LightDo',
      appPath: Platform.resolvedExecutable,
    );
  }

  Future<void> _syncLaunchAtStartup() async {
    final isEnabled = await launchAtStartup.isEnabled();
    if (_settings.launchAtStartup && !isEnabled) {
      await launchAtStartup.enable();
      return;
    }
    if (!_settings.launchAtStartup && isEnabled) {
      await launchAtStartup.disable();
    }
  }

  Future<void> _syncHotKey() async {
    await hotKeyManager.unregisterAll();
    if (!_settings.enableGlobalHotkey) {
      return;
    }
    await hotKeyManager.register(
      _toggleHotKey,
      keyDownHandler: (_) async {
        await toggleSurface();
      },
    );
  }

  Future<void> _setupTray() async {
    final iconPath = await _ensureTrayIconPath();
    await _systemTray.initSystemTray(
      title: 'LightDo',
      iconPath: iconPath,
      toolTip: 'LightDo',
    );
    _systemTray.registerSystemTrayEventHandler((eventName) async {
      if (eventName == kSystemTrayEventRightClick) {
        await _systemTray.popUpContextMenu();
        return;
      }
      if (eventName == kSystemTrayEventClick ||
          eventName == kSystemTrayEventDoubleClick) {
        await toggleSurface();
      }
    });
    await _syncTrayMenu();
  }

  Future<void> _syncTrayMenu() async {
    await _menu.buildFrom([
      MenuItemLabel(
        label: _modeNotifier.value == DesktopSurfaceMode.main
            ? '收起到悬浮球'
            : '显示主窗口',
        onClicked: (_) async {
          await toggleSurface();
        },
      ),
      MenuItemLabel(
        label: _settings.enableGlobalHotkey
            ? '快捷键: Alt+Shift+T'
            : '快捷键已关闭',
        enabled: false,
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出 LightDo',
        onClicked: (_) async {
          await exitApplication();
        },
      ),
    ]);
    await _systemTray.setContextMenu(_menu);
  }

  Future<String> _ensureTrayIconPath() async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}lightdo_tray.ico',
    );
    if (!await file.exists()) {
      final iconBytes = await rootBundle.load('assets/windows/app_icon.ico');
      await file.writeAsBytes(
        iconBytes.buffer.asUint8List(
          iconBytes.offsetInBytes,
          iconBytes.lengthInBytes,
        ),
        flush: true,
      );
    }
    return file.path;
  }

  Future<Rect> _calculateFloatingBallBounds() async {
    if (_modeNotifier.value == DesktopSurfaceMode.main) {
      final position = await _windowManager.getPosition();
      final size = await _windowManager.getSize();
      return Rect.fromLTWH(
        position.dx + size.width - _floatingBallSize.width - 18,
        position.dy + 14,
        _floatingBallSize.width,
        _floatingBallSize.height,
      );
    }

    final display = await screenRetriever.getPrimaryDisplay();
    final visiblePosition = display.visiblePosition ?? Offset.zero;
    final visibleSize = display.visibleSize ?? display.size;
    return Rect.fromLTWH(
      visiblePosition.dx +
          visibleSize.width -
          _floatingBallSize.width -
          _screenPadding,
      visiblePosition.dy + _screenPadding,
      _floatingBallSize.width,
      _floatingBallSize.height,
    );
  }

  Future<Rect> _calculateMainWindowBounds() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final visiblePosition = display.visiblePosition ?? Offset.zero;
    final visibleSize = display.visibleSize ?? display.size;

    if (_modeNotifier.value == DesktopSurfaceMode.floatingBall) {
      final position = await _windowManager.getPosition();
      final left = (position.dx + _floatingBallSize.width - _mainWindowSize.width)
          .clamp(
            visiblePosition.dx + _screenPadding,
            visiblePosition.dx +
                visibleSize.width -
                _mainWindowSize.width -
                _screenPadding,
          )
          .toDouble();
      final top = (position.dy + _floatingBallSize.height + 12)
          .clamp(
            visiblePosition.dy + _screenPadding,
            visiblePosition.dy +
                visibleSize.height -
                _mainWindowSize.height -
                _screenPadding,
          )
          .toDouble();
      return Rect.fromLTWH(
        left,
        top,
        _mainWindowSize.width,
        _mainWindowSize.height,
      );
    }

    final size = await _windowManager.getSize();
    final position = await _windowManager.getPosition();
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }
}
