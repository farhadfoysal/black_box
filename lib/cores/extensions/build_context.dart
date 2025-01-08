part of core;

extension BuildContextExtension on BuildContext {
  ThemeData get themeD => Theme.of(this);

  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;
}
