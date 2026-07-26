import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_template/features/exercise_catalog/data/exercise_catalog.dart';
import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';
import 'package:flutter_template/features/exercise_catalog/presentation/exercise_motion_image.dart';
import 'package:flutter_template/features/logs/application/form_check_service.dart';
import 'package:flutter_template/features/logs/application/video_service.dart';
import 'package:flutter_template/features/logs/data/logs.dart';
import 'package:flutter_template/features/logs/domain/form_feedback.dart';
import 'package:flutter_template/features/logs/domain/log_entry.dart';
import 'package:flutter_template/features/logs/domain/streak.dart';
import 'package:flutter_template/features/logs/presentation/form_feedback_dialog.dart';
import 'package:flutter_template/features/logs/presentation/session_video_view.dart';
import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/schedule/application/notification_service.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/celebration_overlay.dart';
import 'package:flutter_template/widgets/dismiss_keyboard.dart';
import 'package:flutter_template/widgets/form_fields.dart';

/// Today's session for one program: mark each exercise done or skipped,
/// optionally amend actuals / add a comment / record a form-check video,
/// then finish once everything is logged.
///
/// This is where notification taps land. Finishing a fully successful session
/// presents one Creaky success screen.
class TodayLogScreen extends ConsumerStatefulWidget {
  const TodayLogScreen({required this.programId, super.key});

  /// The program being logged today.
  final String programId;

  /// Pushes the screen for [programId].
  static Future<void> push(BuildContext context, String programId) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TodayLogScreen(programId: programId),
      ),
    );
  }

  @override
  ConsumerState<TodayLogScreen> createState() => _TodayLogScreenState();
}

class _TodayLogScreenState extends ConsumerState<TodayLogScreen> {
  String? _entryId;
  var _finishing = false;

  @override
  void initState() {
    super.initState();
    // Create today's pending entry on first open.
    unawaited(
      Future.microtask(() async {
        final entry = await ref
            .read(logsProvider.notifier)
            .ensureToday(widget.programId);
        if (mounted) setState(() => _entryId = entry.id);
      }),
    );
  }

