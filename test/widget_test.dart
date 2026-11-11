import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dnstt_xyz_app/theme/app_theme.dart';

void main() {
  testWidgets('DNS Pro theme builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AppThemeOption.amoled),
        home: const Scaffold(body: Text('DNS Pro')),
      ),
    );

    expect(find.text('DNS Pro'), findsOneWidget);
  });
}
