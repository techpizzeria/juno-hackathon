import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/utils/local_storage.dart';

part 'onboarding_repository.g.dart';

/// Source of truth for whether the first-run introduction has been shown.
@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) {
  return OnboardingRepository(ref.watch(localStorageProvider));
}

/// Reads and records whether the user has seen the welcome intro.
///
/// Backed by a single shared_preferences flag, written only here. The intro
/// is a one-time welcome that flows into program creation; once seen, the app
/// opens straight on the dashboard.
class OnboardingRepository {
  /// Creates the repository over the given preferences store.
  const OnboardingRepository(this._prefs);

  static const _seenKey = 'creak.onboarding.seen.v1';

  final SharedPreferences _prefs;

  /// Whether the intro has already been shown.
  bool hasCompletedIntro() => _prefs.getBool(_seenKey) ?? false;

  /// Marks the intro as seen so it never shows again.
  Future<void> markIntroSeen() => _prefs.setBool(_seenKey, true);
}
