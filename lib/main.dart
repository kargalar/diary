import 'package:flutter/material.dart';

import 'data/diary_repository.dart';
import 'ui/diary_app.dart';
import 'ui/diary_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = DiaryViewModel(DiaryRepository());
  await viewModel.load();
  runApp(DiaryApp(viewModel: viewModel));
}
