# Quietly

Quietly is a private daily journal for capturing moments, moods, and the people who were there. Review entries over time with simple writing insights and filters.

## Features

- Write and edit journal entries with a title and free-form text.
- Add a mood, a 1–5 rating, and people tags.
- Filter entries by date, rating, mood, and person.
- Review writing statistics and recurring words in the Analysis view.
- Choose a light or dark theme.
- Store entries locally on the device using shared preferences.

## Run the app

Install [Flutter](https://docs.flutter.dev/get-started/install), then run:

```sh
flutter pub get
flutter run
```

To create an Android APK:

```sh
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Development

Run the analyzer and tests before submitting a change:

```sh
flutter analyze
flutter test
```

## Privacy

Journal entries stay on the device. The app does not include a cloud sync service. Keep a separate backup if you need to preserve entries across device changes.

## License

Quietly is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
