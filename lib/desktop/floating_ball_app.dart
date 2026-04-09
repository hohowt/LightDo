import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import '../services/lightdo_storage.dart';

class FloatingBallApp extends StatelessWidget {
  const FloatingBallApp({super.key, required this.mainWindowId});

  final String mainWindowId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FloatingBallHome(mainWindowId: mainWindowId),
    );
  }
}

class FloatingBallHome extends StatefulWidget {
  const FloatingBallHome({super.key, required this.mainWindowId});

  final String mainWindowId;

  @override
  State<FloatingBallHome> createState() => _FloatingBallHomeState();
}

class _FloatingBallHomeState extends State<FloatingBallHome>
    with WindowListener {
  final LightDoStorage _storage = const FileLightDoStorage();
  final SystemTray _systemTray = SystemTray();
  final Menu _trayMenu = Menu();
  final HotKey _toggleHotKey = HotKey(
    key: PhysicalKeyboardKey.keyT,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
  );

  WindowController? _currentController;
  bool _trayReady = false;
  bool _hotKeyEnabled = true;
  bool _launchAtStartupEnabled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    unawaited(hotKeyManager.unregisterAll());
    if (_trayReady && Platform.isWindows) {
      unawaited(_systemTray.destroy());
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    _currentController = await WindowController.fromCurrentEngine();
    await _currentController!.setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'refreshSettings':
          await _loadSettings();
          return null;
        case 'setBallOverlayState':
          final arguments =
              (call.arguments as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
          final coveredByMain = arguments['coveredByMain'] as bool? ?? false;
          await windowManager.setAlwaysOnTop(!coveredByMain);
          if (!coveredByMain) {
            await windowManager.show();
          }
          return null;
        default:
          throw MissingPluginException('Unknown method: ${call.method}');
      }
    });
    windowManager.addListener(this);
    await _loadSettings();
    if (Platform.isWindows) {
      await _setupTray();
    }
  }

  Future<void> _loadSettings() async {
    final snapshot = await _storage.load();
    _hotKeyEnabled = snapshot.settings.enableGlobalHotkey;
    _launchAtStartupEnabled = snapshot.settings.launchAtStartup;
    await _syncLaunchAtStartup();
    await _syncHotKey();
  }

  Future<void> _syncLaunchAtStartup() async {
    if (!Platform.isWindows) {
      return;
    }
    launchAtStartup.setup(
      appName: 'LightDo',
      appPath: Platform.resolvedExecutable,
    );
    final enabled = await launchAtStartup.isEnabled();
    if (_launchAtStartupEnabled && !enabled) {
      await launchAtStartup.enable();
      return;
    }
    if (!_launchAtStartupEnabled && enabled) {
      await launchAtStartup.disable();
    }
  }

  Future<void> _syncHotKey() async {
    await hotKeyManager.unregisterAll();
    if (!_hotKeyEnabled) {
      return;
    }
    await hotKeyManager.register(
      _toggleHotKey,
      keyDownHandler: (_) async {
        await _openMainWindow();
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
        await _openMainWindow();
      }
    });
    await _trayMenu.buildFrom([
      MenuItemLabel(
        label: '显示主窗口',
        onClicked: (_) async {
          await _openMainWindow();
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出 LightDo',
        onClicked: (_) async {
          await Future.wait([
            hotKeyManager.unregisterAll(),
            _systemTray.destroy(),
          ]);
          await windowManager.destroy();
          exit(0);
        },
      ),
    ]);
    await _systemTray.setContextMenu(_trayMenu);
    _trayReady = true;
  }

  Future<String> _ensureTrayIconPath() async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}lightdo_tray.ico',
    );
    if (!await file.exists()) {
      final bytes = await rootBundle.load('assets/windows/app_icon.ico');
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }
    return file.path;
  }

  Future<void> _openMainWindow() async {
    final controller = WindowController.fromWindowId(widget.mainWindowId);
    final position = await windowManager.getPosition();
    final size = await windowManager.getSize();
    final display = await _resolveDisplayForBall(position, size);
    final visiblePosition = display.visiblePosition ?? Offset.zero;
    final visibleSize = display.visibleSize ?? display.size;
    final centerX = position.dx + size.width / 2;
    final side = centerX >= visiblePosition.dx + visibleSize.width / 2
        ? 'right'
        : 'left';
    await controller.invokeMethod('showMainAtBall', {
      'ballX': position.dx,
      'ballY': position.dy,
      'ballWidth': size.width,
      'ballHeight': size.height,
      'visibleX': visiblePosition.dx,
      'visibleY': visiblePosition.dy,
      'visibleWidth': visibleSize.width,
      'visibleHeight': visibleSize.height,
      'anchorSide': side,
    });
  }

  Future<Display> _resolveDisplayForBall(Offset position, Size size) async {
    final displays = await screenRetriever.getAllDisplays();
    if (displays.isEmpty) {
      return screenRetriever.getPrimaryDisplay();
    }

    final ballCenter = Offset(
      position.dx + size.width / 2,
      position.dy + size.height / 2,
    );
    Display? bestDisplay;
    double? bestDistance;

    for (final display in displays) {
      final displayRect = _displayRect(display);
      if (displayRect.contains(ballCenter)) {
        return display;
      }
      final distance = _distanceToRect(ballCenter, displayRect);
      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        bestDisplay = display;
      }
    }

    return bestDisplay ?? screenRetriever.getPrimaryDisplay();
  }

  Rect _displayRect(Display display) {
    final position = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  double _distanceToRect(Offset point, Rect rect) {
    final dx = point.dx < rect.left
        ? rect.left - point.dx
        : point.dx > rect.right
        ? point.dx - rect.right
        : 0.0;
    final dy = point.dy < rect.top
        ? rect.top - point.dy
        : point.dy > rect.bottom
        ? point.dy - rect.bottom
        : 0.0;
    return dx * dx + dy * dy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: DragToMoveArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              unawaited(_openMainWindow());
            },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xD91A7A68), Color(0xD93CA692)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.82),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D6F5F).withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