  Future<void> _finish(
    ProgramModel program,
    LogEntryModel entry,
  ) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await ref.read(logsProvider.notifier).markSessionComplete(_entryId!);
      if (!mounted) return;
      final successful =
          sessionOutcome(program: program, entry: entry, isPast: false) ==
          SessionOutcome.completed;
      if (successful) {
        final celebration = creakyCelebrationSelector.next();
        final message = creakyEncouragementSelector.next();
        await CelebrationOverlay.show(
          context,
          celebration: celebration,
          message: message,
        );
      }
      if (mounted) Navigator.pop(context);
    } on Object {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not finish this session.')),
      );
    }
  }

  Future<void> _skipSession(ProgramModel program) async {
    await ref.read(logsProvider.notifier).skipAll(
      _entryId!,
      [for (final exercise in program.exercises) exercise.id],
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _snooze(ProgramModel program) async {
    await ref
        .read(notificationServiceProvider)
        .snoozeOneHour(
          programId: program.id,
          programName: program.name,
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _log(ExerciseLogModel log) async {
    if (_entryId == null) return;
    try {
      await ref.read(logsProvider.notifier).logExercise(_entryId!, log);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this exercise.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = ref.watch(
      programsProvider.select(
        (programs) =>
            programs.where((p) => p.id == widget.programId).firstOrNull,
      ),
    );
    final entry = ref.watch(
      logsProvider.select(
        (logs) => logs.where((log) => log.id == _entryId).firstOrNull,
      ),
    );
    if (program == null) {
      return const AppScaffold(body: SizedBox.shrink());
    }
    final catalog = ref.watch(exerciseCatalogByIdProvider).value ?? const {};
    final loggedCount = entry?.exerciseLogs.length ?? 0;
    final total = program.exercises.length;
    final allLogged =
        entry != null &&
        program.exercises.every((e) => entry.logFor(e.id) != null);

    return AppScaffold(
      title: program.name,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: AppAnimate.staggered(
                context,
                children: [
                  for (final exercise in program.exercises)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExerciseLogCard(
                        exercise: exercise,
                        catalogEntry: exercise.catalogExerciseId == null
                            ? null
                            : catalog[exercise.catalogExerciseId],
                        log: entry?.logFor(exercise.id),
                        onLog: _entryId == null ? null : _log,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$loggedCount of $total logged',
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: allLogged && !_finishing
                      ? () => _finish(program, entry)
                      : null,
                  child: Text(
                    _finishing
                        ? 'Finishing…'
                        : allLogged
                        ? 'Finish 🎉'
                        : 'Mark each exercise',
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _entryId == null
                          ? null
                          : () => _skipSession(program),
                      child: const Text('Skip today'),
                    ),
                    TextButton(
                      onPressed: () => _snooze(program),
                      child: const Text('Snooze 1h'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One exercise's row: prescription, description reminder, image, done/skip,
/// and a tap target that opens the amend sheet.
class _ExerciseLogCard extends StatelessWidget {
  const _ExerciseLogCard({
    required this.exercise,
    required this.catalogEntry,
    required this.log,
    required this.onLog,
  });

  final ProgramExercise exercise;
  final ExerciseModel? catalogEntry;
  final ExerciseLogModel? log;
  final ValueChanged<ExerciseLogModel>? onLog;

  String? get _description {
    final own = exercise.description?.trim();
    if (own != null && own.isNotEmpty) return own;
    return catalogEntry?.instructions.firstOrNull;
  }

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<ExerciseLogModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ExerciseAmendSheet(
        exercise: exercise,
        catalogEntry: catalogEntry,
        initial: log,
      ),
    );
    if (result != null) onLog?.call(result);
  }

  Future<void> _openInspect(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          _ExerciseInspectSheet(exercise: exercise, catalogEntry: catalogEntry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CreakColors>()!;
    final log = this.log;
    final done = log?.status == ExerciseLogStatus.done;
    final skipped = log?.status == ExerciseLogStatus.skipped;

    final reps = log?.repsPerSet;
    final subtitle = (done && reps != null && reps.isNotEmpty)
        ? 'Did ${reps.join(', ')}  ·  plan ${exercise.sets} × ${exercise.reps}'
        : '${exercise.sets} sets × ${exercise.reps} reps';
    final description = _description;

    return AppAnimate(
      target: done ? 1 : 0,
      effects: [
        TintEffect(color: colors.success, end: 0.12, duration: 300.ms),
      ],
      child: Card(
        child: InkWell(
          onTap: onLog == null ? null : () => _openSheet(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (catalogEntry != null) ...[
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: ExerciseMotionImage(exercise: catalogEntry!),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: skipped
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(subtitle, style: theme.textTheme.bodySmall),
                          if (description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (log?.painNote != null)
                            Text(
                              '📝 ${log!.painNote}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (log?.videoPath != null)
                            Text(
                              '🎥 Video attached',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Exercise info',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => _openInspect(context),
                        ),
                        if (done)
                          Icon(Icons.check_circle, color: colors.success)
                        else if (skipped)
                          Icon(
                            Icons.remove_circle_outline,
                            color: theme.colorScheme.outline,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!done && !skipped)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: onLog == null
                          ? null
                          : () => _openSheet(context),
                      child: const Text('Start'),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onLog == null
                          ? null
                          : () => _openSheet(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to log an exercise: shows what the exercise is, records reps
/// per set, a comment, and an optional self-recorded video.
class _ExerciseAmendSheet extends ConsumerStatefulWidget {
  const _ExerciseAmendSheet({
    required this.exercise,
    required this.catalogEntry,
    this.initial,
  });

  final ProgramExercise exercise;
  final ExerciseModel? catalogEntry;
  final ExerciseLogModel? initial;

  @override
  ConsumerState<_ExerciseAmendSheet> createState() =>
      _ExerciseAmendSheetState();
}

class _ExerciseAmendSheetState extends ConsumerState<_ExerciseAmendSheet> {
  late final List<int> _reps = _initialReps();
  late final TextEditingController _comment = TextEditingController(
    text: widget.initial?.painNote,
  );
  late String? _videoPath = widget.initial?.videoPath;
  late FormFeedbackModel? _feedback = widget.initial?.feedback;
  var _recording = false;
  var _analyzing = false;

  List<int> _initialReps() {
    final existing = widget.initial?.repsPerSet;
    if (existing != null && existing.isNotEmpty) return [...existing];
    // Growable so sets can be added/removed below.
    return List.generate(widget.exercise.sets, (_) => widget.exercise.reps);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    setState(() => _recording = true);
    try {
      final path = await ref.read(videoServiceProvider).recordAndStore();
      if (!mounted) return;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No video recorded (needs a device camera).'),
          ),
        );
        return;
      }
      // A fresh clip invalidates any feedback from the previous take.
      setState(() {
        _videoPath = path;
        _feedback = null;
      });
    } finally {
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<void> _analyze() async {
    final service = ref.read(formCheckServiceProvider);
    final videoPath = _videoPath;
    if (service == null || videoPath == null || _analyzing) return;
    setState(() => _analyzing = true);
    try {
      final feedback = await service.analyze(
        videoPath: videoPath,
        exerciseName: widget.exercise.name,
        sets: widget.exercise.sets,
        reps: widget.exercise.reps,
        targetMuscles: widget.catalogEntry?.primaryMuscles ?? const [],
        instructions: widget.catalogEntry?.instructions ?? const [],
      );
      if (!mounted) return;
      setState(() => _feedback = feedback);
      await showFormFeedback(context, feedback, widget.exercise.name);
    } on FormCheckException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _markDone() {
    final comment = _comment.text.trim();
    Navigator.pop(
      context,
      ExerciseLogModel(
        exerciseId: widget.exercise.id,
        status: ExerciseLogStatus.done,
        repsPerSet: [..._reps],
        painNote: comment.isEmpty ? null : comment,
        videoPath: _videoPath,
        feedback: _feedback,
      ),
    );
  }

  void _skip() {
    Navigator.pop(
      context,
      ExerciseLogModel(
        exerciseId: widget.exercise.id,
        status: ExerciseLogStatus.skipped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DismissKeyboard(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAbout(context),
              const SizedBox(height: 16),
              _buildReps(context),
              const SizedBox(height: 16),
              Text('Comments', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              AppTextField(
                controller: _comment,
                hint: 'e.g. sharp pain after set 2',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildVideoSection(context),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skip,
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _markDone,
                      child: const Text('Mark done ✓'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A compact header: image, name, plan, and description. Full spec lives
  /// in the info (inspect) sheet.
  Widget _buildAbout(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.catalogEntry;
    final ownDescription = widget.exercise.description?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry != null) ...[
              SizedBox(
                width: 72,
                height: 72,
                child: ExerciseMotionImage(exercise: entry),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.exercise.name, style: theme.textTheme.titleLarge),
                  Text(
                    'Plan: ${widget.exercise.sets} × ${widget.exercise.reps} '
                    'reps',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (ownDescription != null && ownDescription.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(ownDescription, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }

  /// Reps per set, one stepper per prescribed set (0 = didn't finish it).
  Widget _buildReps(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Reps you managed, per set', style: theme.textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          'Log 0 for a set you couldn’t finish.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _reps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NumberStepper(
              label: 'Set ${i + 1}',
              value: _reps[i],
              min: 0,
              onChanged: (value) => setState(() => _reps[i] = value),
            ),
          ),
      ],
    );
  }

  /// Prominent form-check video section.
  ///
  /// Before recording, shows a single record button. After recording, shows
  /// the clip inline (tap to replay) with a retake button beneath it.
  Widget _buildVideoSection(BuildContext context) {
    final theme = Theme.of(context);
    final videoPath = _videoPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Record a form check 🎥', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Film yourself so you (or your physio) can check your form later.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (videoPath == null)
          OutlinedButton.icon(
            onPressed: _recording ? null : _record,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.videocam_outlined),
            label: Text(_recording ? 'Opening camera…' : 'Record a video'),
          )
        else ...[
          SessionVideoView(path: videoPath),
          const SizedBox(height: 4),
          Text(
            'Tap the video to replay.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _recording ? null : _record,
                icon: const Icon(Icons.videocam_outlined),
                label: Text(_recording ? 'Opening camera…' : 'Retake'),
              ),
              const SizedBox(width: 8),
              _buildAnalyzeAction(context),
            ],
          ),
        ],
      ],
    );
  }

  /// The analyse / view-feedback action shown beside Retake.
  ///
  /// Hidden when no form-check service is configured. Turns into a compact
  /// "View feedback" button once analysis has produced a result.
  Widget _buildAnalyzeAction(BuildContext context) {
    if (ref.read(formCheckServiceProvider) == null) {
      return const SizedBox.shrink();
    }
    final feedback = _feedback;
    if (feedback != null) {
      return OutlinedButton.icon(
        onPressed: () =>
            showFormFeedback(context, feedback, widget.exercise.name),
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('View feedback'),
      );
    }
    if (_analyzing) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Analysing…'),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: _analyze,
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: const Text('Analyse form'),
    );
  }
}

/// Read-only detail for one exercise, opened from the session card's info
/// button so the user can check the spec mid-session.
class _ExerciseInspectSheet extends StatelessWidget {
  const _ExerciseInspectSheet({
    required this.exercise,
    required this.catalogEntry,
  });

  final ProgramExercise exercise;
  final ExerciseModel? catalogEntry;

  Future<void> _openReference() async {
    final url = Uri.tryParse(exercise.referenceUrl ?? '');
    if (url != null) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = catalogEntry;
    final description = exercise.description?.trim();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        children: [
          if (entry != null) ...[
            SizedBox(
              height: 180,
              child: ExerciseMotionImage(exercise: entry),
            ),
            const SizedBox(height: 16),
          ],
          Text(exercise.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${exercise.sets} sets × ${exercise.reps} reps',
            style: theme.textTheme.bodyMedium,
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(description, style: theme.textTheme.bodyMedium),
          ],
          if (entry != null && entry.primaryMuscles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final muscle in entry.primaryMuscles)
                  Chip(label: Text(muscle)),
                for (final muscle in entry.secondaryMuscles)
                  Chip(
                    label: Text(muscle),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
              ],
            ),
          ],
          if (entry != null && entry.instructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('How to do it', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final (index, step) in entry.instructions.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${index + 1}. $step',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
          if (exercise.referenceUrl != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openReference,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Open reference'),
            ),
          ],
        ],
      ),
    );
  }
}
