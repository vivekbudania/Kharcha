import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kharcha/main.dart';
import 'package:kharcha/providers/expense_provider.dart';
import 'package:kharcha/providers/settings_provider.dart';
import 'package:kharcha/providers/locale_provider.dart';

import 'package:kharcha/providers/loan_provider.dart';

void main() {
  testWidgets('Kharcha home screen smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Build the providers
    final expenseProvider = ExpenseProvider();
    final settingsProvider = SettingsProvider();
    final localeProvider = LocaleProvider();
    final loanProvider = LoanProvider();

    // Directly pump HomeShell, bypassing the splash screen to avoid infinite animation timers in tests
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: expenseProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: loanProvider),
        ],
        child: const MaterialApp(
          home: HomeShell(),
        ),
      ),
    );

    // Let the first frame render
    await tester.pump();

    // Verify that the HomeShell is successfully built and present
    expect(find.byType(HomeShell), findsOneWidget);
  });
}
