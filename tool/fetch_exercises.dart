// Dev-time script: curates the bundled exercise catalog.
//
// Downloads the free-exercise-db dataset (public domain), filters it down to
// physio-relevant home exercises, and writes assets/exercises.json. Run with:
//
//   dart run tool/fetch_exercises.dart
//
// Images are NOT bundled; the app loads them from the dataset's GitHub raw
// URLs at runtime.
import 'dart:convert';
import 'dart:io';

const String _sourceUrl =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';
const String _outPath = 'assets/exercises.json';

const Set<String?> _allowedEquipment = {
  null,
  'body only',
  'bands',
  'dumbbell',
  'exercise ball',
  'foam roll',
};
const Set<String> _allowedCategories = {
  'stretching',
  'strength',
  'plyometrics',
};
const Set<String> _allowedLevels = {'beginner', 'intermediate'};

/// Physio classics kept even when the general filter would drop them,
/// matched as case-insensitive substrings of the exercise name.
const _mustKeepNames = [
  'calf raise',
  'glute bridge',
  'butt lift (bridge)',
  'bird dog',
  'clam',
  'dead bug',
  'hamstring stretch',
  'calf stretch',
  'ankle circles',
  'hip circles',
  'wall sit',
  'step-up',
  'side plank',
  'plank',
  'superman',
  'standing hip',
  'seated calf',
  'pistol squat',
  'bodyweight squat',
  'lunge',
  'heel',
  'neck',
  'shoulder circles',
  'scapular',
  'external rotation',
  'internal rotation',
  'wrist circles',
  'cat stretch',
  'child',
  'pelvic tilt',
];

/// Muscle groups physio programs most often target; used to keep the
/// general-filter selection focused instead of gym-workout-shaped.
const _priorityMuscles = {
  'calves',
  'glutes',
  'hamstrings',
  'quadriceps',
  'abductors',
  'adductors',
  'lower back',
  'neck',
  'shoulders',
  'abdominals',
};

Future<void> main() async {
  stdout.writeln('Downloading $_sourceUrl ...');
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(_sourceUrl));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  client.close();

  final all = (jsonDecode(body) as List<dynamic>).cast<Map<String, dynamic>>();
  stdout.writeln('Dataset: ${all.length} exercises');

  bool nameMatches(Map<String, dynamic> e) {
    final name = (e['name'] as String).toLowerCase();
    return _mustKeepNames.any(name.contains);
  }

  // Everything must be home-doable, beginner-friendly, and illustrated;
  // name-matched classics only bypass the muscle-focus requirement.
  bool passesBaseFilter(Map<String, dynamic> e) {
    return (e['images'] as List<dynamic>).isNotEmpty &&
        _allowedEquipment.contains(e['equipment'] as String?) &&
        _allowedCategories.contains(e['category'] as String?) &&
        _allowedLevels.contains(e['level'] as String?);
  }

  bool hasPriorityMuscle(Map<String, dynamic> e) {
    final primary =
        (e['primaryMuscles'] as List<dynamic>).cast<String>().toSet();
    return primary.intersection(_priorityMuscles).isNotEmpty;
  }

  bool homeFriendly(Map<String, dynamic> e) {
    const generalEquipment = {null, 'body only', 'bands', 'exercise ball'};
    return generalEquipment.contains(e['equipment'] as String?);
  }

  final kept = all
      .where(passesBaseFilter)
      .where((e) =>
          nameMatches(e) || (homeFriendly(e) && hasPriorityMuscle(e)))
      .toList()
    ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

  stdout.writeln('Curated: ${kept.length} exercises');
  final byCategory = <String, int>{};
  for (final e in kept) {
    final cat = e['category'] as String;
    byCategory[cat] = (byCategory[cat] ?? 0) + 1;
  }
  stdout.writeln('By category: $byCategory');

  const encoder = JsonEncoder.withIndent('  ');
  File(_outPath).writeAsStringSync('${encoder.convert(kept)}\n');
  stdout.writeln('Wrote $_outPath');
}
