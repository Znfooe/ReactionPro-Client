import '../../../web/fullscreen_stub.dart'
    if (dart.library.html) '../../../web/fullscreen.dart'
    if (dart.library.io) '../../../desktop/fullscreen.dart'
    as browser;

final class FullscreenController {
  browser.FullscreenSubscription? _fullscreenChangeSubscription;
  void Function(bool fullscreen)? _onFullscreenChanged;

  bool get isFullscreen => browser.isFullscreen();

  void startListening({required void Function(bool fullscreen) onChange}) {
    _onFullscreenChanged = onChange;
    _fullscreenChangeSubscription ??= browser.listenFullscreenChange((
      fullscreen,
    ) {
      _onFullscreenChanged?.call(fullscreen);
    });
  }

  void requestFullscreen() {
    browser.requestFullscreen();
  }

  void exitFullscreen() {
    browser.exitFullscreen();
  }

  void dispose() {
    _fullscreenChangeSubscription?.dispose();
    _fullscreenChangeSubscription = null;
  }
}
