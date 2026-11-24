import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const diaryMotion = Duration(milliseconds: 200);
const diaryControlShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(9)),
);
const diaryCardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);
const _panelShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
);

const _darkScheme = ColorScheme.dark(
  primary: Color(0xFFEEEEEE),
  onPrimary: Color(0xFF171717),
  primaryContainer: Color(0xFF303030),
  onPrimaryContainer: Color(0xFFF4F4F4),
  secondary: Color(0xFFEEEEEE),
  onSecondary: Color(0xFF171717),
  secondaryContainer: Color(0xFFEEEEEE),
  onSecondaryContainer: Color(0xFF171717),
  tertiary: Color(0xFFA8BBA9),
  surface: Color(0xFF1C1C1C),
  onSurface: Color(0xFFF4F4F4),
  onSurfaceVariant: Color(0xFF929292),
  surfaceContainerLow: Color(0xFF1C1C1C),
  surfaceContainer: Color(0xFF252525),
  surfaceContainerHigh: Color(0xFF414141),
  surfaceContainerHighest: Color(0xFF303030),
  outline: Color(0xFF929292),
  outlineVariant: Color(0xFF333333),
  error: Color(0xFFF0A9A5),
  onError: Color(0xFF321716),
);

const _lightScheme = ColorScheme.light(
  primary: Color(0xFF252525),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE6E6E6),
  onPrimaryContainer: Color(0xFF191919),
  secondary: Color(0xFF252525),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFF252525),
  onSecondaryContainer: Color(0xFFFFFFFF),
  tertiary: Color(0xFF4D6B55),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF191919),
  onSurfaceVariant: Color(0xFF626262),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFEDEDED),
  surfaceContainerHigh: Color(0xFFDCDCDC),
  surfaceContainerHighest: Color(0xFFE6E6E6),
  outline: Color(0xFF727272),
  outlineVariant: Color(0xFFD2D2D2),
  error: Color(0xFF9C2726),
  onError: Color(0xFFFFFFFF),
);

const _fieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(9)),
  borderSide: BorderSide(color: Colors.transparent),
);

const _label = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: .2,
);

