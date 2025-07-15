import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_frontend/main.dart';

void main() {
  testWidgets('Main screen should display AppBar and FAB', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    // Should find the search app bar, the floating action button, and bottom navigation bar.
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('FAB opens note editor (route navigation)', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    // Tap the FloatingActionButton.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    // The New Note page should show a title field.
    expect(find.text('New Note'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
