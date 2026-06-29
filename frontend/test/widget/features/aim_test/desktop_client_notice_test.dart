import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/core/theme/app_theme.dart';
import 'package:reaction_time_test/features/aim_test/widgets/desktop_client_notice.dart';

void main() {
  testWidgets('桌面端提示应说明浏览器限制并提供双平台下载', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(child: AimDesktopClientNotice()),
        ),
      ),
    );

    expect(find.text('击杀时间测试需要桌面客户端'), findsOneWidget);
    expect(find.textContaining('requestFullscreen()'), findsOneWidget);
    expect(find.text('下载 Windows .exe'), findsOneWidget);
    expect(find.text('下载 macOS .dmg'), findsOneWidget);
  });
}
