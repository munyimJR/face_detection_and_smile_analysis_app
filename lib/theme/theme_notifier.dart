import 'package:flutter/material.dart';

/// Notifier to control and persist the active [ThemeMode] (light, dark, or system).
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);
