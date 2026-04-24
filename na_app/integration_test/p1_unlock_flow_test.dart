import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:na_app/features/subjects/presentation/pages/subject_detail_page.dart';
import 'package:na_app/main.dart' as app;

// Generate a unique code at runtime or mock the activation repository.
// A 12-character alphanumeric code matching the expected format is produced
// by generating a random string. If the backend uses a different format or
// requires seeding, replace the generator below or mock the repository.
String _generateTestActivationCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rng = DateTime.now().millisecondsSinceEpoch;
  final code = StringBuffer();
  for (var i = 0; i < 12; i++) {
    code.write(chars[(rng + i * 7) % chars.length]);
  }
  return code.toString();
}

late final String _testActivationCode;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('P1 Unlock Flow', () {
    testWidgets('Splash → Register → empty Subjects → enter code → Code Accepted → Subject detail',
        (tester) async {
      _testActivationCode = _generateTestActivationCode();
      final accountEmail = 'student-p1-${DateTime.now().millisecondsSinceEpoch}@na.local';
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for auth bootstrap to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate past onboarding if present
      final getStartedButton = find.text('Get started');
      if (getStartedButton.evaluate().isNotEmpty) {
        await tester.tap(getStartedButton);
        await tester.pumpAndSettle();
      }

      // Should now be on register or login - look for register link
      final createAccountLink = find.text('Create account');
      if (createAccountLink.evaluate().isNotEmpty) {
        await tester.tap(createAccountLink);
        await tester.pumpAndSettle();
      }

      // Fill registration form
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Test Student');
      await tester.enterText(textFields.at(1), accountEmail);
      await tester.enterText(textFields.at(2), 'Passw0rd!');

      // Accept terms
      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }

      // Submit registration
      final submitButton = find.text('Create account');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.last);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // After registration, should be on Subjects page
      // Look for the code entry card or the empty state
      final codeEntryCard = find.text('Have a subject code?');
      final emptyState = find.text('No subjects yet');

      expect(
        codeEntryCard.evaluate().isNotEmpty || emptyState.evaluate().isNotEmpty,
        isTrue,
        reason: 'Should be on Subjects page with either code entry card or empty state',
      );

      // Navigate to enter code page
      if (codeEntryCard.evaluate().isNotEmpty) {
        await tester.tap(codeEntryCard);
        await tester.pumpAndSettle();
      } else {
        final enterCodeButton = find.text('Enter code');
        await tester.tap(enterCodeButton);
        await tester.pumpAndSettle();
      }

      // Should be on enter code page
      expect(find.text('Unlock'), findsOneWidget);

      // Enter code in the CodeInputField
      final codeFields = find.byType(TextField);
      await tester.enterText(codeFields.first, _testActivationCode);
      await tester.pumpAndSettle();

      // Tap unlock
      final unlockButton = find.text('Unlock');
      await tester.tap(unlockButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should land on SubjectDetailPage
      expect(find.byType(SubjectDetailPage), findsOneWidget);
    });
  });
}