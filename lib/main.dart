import 'package:flutter/material.dart';

import 'data/diary_repository.dart';
import 'ui/diary_app.dart';
import 'ui/diary_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = DiaryRepository();
  final viewModel = DiaryViewModel(repository);
  final darkTheme = repository.loadDarkTheme();
  await viewModel.load();
  runApp(
    DiaryApp(
      viewModel: viewModel,
      initialDarkTheme: await darkTheme,
      onThemeChanged: repository.saveDarkTheme,
    ),
  );
}
