import 'dart:async';
import 'dart:io';

import 'package:window_manager/window_manager.dart';

final class FullscreenSubscription {
  FullscreenSubscription(this._onChange);

  final void Function(bool fullscreen) _onChange;
  bool _disposed = false;

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _listeners.remove(_onChange);
  }
}

final Set<void Function(bool fullscreen)> _listeners = {};
final _windowListener = _DesktopFullscreenListener();
Future<void>? _initialization;
bool _fullscreen = false;

bool get _isDesktop =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

bool isFullscreen() => _fullscreen;

void requestFullscreen() {
  if (!_isDesktop) {
    return;
  }
  unawaited(_setFullscreen(true));
}

void exitFullscreen() {
  if (!_isDesktop) {
    return;
  }
  unawaited(_setFullscreen(false));
}

FullscreenSubscription listenFullscreenChange(
  void Function(bool fullscreen) onChange,
) {
  _listeners.add(onChange);
  if (_isDesktop) {
    unawaited(_ensureInitialized().then((_) => onChange(_fullscreen)));
  }
  return FullscreenSubscription(onChange);
}

Future<void> _ensureInitialized() {
  return _initialization ??= _initialize();
}

Future<void> _initialize() async {
  await windowManager.ensureInitialized();
  windowManager.addListener(_windowListener);
  _notify(await windowManager.isFullScreen());
}

Future<void> _setFullscreen(bool fullscreen) async {
  await _ensureInitialized();
  await windowManager.setFullScreen(fullscreen);
  _notify(await windowManager.isFullScreen());
}

void _notify(bool fullscreen) {
  if (_fullscreen == fullscreen) {
    return;
  }
  _fullscreen = fullscreen;
  for (final listener in List.of(_listeners)) {
    listener(fullscreen);
  }
}

final class _DesktopFullscreenListener with WindowListener {
  @override
  void onWindowEnterFullScreen() {
    _notify(true);
  }

  @override
  void onWindowLeaveFullScreen() {
    _notify(false);
  }
}
