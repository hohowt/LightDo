import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightdo/main.dart';
import 'package:lightdo/models/app_settings.dart';
import 'package:lightdo/models/app_snapshot.dart';
import 'package:lightdo/services/desktop_integration.dart';
import 'package:lightdo/models/todo_item.dart';
import 'package:lightdo/services/lightdo_storage.dart';

void main() {
  testWidgets('renders existing todo item', (tester) async {
    final snapshot = AppSnapshot(
      todos: [TodoItem.create(title: '整理 Flutter 需求')],
      settings: AppSettings.defaults(),
    );

    await tester.pumpWidget(
      LightDoApp(
        storage: MemoryLightDoStorage(snapshot),
        desktopIntegration: NoopDesktopIntegration(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LightDo'), findsOneWidget);
    expect(find.text('整理 Flutter 需求'), findsOneWidget);
  });

  testWidgets('adds todo item from input', (tester) async {
    await tester.pumpWidget(
      LightDoApp(
        storage: MemoryLightDoStorage(),
        desktopIntegration: NoopDesktopIntegration(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '补齐 Flutter 页面');
    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    await tester.pumpAndSettle();

    expect(find.text('补齐 Flutter 页面'), findsOneWidget);
  });
}