ThemeData buildDiaryTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = dark ? _darkScheme : _lightScheme;
  final canvas = dark ? const Color(0xFF101010) : const Color(0xFFF6F6F6);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final divider = BorderSide(color: scheme.outlineVariant);
  final activeOutline = BorderSide(color: scheme.primary, width: 2);
  final cardShape = diaryCardShape.copyWith(side: divider);
  final fontFamily = base.platform == TargetPlatform.windows
      ? 'Segoe UI'
      : null;
  final text = base.textTheme
      .copyWith(
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 14, height: 1.55),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
        labelLarge: _label,
        labelMedium: _label,
        labelSmall: const TextStyle(fontSize: 11, letterSpacing: .3),
      )
      .apply(
        fontFamily: fontFamily,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      )
      .copyWith(
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
      );

  final focusSide = WidgetStateProperty.resolveWith<BorderSide?>(
    (states) => states.contains(WidgetState.focused)
        ? activeOutline
        : const BorderSide(color: Colors.transparent, width: 2),
  );

  final controls = ButtonStyle(
    shape: const WidgetStatePropertyAll(diaryControlShape),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    iconSize: const WidgetStatePropertyAll(17),
    minimumSize: const WidgetStatePropertyAll(Size(40, 38)),
    visualDensity: VisualDensity.standard,
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
  );

  return base.copyWith(
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: canvas,
    canvasColor: canvas,
    dividerColor: scheme.outlineVariant,
    focusColor: scheme.surfaceContainerHigh,
    hoverColor: scheme.surfaceContainerHigh,
    appBarTheme: AppBarThemeData(
      toolbarHeight: 60,
      backgroundColor: canvas,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: brightness,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: canvas,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: cardShape,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHighest,
      ),
      hoverColor: Colors.transparent,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: scheme.onSurface),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: _fieldBorder,
      enabledBorder: _fieldBorder,
      focusedBorder: _fieldBorder.copyWith(borderSide: activeOutline),
      errorBorder: _fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: _fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: controls.copyWith(
        side: WidgetStateProperty.resolveWith<BorderSide?>(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(color: scheme.onPrimary, width: 2)
              : BorderSide.none,
        ),
        backgroundColor: WidgetStateProperty.fromMap({
          WidgetState.disabled: scheme.surfaceContainerHighest,
          WidgetState.hovered: scheme.onSurface,
          WidgetState.any: scheme.primary,
        }),
        foregroundColor: WidgetStateProperty.fromMap({
          WidgetState.disabled: scheme.onSurfaceVariant,
          WidgetState.any: scheme.onPrimary,
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: controls.copyWith(
        side: WidgetStateProperty.resolveWith<BorderSide?>(
          (states) => states.contains(WidgetState.focused)
              ? activeOutline
              : BorderSide(color: scheme.outlineVariant),
        ),
        foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        backgroundColor: WidgetStateProperty.fromMap({
          WidgetState.selected: scheme.surfaceContainerHigh,
          WidgetState.hovered: scheme.surfaceContainerHigh,
          WidgetState.any: scheme.surfaceContainer,
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: controls.copyWith(
        side: focusSide,
        foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        overlayColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: controls.copyWith(
        side: focusSide,
        foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        overlayColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        minimumSize: const WidgetStatePropertyAll(Size(38, 38)),
        iconSize: const WidgetStatePropertyAll(18),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainer,
      color: WidgetStateProperty.fromMap({
        WidgetState.selected: scheme.primary,
        WidgetState.hovered: scheme.surfaceContainerHigh,
        WidgetState.any: scheme.surfaceContainer,
      }),
      shape: diaryControlShape,
      side: WidgetStateBorderSide.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(
                color: states.contains(WidgetState.selected)
                    ? scheme.onPrimary
                    : scheme.primary,
                width: 2,
              )
            : BorderSide(color: scheme.outlineVariant),
      ),
      labelStyle: _label.copyWith(
        fontFamily: fontFamily,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurface,
        ),
      ),
      secondaryLabelStyle: _label.copyWith(
        fontFamily: fontFamily,
        color: scheme.onPrimary,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xB3000000),
      elevation: 24,
      shape: _panelShape.copyWith(side: divider),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 14,
        height: 1.4,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xB3000000),
      modalElevation: 24,
      dragHandleColor: scheme.onSurfaceVariant,
      dragHandleSize: const Size(32, 3),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        side: divider,
      ),
      clipBehavior: Clip.antiAlias,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xB3000000),
      elevation: 16,
      shape: cardShape,
      textStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.tertiary,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      textColor: scheme.onSurface,
      iconColor: scheme.onSurfaceVariant,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.surfaceContainer,
      contentTextStyle: TextStyle(color: scheme.onSurface, fontSize: 14),
      shape: diaryControlShape,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: .35),
      selectionHandleColor: scheme.primary,
    ),
  );
}

AnimationStyle diaryAnimation(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? AnimationStyle.noAnimation
    : const AnimationStyle(
        duration: diaryMotion,
        reverseDuration: diaryMotion,
        curve: Curves.easeOut,
      );

Route<T> diaryPageRoute<T>(BuildContext context, WidgetBuilder builder) {
  final animation = diaryAnimation(context);
  return PageRouteBuilder<T>(
    pageBuilder: (context, _, _) => builder(context),
    transitionDuration: animation.duration!,
    reverseTransitionDuration: animation.reverseDuration!,
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

Future<T?> showDiaryPanel<T>(
  BuildContext context,
  Widget child, {
  bool bottomSheet = false,
}) {
  final animation = diaryAnimation(context);
  if (!bottomSheet && MediaQuery.sizeOf(context).width >= 640) {
    return showDialog<T>(
      context: context,
      animationStyle: animation,
      builder: (_) => Dialog(
        constraints: const BoxConstraints(maxWidth: 520),
        insetAnimationDuration: animation.duration!,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: animation,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      ),
    ),
  );
}
