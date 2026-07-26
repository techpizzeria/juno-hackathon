import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/utils/local_storage.dart';

part 'programs.g.dart';

/// Single source of truth for stored programs.
///
/// Persists the full program list as one JSON array under
/// `creak.programs.v1`. Reads are synchronous (shared_preferences is an
/// in-memory cache); every mutation writes through.
@Riverpod(keepAlive: true)
class ProgramRepository extends _$ProgramRepository {
  static const _storageKey = 'creak.programs.v1';

  @override
  ProgramRepository build() => this;

  SharedPreferences get _prefs => ref.read(localStorageProvider);

  /// Loads every stored program, empty when none saved yet.
  List<ProgramModel> loadAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final entry in list.cast<Map<String, dynamic>>())
        ProgramModel.fromJson(entry),
    ];
  }

  /// Replaces the stored program list.
  Future<void> saveAll(List<ProgramModel> programs) async {
    await _prefs.setString(
      _storageKey,
      jsonEncode([for (final program in programs) program.toJson()]),
    );
  }
}

/// Reactive list of the user's programs; the UI's entry point for program
/// state and mutations.
@Riverpod(keepAlive: true)
class Programs extends _$Programs {
  @override
  List<ProgramModel> build() => ref.read(programRepositoryProvider).loadAll();

  /// Adds [program] or replaces the stored program with the same id.
  Future<void> upsert(ProgramModel program) async {
    final existing = state.indexWhere((p) => p.id == program.id);
    state = [
      for (final p in state)
        if (p.id == program.id) program else p,
      if (existing == -1) program,
    ];
    await ref.read(programRepositoryProvider).saveAll(state);
  }

  /// Deletes the program with [id]. Log history is deliberately kept.
  Future<void> delete(String id) async {
    state = [
      for (final p in state)
        if (p.id != id) p,
    ];
    await ref.read(programRepositoryProvider).saveAll(state);
  }

  /// Removes every program (demo data reset).
  Future<void> clearAll() async {
    state = const [];
    await ref.read(programRepositoryProvider).saveAll(state);
  }
}
