import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_settings.dart';

DesktopIntegration createDesktopIntegration() {
  if (Platform.isWindows) {
    return WindowsDesktopIntegration();
  }
  return const NoopDesktopIntegration();
}

abstract class DesktopIntegration {
  const DesktopIntegration();

  Future<void> initialize(AppSettings settings);

  Future<void> applySettings(AppSettings settings);

  Future<void> dispose();
}

class NoopDesktopIntegration extends DesktopIntegration {
  const NoopDesktopIntegration();

  @override
  Future<void> applySettings(AppSettings settings) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize(AppSettings settings) async {}
}

class WindowsDesktopIntegration extends DesktopIntegration with WindowListener {
  WindowsDesktopIntegration();

  final WindowManager _windowManager = windowManager;
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  final HotKey _toggleHotKey = HotKey(
    key: PhysicalKeyboardKey.keyT,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
  );

  AppSettings _settings = AppSettings.defaults();
  bool _initialized = false;
  bool _disposed = false;
  bool _exiting = false;

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
  }

  @override
  Future<void> applySettings(AppSettings settings) async {
    _settings = settings;
    if (!_initialized || _disposed) {
      return;
    }

    await _windowManager.setAlwaysOnTop(settings.alwaysOnTop);
    await _windowManager.setPreventClose(settings.minimizeToTrayOnClose);
    await _syncLaunchAtStartup();
    await _syncHotKey();
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
    await hideToTray();
  }

  Future<void> toggleVisibility() async {
    final visible = await _windowManager.isVisible();
    if (visible) {
      await hideToTray();
      return;
    }
    await showAndFocus();
  }

  Future<void> showAndFocus() async {
    await _windowManager.setSkipTaskbar(false);
    await _windowManager.show();
    await _windowManager.focus();
  }

  Future<void> hideToTray() async {
    await _windowManager.setSkipTaskbar(true);
    await _windowManager.hide();
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
        await toggleVisibility();
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
        await toggleVisibility();
      }
    });
    await _syncTrayMenu();
  }

  Future<void> _syncTrayMenu() async {
    final visible = await _windowManager.isVisible();
    await _menu.buildFrom([
      MenuItemLabel(
        label: visible ? '隐藏窗口' : '显示窗口',
        onClicked: (_) async {
          await toggleVisibility();
        },
      ),
      MenuItemLabel(
        label: _settings.alwaysOnTop ? '取消置顶请到设置面板' : '置顶请到设置面板',
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
      await file.writeAsBytes(_uint8List(iconBytes), flush: true);
    }
    return file.path;
  }

  Uint8List _uint8List(ByteData byteData) {
    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }
}
