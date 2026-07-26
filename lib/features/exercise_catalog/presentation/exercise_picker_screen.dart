import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/exercise_catalog/data/exercise_catalog.dart';
import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';
import 'package:flutter_template/features/exercise_catalog/presentation/exercise_motion_image.dart';
import 'package:flutter_template/widgets/adaptive.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';

/// Searchable catalog browser that returns the picked [ExerciseModel].
///
/// Push with [pick]; resolves to null when the user backs out without
/// choosing. Tapping a card opens a detail sheet (instructions, muscles)
/// with the final "Add" confirmation.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  /// Opens the picker and resolves with the chosen exercise, if any.
  static Future<ExerciseModel?> pick(BuildContext context) {
    return Navigator.push<ExerciseModel>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
  }

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  String _query = '';
  String? _muscle;

  static const _muscleFilters = [
    'calves',
    'glutes',
    'hamstrings',
    'quadriceps',
    'lower back',
    'neck',
    'shoulders',
    'abdominals',
  ];

  List<ExerciseModel> _filtered(List<ExerciseModel> all) {
    final query = _query.trim().toLowerCase();
    return [
      for (final exercise in all)
        if ((query.isEmpty || exercise.name.toLowerCase().contains(query)) &&
            (_muscle == null || exercise.primaryMuscles.contains(_muscle)))
          exercise,
    ];
  }

  Future<void> _showDetail(ExerciseModel exercise) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExerciseDetailSheet(exercise: exercise),
    );
    if ((added ?? false) && mounted) {
      Navigator.pop(context, exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exerciseCatalogProvider);
    return AppScaffold(
      title: 'Pick an exercise',
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search exercises…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final muscle in _muscleFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(muscle),
                      selected: _muscle == muscle,
                      onSelected: (selected) => setState(
                        () => _muscle = selected ? muscle : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: switch (catalog) {
              AsyncData(:final value) => _ExerciseGrid(
                  exercises: _filtered(value),
                  onTap: _showDetail,
                ),
              AsyncError() => Center(
                  child: Text(
                    'Could not load the exercise catalog.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              _ => const AppProgressIndicator(),
            },
          ),
        ],
      ),
    );
  }
}

class _ExerciseGrid extends StatelessWidget {
  const _ExerciseGrid({required this.exercises, required this.onTap});

  final List<ExerciseModel> exercises;
  final ValueChanged<ExerciseModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return Center(
        child: Text(
          'No exercises match — try a different search.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return AppAnimate(
          effects: AppAnimations.cardEntrance,
          child: _ExerciseCard(
            exercise: exercise,
            onTap: () => onTap(exercise),
          ),
        );
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final ExerciseModel exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.4),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ExerciseMotionImage(
                exercise: exercise,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.level,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with the full exercise description and an Add action.
class _ExerciseDetailSheet extends StatelessWidget {
  const _ExerciseDetailSheet({required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  SizedBox(
                    height: 180,
                    child: ExerciseMotionImage(
                      exercise: exercise,
                      animate: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(exercise.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final muscle in exercise.primaryMuscles)
                        Chip(label: Text(muscle)),
                      for (final muscle in exercise.secondaryMuscles)
                        Chip(
                          label: Text(muscle),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final (index, step) in exercise.instructions.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${index + 1}. $step',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add exercise'),
            ),
          ],
        ),
      ),
    );
  }
}
