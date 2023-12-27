import 'package:flutter/material.dart';

class ProviderInheritedWidget extends InheritedWidget {

  const ProviderInheritedWidget({
    Key? key,
    required this.score,
    required Widget child,
  }) : super(key: key, child: child);

  final int score;

  static ProviderInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProviderInheritedWidget>();
  }

  @override
  bool updateShouldNotify(covariant ProviderInheritedWidget oldWidget) {
    return score != oldWidget.score;
  }
}