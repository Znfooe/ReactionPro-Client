import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'desktop/desktop_window_stub.dart'
    if (dart.library.io) 'desktop/desktop_window.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDesktopWindow();
  runApp(const ProviderScope(child: ReactionProApp()));
}
