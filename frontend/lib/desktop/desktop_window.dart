import 'dart:io';

import 'package:window_manager/window_manager.dart';

Future<void> initializeDesktopWindow() async {
  if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
    return;
  }

  await windowManager.ensureInitialized();
  await windowManager.setTitle('ReactionPro');
}
