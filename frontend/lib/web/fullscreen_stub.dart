final class FullscreenSubscription {
  const FullscreenSubscription();

  void dispose() {}
}

bool isFullscreen() => false;

void requestFullscreen() {}

void exitFullscreen() {}

FullscreenSubscription listenFullscreenChange(void Function(bool) onChange) {
  return const FullscreenSubscription();
}
