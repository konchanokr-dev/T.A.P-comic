import 'package:flutter/material.dart';
import 'app_settings.dart'; 

class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required Widget child,
  }) : super(notifier: settings, child: child);

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found');
    return scope!.notifier!;
  }
}
