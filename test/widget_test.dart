import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/ui/diary_app.dart';
import 'package:diary/ui/diary_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates and displays a diary entry', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final viewModel = DiaryViewModel(DiaryRepository());
    await viewModel.load();
    await tester.pumpWidget(DiaryApp(viewModel: viewModel));

    expect(find.text('Your story starts here'), findsOneWidget);
    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Write freely…'),
      'I made time to slow down.',
    );
    await tester.tap(find.byTooltip('Save entry'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Give today a name'),
      'A calm day',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('A calm day'), findsOneWidget);
    expect(find.text('I made time to slow down.'), findsOneWidget);

    await tester.tap(find.text('A calm day'));
    await tester.pumpAndSettle();
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('I made time to slow down.'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save entry'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Give today a name'),
      'An updated day',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('An updated day'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.longPress(find.text('An updated day'));
    await tester.pumpAndSettle();
    expect(find.text('Delete entry?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('An updated day'), findsNothing);
    expect(find.text('Your story starts here'), findsOneWidget);
  });

  testWidgets('shows detailed diary analysis', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final viewModel = DiaryViewModel(DiaryRepository());
    await viewModel.load();
    await viewModel.add(
      DiaryEntry(
        id: 'analysis-entry',
        title: 'Coffee walk',
        body: 'Coffee and a peaceful walk with Ada.',
        createdAt: DateTime.now(),
        mood: Mood.happy,
        rating: 5,
        people: const ['Ada'],
      ),
    );
    await tester.pumpWidget(DiaryApp(viewModel: viewModel));

    await tester.tap(find.byTooltip('Analysis'));
    await tester.pumpAndSettle();

    expect(find.text('Period summary'), findsOneWidget);
    expect(find.text('Mood distribution'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('People and their impact'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('People and their impact'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Most used words'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Most used words'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
