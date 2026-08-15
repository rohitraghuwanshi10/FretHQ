import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:frethq/main.dart';
import 'package:frethq/screens/main_shell.dart';
import 'package:frethq/screens/settings_screen.dart';
import 'package:frethq/services/theme_service.dart';
import 'package:frethq/widgets/fretboard_heatmap_widget.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('FretHQApp renders MainShell with Train tab correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FretHQApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('FRET HQ'), findsOneWidget);
    expect(find.text('Identify Note'), findsOneWidget);
    expect(find.text('Find Fret Location'), findsOneWidget);
    expect(find.text('Scale & Interval Quiz'), findsOneWidget);
    expect(find.text('1m'), findsWidgets);
  });

  testWidgets('FretboardHeatmapWidget renders correctly with empty stats', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FretboardHeatmapWidget(heatmapStats: {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FretboardHeatmapWidget), findsOneWidget);
    expect(find.textContaining('Mastered'), findsOneWidget);
    expect(find.textContaining('Untested'), findsOneWidget);
  });

  testWidgets('ThemeService changes ThemeMode and SettingsScreen allows switching', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.init();

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Switch to Light mode
    await tester.tap(find.text('Light'));
    await tester.pump();

    expect(ThemeService.themeModeNotifier.value, equals(ThemeMode.light));

    // Switch back to Dark mode
    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(ThemeService.themeModeNotifier.value, equals(ThemeMode.dark));
  });

  testWidgets('MainShell navigation switches tabs cleanly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const FretHQApp(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on Tools Tab
    final toolsIcon = find.byIcon(Icons.tune_rounded).last;
    expect(toolsIcon, findsOneWidget);

    await tester.tap(toolsIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Tuner'), findsOneWidget);
    expect(find.text('Metronome'), findsOneWidget);

    // Tap on Settings Tab
    final settingsIcon = find.byIcon(Icons.settings_rounded).last;
    expect(settingsIcon, findsOneWidget);

    await tester.tap(settingsIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Settings & Preferences'), findsOneWidget);
  });
}
