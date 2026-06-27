import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/app.dart';

void main() {
  testWidgets('应用启动后显示首页入口', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReactionProApp()));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('ReactionPro'), findsWidgets);
    expect(find.text('反应力测试'), findsWidgets);
    expect(find.text('击杀时间测试'), findsWidgets);
  });

  testWidgets('主题切换按钮可在极简白与夜间黑之间切换', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReactionProApp()));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.brightness_auto_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
