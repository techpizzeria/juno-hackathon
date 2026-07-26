import 'package:flutter/material.dart';

/// Root navigator key, installed on the app's [MaterialApp].
///
/// Lets non-widget code (the notification service handling a tapped
/// reminder) push screens without a [BuildContext].
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();
