import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/stat_card.dart';
import 'package:frontend/core/widgets/status_badge.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('StatusBadge renders correctly for approved status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: StatusBadge.forStatus('Approved'))),
    );

    expect(find.text('Approved'), findsOneWidget);
  });

  testWidgets('StatCard renders title, value and subtitle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'Active Workflows',
            value: '24',
            subtitle: 'Department requests',
            icon: Icons.task_alt,
            accentColor: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('Active Workflows'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('Department requests'), findsOneWidget);
  });

  testWidgets('InstitutionalWorkflowApp boots and renders dashboard', (
    WidgetTester tester,
  ) async {
    // Set a desktop viewport size
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const InstitutionalWorkflowApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Executive Dashboard'), findsOneWidget);
  });
}
