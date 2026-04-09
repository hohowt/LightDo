import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../desktop/window_arguments.dart';
import '../models/app_settings.dart';

DesktopIntegration createDesktopIntegration({
  WindowController? currentWindowController,
  bool enabled = true,
}) {
  if (!enabled) {
    return const NoopDesktopIntegration();
  }
  if (Platform.isWindows || Platform.isMacOS) {
    return MainDesktopIntegration(currentWindowController);
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

class MainDesktopIntegration extends DesktopIntegration with WindowListener {
  MainDesktopIntegration(this._currentWindowController);

  static const Size _mainWindowSize = Size(420, 640);
  static const Size _mainWindowMinSize = Size(360, 520);
  static const double _screenPadding = 20;
  static const double _ballOverlap = 28;
  static const double _ballVerticalOverlap = 26;

  final WindowController? _currentWindowController;
  final WindowManager _windowManager = windowManager;

  WindowController? _floatingBallController;
  AppSettings _settings = AppSettings.defaults();
  bool _initialized = false;
  bool _disposed = false;

  @override
  Future<void> initialize(AppSettings settings) async {
    if (_initialized) {
      await applySettings(settings);
      return;
    }
    _settings = settings;
    if (_currentWindowController == null) {
      _initialized = true;
      return;
    }

    _windowManager.addListener(this);
    await _currentWindowController.setWindowMethodHandler(_handleWindowCall);
    await _spawnFloatingBallWindowIfNeeded();
    await _applyMainWindowChrome();
    await _windowManager.hide();
    _initialized = true;
    await applySettings(settings);
  }

  @override
  Future<void> applySettings(AppSettings settings) async {
    _settings = settings;
    if (_disposed) {
      return;
    }
    await _windowManager.setAlwaysOnTop(settings.alwaysOnTop);
    await _floatingBallController?.invokeMethod('refreshSettings');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _windowManager.removeListener(this);
  }

  @override
  Future<void> onWindowBlur() async {
    if (!_settings.minimizeToTrayOnClose) {
      return;
    }
    await _windowManager.hide();
    await _restoreFloatingBall();
  }

  @override
  Future<void> onWindowClose() async {
    if (!_settings.minimizeToTrayOnClose) {
      await _restoreFloatingBall();
      await _windowManager.destroy();
      return;
    }
    await _windowManager.hide();
    await _restoreFloatingBall();
  }

  Future<dynamic> _handleWindowCall(MethodCall call) async {
    switch (call.method) {
      case 'showMainAtBall':
        final arguments = (call.arguments as Map).cast<String, dynamic>();
        await _showMainAtBall(arguments);
        return null;
      default:
        throw MissingPluginException('Unknown method: ${call.method}');
    }
  }

  Future<void> _spawnFloatingBallWindowIfNeeded() async {
    if (_floatingBallController != null || _currentWindowController == null) {
      return;
    }
    _floatingBallController = await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: false,
        arguments: LightDoWindowArguments.floatingBall(
          mainWindowId: _currentWindowController.windowId,
        ).encode(),
      ),
    );
  }

  Future<void> _applyMainWindowChrome() async {
    await _windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await _windowManager.setPreventClose(true);
    await _windowManager.setResizable(true);
    await _windowManager.setMinimumSize(_mainWindowMinSize);
    await _windowManager.setBackgroundColor(const Color(0xFFF7F4ED));
    await _windowManager.setSkipTaskbar(false);
  }

  Future<void> _showMainAtBall(Map<String, dynamic> payload) async {
    await _applyMainWindowChrome();

    final ballX = (payload['ballX'] as num).toDouble();
    final ballY = (payload['ballY'] as num).toDouble();
    final ballWidth = (payload['ballWidth'] as num).toDouble();
    final ballHeight = (payload['ballHeight'] as num).toDouble();
    final visibleX = (payload['visibleX'] as num).toDouble();
    final visibleY = (payload['visibleY'] as num).toDouble();
    final visibleWidth = (payload['visibleWidth'] as num).toDouble();
    final visibleHeight = (payload['visibleHeight'] as num).toDouble();
    final anchorSide = payload['anchorSide'] as String? ?? 'right';

    final rawLeft = anchorSide == 'right'
        ? ballX + ballWidth - _ballOverlap - _mainWindowSize.width
        : ballX - ballWidth + _ballOverlap;
    final left = rawLeft
        .clamp(
          visibleX + _screenPadding,
          visibleX + visibleWidth - _mainWindowSize.width - _screenPadding,
        )
        .toDouble();
    final top = (ballY + (ballHeight / 2) - _ballVerticalOverlap)
        .clamp(
          visibleY + _screenPadding,
          visibleY + visibleHeight - _mainWindowSize.height - _screenPadding,
        )
        .toDouble();

    await _floatingBallController?.invokeMethod('setBallOverlayState', {
      'coveredByMain': true,
    });
    await _windowManager.setBounds(
      Rect.fromLTWH(left, top, _mainWindowSize.width, _mainWindowSize.height),
    );
    await _windowManager.setAlwaysOnTop(_settings.alwaysOnTop);
    await _windowManager.show();
    await _windowManager.focus();
  }

  Future<void> _restoreFloatingBall() async {
    await _floatingBallController?.invokeMethod('setBallOverlayState', {
      'coveredByMain': false,
    });
  }
}
