import 'dart:convert';

import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/main.dart' as app;
import 'package:diary/ui/diary_app.dart';
import 'package:diary/ui/diary_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates, edits directly, and deletes a diary entry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final viewModel = DiaryViewModel(DiaryRepository());
    await viewModel.load();
    await tester.pumpWidget(DiaryApp(viewModel: viewModel));

    expect(find.text('Your story starts here'), findsOneWidget);
    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    final title = find.widgetWithText(TextFormField, 'Title');
    final body = find.widgetWithText(TextFormField, 'Write freely…');
    final bodyInput = find.descendant(
      of: body,
      matching: find.byType(EditableText),
    );
    await tester.enterText(title, 'A calm day');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<EditableText>(bodyInput).focusNode.hasFocus, isTrue);
    tester.testTextInput.enterText('I made time to slow down.');
    await tester.pump();

    await tester.tap(find.byTooltip('Entry details'));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Title')),
      findsNothing,
    );
    await tester.tap(find.text('😊 Happy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('A calm day'), findsOneWidget);
    expect(find.text('I made time to slow down.'), findsOneWidget);
    final original = viewModel.entries.single;
    expect(original.mood, Mood.happy);

    await tester.tap(find.text('A calm day'));
    await tester.pumpAndSettle();
    expect(find.text('Edit entry'), findsOneWidget);
    expect(
      tester.widget<EditableText>(bodyInput).controller.text,
      'I made time to slow down.',
    );
    await tester.enterText(title, 'An updated day');
    await tester.enterText(body, 'I wrote straight into the entry.');
    await tester.tap(find.byTooltip('Entry details'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '😊 Happy'))
          .selected,
      isTrue,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('An updated day'), findsOneWidget);
    expect(find.text('I wrote straight into the entry.'), findsOneWidget);
    expect(viewModel.entries.single.id, original.id);

    await tester.longPress(find.text('An updated day'));
    await tester.pumpAndSettle();
    expect(find.text('Delete entry?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('An updated day'), findsNothing);
    expect(find.text('Your story starts here'), findsOneWidget);
  });

  testWidgets('keeps the editor and details inside safe areas', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    const insets = FakeViewPadding(top: 28, left: 12, right: 12, bottom: 34);
    tester.view.viewPadding = insets;
    tester.view.padding = insets;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final viewModel = DiaryViewModel(DiaryRepository());
    await tester.pumpWidget(DiaryApp(viewModel: viewModel));
    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();

    final title = find.widgetWithText(TextFormField, 'Title');
    final body = find.widgetWithText(TextFormField, 'Write freely…');
    expect(tester.getTopLeft(title).dx, greaterThan(insets.left));
    expect(tester.getTopLeft(title).dy, greaterThan(insets.top));
    expect(tester.getBottomRight(body).dy, lessThan(640 - insets.bottom));
    await tester.tap(find.byTooltip('Entry details'));
    await tester.pumpAndSettle();
    final addPerson = find.widgetWithText(TextField, 'Add person');
    await tester.ensureVisible(addPerson);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(addPerson).dy,
      lessThanOrEqualTo(640 - insets.bottom),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Please add a title'), findsOneWidget);
    expect(find.text('Write something before saving.'), findsOneWidget);
    expect(viewModel.entries, isEmpty);

    tester.view.viewInsets = const FakeViewPadding(bottom: 460);
    tester.view.padding = const FakeViewPadding(top: 28, left: 12, right: 12);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the saved theme and matching toggle on startup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await app.main();
    await tester.pumpAndSettle();

    Brightness brightness() =>
        Theme.of(tester.element(find.byType(DiaryHomePage))).brightness;

    expect(brightness(), Brightness.dark);
    await tester.tap(find.byTooltip('Use light theme'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);

    await tester.pumpWidget(const SizedBox.shrink());
    await app.main();
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    expect(find.byTooltip('Use dark theme'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
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

  testWidgets('keeps older diary entries and separates dreams into Note', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'diary_entries': jsonEncode([
        {
          'id': 'existing',
          'title': 'An earlier diary entry',
          'body': 'A memorable afternoon.',
          'createdAt': DateTime.now().toIso8601String(),
          'mood': 'happy',
          'rating': 5,
          'people': [],
        },
      ]),
    });
    final repository = DiaryRepository();
    final viewModel = DiaryViewModel(repository);
    await viewModel.load();
    await tester.pumpWidget(DiaryApp(viewModel: viewModel));

    final diaryTab = find.descendant(
      of: find.byType(TabBar),
      matching: find.text('Diary'),
    );
    final oldEntry = find.text('An earlier diary entry');
    final dream = find.text('Flying over the city');

    expect(oldEntry, findsOneWidget);
    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dream'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Flying over the city',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Write freely…'),
      'I could see the lights from above.',
    );
    await tester.tap(find.byTooltip('Entry details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(dream, findsOneWidget);
    expect(oldEntry, findsNothing);
    final saved = await repository.load();
    expect(
      saved.firstWhere((entry) => entry.id == 'existing').category,
      EntryCategory.diary,
    );
    expect(
      saved.firstWhere((entry) => entry.id != 'existing').category,
      EntryCategory.dream,
    );

    await tester.tap(find.byTooltip('Analysis'));
    await tester.pumpAndSettle();
    expect(find.text('3.0 / 5'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(dream);
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<EntryCategory>), findsNothing);
    await tester.tap(find.byTooltip('Entry details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(dream, findsOneWidget);

    await tester.tap(diaryTab);
    await tester.pumpAndSettle();
    expect(oldEntry, findsOneWidget);
    expect(dream, findsNothing);

    final pageCenter = tester.getCenter(find.byType(TabBarView));
    await tester.dragFrom(pageCenter, const Offset(-550, 0));
    await tester.pumpAndSettle();
    expect(dream, findsOneWidget);
    expect(oldEntry, findsNothing);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);

    await tester.dragFrom(pageCenter, const Offset(550, 0));
    await tester.pumpAndSettle();
    expect(oldEntry, findsOneWidget);
    expect(dream, findsNothing);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
  });

  testWidgets('applies and clears filters in the compact layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    SharedPreferences.setMockInitialValues({});
    final viewModel = DiaryViewModel(DiaryRepository());
    await viewModel.add(
      DiaryEntry(
        id: 'filter-entry',
        title: 'Morning walk',
        body: 'Walked with Ada before work.',
        createdAt: DateTime.now(),
        mood: Mood.happy,
        rating: 5,
        people: const ['Ada'],
      ),
    );
    await tester.pumpWidget(DiaryApp(viewModel: viewModel));

    await tester.tap(find.byTooltip('Filter entries'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    final panel = tester.element(find.text('Filter entries'));
    expect(ModalRoute.of(panel)?.transitionDuration, Duration.zero);

    final rating = find.widgetWithText(FilterChip, '2 🙁');
    await tester.tap(rating);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(rating).selected, isTrue);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('No matching entries'), findsOneWidget);
    expect(find.text('Rating: 2 / 5'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Morning walk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto-saves valid changes when pressing back in edit mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = DiaryRepository();
    final viewModel = DiaryViewModel(repository);
    final createdAt = DateTime(2026, 5, 10, 9, 30);
    await viewModel.add(
      DiaryEntry(
        id: 'edit-back-entry',
        title: 'Original title',
        body: 'Original body',
        createdAt: createdAt,
        mood: Mood.calm,
        rating: 4,
        people: const ['Ada'],
      ),
    );
    await tester.pumpWidget(DiaryApp(viewModel: viewModel));

    final titleField = find.widgetWithText(TextFormField, 'Title');
    final bodyField = find.widgetWithText(TextFormField, 'Write freely…');

    await tester.tap(find.text('Original title'));
    await tester.pumpAndSettle();
    await tester.enterText(titleField, 'Updated via back button');
    await tester.enterText(bodyField, 'Saved automatically on back.');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Save entry?'), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Updated via back button'), findsOneWidget);
    expect(find.text('Saved automatically on back.'), findsOneWidget);
    expect(viewModel.entries.single.id, 'edit-back-entry');
    expect(viewModel.entries.single.createdAt, createdAt);

    await tester.tap(find.text('Updated via back button'));
    await tester.pumpAndSettle();
    await tester.enterText(bodyField, 'Saved on system back.');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Saved on system back.'), findsOneWidget);
    expect(viewModel.entries.single.body, 'Saved on system back.');

    await tester.tap(find.text('Updated via back button'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Updated via back button'), findsOneWidget);

    await tester.tap(find.text('Updated via back button'));
    await tester.pumpAndSettle();
    await tester.enterText(titleField, '');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Edit entry'), findsOneWidget);
    expect(find.text('Please add a title'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Updated via back button'), findsOneWidget);
    expect(viewModel.entries.single.title, 'Updated via back button');
    expect(tester.takeException(), isNull);
  });

  testWidgets('prompts to save when pressing back in new entry mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final viewModel = DiaryViewModel(DiaryRepository());
    await viewModel.load();
    await tester.pumpWidget(DiaryApp(viewModel: viewModel));

    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Save entry?'), findsNothing);
    expect(viewModel.entries, isEmpty);

    final titleField = find.widgetWithText(TextFormField, 'Title');
    final bodyField = find.widgetWithText(TextFormField, 'Write freely…');

    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    await tester.enterText(titleField, 'Draft note');
    await tester.enterText(bodyField, 'Unsaved draft body');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Save entry?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsOneWidget);
    expect(find.text('Draft note'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Save entry?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(viewModel.entries, isEmpty);
    expect(find.text('Your story starts here'), findsOneWidget);

    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dream'));
    await tester.enterText(titleField, 'Lucid flight');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Save entry?'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Write something before saving.'), findsOneWidget);
    expect(viewModel.entries, isEmpty);

    await tester.enterText(bodyField, 'Soared above quiet mountains.');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Save entry?'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Lucid flight'), findsOneWidget);
    expect(find.text('Soared above quiet mountains.'), findsOneWidget);
    expect(viewModel.entries.single.category, EntryCategory.dream);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    expect(tester.takeException(), isNull);
  });
}
