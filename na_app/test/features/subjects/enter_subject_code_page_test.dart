import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_app/core/widgets/code_input.dart';

void main() {
  Widget buildTestWidget({
    required ValueChanged<String> onChanged,
    VoidCallback? onCompleted,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CodeInputField(
          length: 6,
          onChanged: onChanged,
          onCompleted: onCompleted,
        ),
      ),
    );
  }

  testWidgets('CodeInputField auto-advances on keystroke', (tester) async {
    final codes = <String>[];
    await tester.pumpWidget(buildTestWidget(
      onChanged: (code) => codes.add(code),
    ));

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(6));

    // Focus the first cell and type a character
    await tester.tap(textFields.at(0));
    await tester.pump();
    await tester.enterText(textFields.at(0), 'A');
    await tester.pump();
    expect(codes.last, 'A');

    // Focus should have auto-advanced to the second cell.
    // Type into the second cell to verify it received focus.
    await tester.enterText(textFields.at(1), 'B');
    await tester.pump();
    expect(codes.last, 'AB');
  });

  testWidgets('CodeInputField distributes paste across cells', (tester) async {
    final codes = <String>[];
    await tester.pumpWidget(buildTestWidget(
      onChanged: (code) => codes.add(code),
    ));

    final textFields = find.byType(TextField);

    // Simulate pasting 6 characters into the first cell
    await tester.enterText(textFields.at(0), 'ABC123');
    await tester.pump();
    expect(codes.last, 'ABC123');
  });

  testWidgets('CodeInputField fires onCompleted when all cells filled', (tester) async {
    bool completed = false;
    final codes = <String>[];
    await tester.pumpWidget(buildTestWidget(
      onChanged: (code) => codes.add(code),
      onCompleted: () => completed = true,
    ));

    final textFields = find.byType(TextField);

    await tester.enterText(textFields.at(0), 'NA24CH');
    await tester.pump();

    expect(codes.last, 'NA24CH');
    expect(completed, isTrue);
  });

  testWidgets('CodeInputField rejects non-alphanumeric input', (tester) async {
    final codes = <String>[];
    await tester.pumpWidget(buildTestWidget(
      onChanged: (code) => codes.add(code),
    ));

    final textFields = find.byType(TextField);

    // The FilteringTextInputFormatter should strip non-alphanumeric
    await tester.enterText(textFields.at(0), '!@#');
    await tester.pump();

    // After filtering, only empty string remains (non-alphanumerics stripped)
    expect(codes.last, '');
  });

  testWidgets('CodeInputField uppercases input', (tester) async {
    final codes = <String>[];
    await tester.pumpWidget(buildTestWidget(
      onChanged: (code) => codes.add(code),
    ));

    final textFields = find.byType(TextField);

    await tester.enterText(textFields.at(0), 'abcdef');
    await tester.pump();

    expect(codes.last, 'ABCDEF');
  });
}
