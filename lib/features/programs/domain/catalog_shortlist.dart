import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';

/// Body-part words a user might mention, mapped to the catalog muscle names
/// they should train. Keys are matched as substrings of the complaint, so
/// multi-word phrases ("lower back") and stems ("quad") both work.
const Map<String, List<String>> _bodyPartMuscles = {
  'lower back': ['lower back', 'glutes', 'hamstrings'],
  'upper back': ['lats', 'middle back', 'traps'],
  'lumbar': ['lower back'],
  'back': ['lower back', 'lats', 'middle back', 'traps'],
  'posture': ['traps', 'middle back', 'lower back'],
  'neck': ['neck', 'traps'],
  'trap': ['traps'],
  'shoulder': ['shoulders', 'traps'],
  'rotator cuff': ['shoulders'],
  'chest': ['chest'],
  'pec': ['chest'],
  'knee': ['quadriceps', 'hamstrings', 'calves', 'glutes'],
  'thigh': ['quadriceps', 'hamstrings', 'adductors'],
  'quad': ['quadriceps'],
  'hamstring': ['hamstrings'],
  'hip': ['glutes', 'abductors', 'adductors'],
  'glute': ['glutes'],
  'buttock': ['glutes'],
  'groin': ['adductors'],
  'calf': ['calves'],
  'calves': ['calves'],
  'shin': ['calves'],
  'ankle': ['calves'],
  'arm': ['biceps', 'triceps', 'forearms'],
  'bicep': ['biceps'],
  'tricep': ['triceps'],
  'elbow': ['biceps', 'triceps', 'forearms'],
  'wrist': ['forearms'],
  'forearm': ['forearms'],
  'core': ['abdominals'],
  'abdominal': ['abdominals'],
  'abs': ['abdominals'],
  'stomach': ['abdominals'],
  'belly': ['abdominals'],
};

/// The catalog muscles implied by [complaint], derived from the body parts it
/// mentions. Empty when nothing recognizable is found.
Set<String> targetMusclesFor(String complaint) {
  final text = complaint.toLowerCase();
  final targets = <String>{};
  for (final entry in _bodyPartMuscles.entries) {
    if (text.contains(entry.key)) targets.addAll(entry.value);
  }
  return targets;
}

/// Narrows [catalog] to the exercises most relevant to [complaint] before it
/// is sent to the LLM, so the model chooses from a focused, on-target set
/// instead of the whole catalog.
///
/// Exercises are ranked by how well their muscles match the complaint (primary
/// muscles weighted double) and the top [limit] are kept. When the complaint
/// names no recognizable body part, or fewer than [minResults] exercises match,
/// the full catalog is returned unchanged so the model never runs short of
/// options.
List<ExerciseModel> shortlistForComplaint(
  String complaint,
  List<ExerciseModel> catalog, {
  int limit = 40,
  int minResults = 8,
}) {
  final targets = targetMusclesFor(complaint);
  if (targets.isEmpty) return catalog;

  final scored = <(ExerciseModel, int)>[];
  for (final exercise in catalog) {
    final score = _score(exercise, targets);
    if (score > 0) scored.add((exercise, score));
  }
  if (scored.length < minResults) return catalog;

  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final entry in scored.take(limit)) entry.$1];
}

/// Relevance score: each targeted primary muscle counts double a secondary.
int _score(ExerciseModel exercise, Set<String> targets) {
  var score = 0;
  for (final muscle in exercise.primaryMuscles) {
    if (targets.contains(muscle)) score += 2;
  }
  for (final muscle in exercise.secondaryMuscles) {
    if (targets.contains(muscle)) score += 1;
  }
  return score;
}
