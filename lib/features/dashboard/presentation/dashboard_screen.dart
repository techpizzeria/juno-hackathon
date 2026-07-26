import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/features/logs/data/logs.dart';
import 'package:flutter_template/features/logs/data/today.dart';
import 'package:flutter_template/features/logs/domain/log_entry.dart';
import 'package:flutter_template/features/logs/domain/streak.dart';
import 'package:flutter_template/features/logs/presentation/history_screen.dart';
import 'package:flutter_template/features/logs/presentation/today_log_screen.dart';
import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/programs/presentation/program_list_screen.dart';
import 'package:flutter_template/features/schedule/data/schedules.dart';
import 'package:flutter_template/features/schedule/presentation/schedule_editor_screen.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_template/utils/dates.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/daily_progress_arc.dart';
import 'package:flutter_template/widgets/debug_reset_button.dart';
import 'package:flutter_template/widgets/mascot.dart';

/// Creak's landing screen.
///
/// A warm peach header holds the mascot straddling the lip of a raised
/// foreground panel. The panel shows the streak and today's status, then a
/// short list of actions (history, programs, reminders). The page never
/// scrolls; only deeper lists (exercises) do.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  CreakyHomeMood? _moodOverride;

  void _cycleMood() {
    const moods = CreakyHomeMood.values;
    setState(() {
      final current = _moodOverride ?? CreakyHomeMood.grey;
      _moodOverride = moods[(moods.indexOf(current) + 1) % moods.length];
    });
  }

  CreakyHomeMood _derivedMood({
    required List<SessionView> sessions,
    required bool yesterdayMissed,
  }) {
    final override = _moodOverride;
    if (override != null) return override;
    if (sessions.isNotEmpty &&
        sessions.every(
          (s) =>
              s.outcome == SessionOutcome.completed ||
              s.outcome == SessionOutcome.partial,
        )) {
      return CreakyHomeMood.sunny;
    }
    if (yesterdayMissed) return CreakyHomeMood.rainy;
    if (DateTime.now().hour >= 21) return CreakyHomeMood.stormy;
    return CreakyHomeMood.grey;
  }

  void _openReminders(List<ProgramModel> programs) {
    if (programs.length == 1) {
      unawaited(ScheduleEditorScreen.push(context, programs.first.id));
    } else {
      unawaited(ProgramListScreen.push(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDebugTools = ref.watch(
      appConfigProvider.select((c) => c.showDebugTools),
    );
    final programs = ref.watch(programsProvider);
    final sessions = ref.watch(todaysSessionsProvider);
    final streak = ref.watch(streakProvider);
    final weekDone = ref.watch(weekDoneDaysProvider);

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final yesterdayMissed =
        _hadScheduledSessions(yesterday) &&
        !daySatisfied(
          programs: programs,
          schedules: ref.watch(schedulesProvider),
          logs: ref.watch(logsProvider),
          day: yesterday,
        );

    final mood = _derivedMood(
      sessions: sessions,
      yesterdayMissed: yesterdayMissed,
    );

    return AppScaffold(
      floatingActionButton: showDebugTools ? const DebugResetButton() : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GreetingHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: _MascotPanel(
              mood: mood,
              progress: _todayProgress(sessions),
              onMascotLongPress: showDebugTools ? _cycleMood : null,
              child: _DashboardContent(
                streak: streak,
                doneWeekdays: weekDone,
                sessions: sessions,
                programCount: programs.length,
                onStartSession: (programId) =>
                    TodayLogScreen.push(context, programId),
                onHistory: () => HistoryScreen.push(context),
                onPrograms: () => ProgramListScreen.push(context),
                onReminders: () => _openReminders(programs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hadScheduledSessions(DateTime day) {
    final programs = ref.watch(programsProvider);
    final schedules = ref.watch(schedulesProvider);
    return programs.any(
      (p) => isScheduledOn(
        p,
        schedules.where((s) => s.programId == p.id).firstOrNull,
        day,
      ),
    );
  }
}

/// Fraction of today's scheduled exercises already marked done, for the
/// arch gauge. Zero when nothing is scheduled.
double _todayProgress(List<SessionView> sessions) {
  var total = 0;
  var done = 0;
  for (final session in sessions) {
    final currentIds = {for (final e in session.program.exercises) e.id};
    total += currentIds.length;
    final entry = session.entry;
    if (entry == null) continue;
    // Only current exercises count; a program edit can leave stale logs for
    // exercises that were removed.
    done += entry.exerciseLogs
        .where(
          (log) =>
              log.status == ExerciseLogStatus.done &&
              currentIds.contains(log.exerciseId),
        )
        .length;
  }
  return total == 0 ? 0 : done / total;
}

/// Greeting and today's date.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_greeting 👋', style: textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(
            DateFormat.MMMMEEEEd().format(DateTime.now()),
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// The raised foreground panel with the mascot straddling its top lip and a
/// coral arc glowing behind it.
class _MascotPanel extends StatelessWidget {
  const _MascotPanel({
    required this.mood,
    required this.progress,
    required this.child,
    this.onMascotLongPress,
  });

  final CreakyHomeMood mood;

  /// Today's completion fraction, shown as the arch gauge behind the mascot.
  final double progress;
  final Widget child;
  final VoidCallback? onMascotLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mascotSize = constraints.maxWidth >= 600
            ? 208.0
            : (constraints.maxWidth * 0.48).clamp(140.0, 176.0);
        final arcSize = mascotSize + 60;
        final sheetGap = mascotSize * 0.7;
        final mascotCenterY = mascotSize / 2;
        return Center(
          child: SingleChildScrollView(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Daily-progress arch, centred on the mascot.
                Positioned(
                  top: mascotCenterY - arcSize / 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DailyProgressArc(progress: progress, size: arcSize),
                  ),
                ),
                // The foreground sheet, sized to just fit its content.
                Padding(
                  padding: EdgeInsets.only(top: sheetGap),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      math.max(44, mascotSize - sheetGap + 12),
                      20,
                      24,
                    ),
                    child: child,
                  ),
                ),
                // Mascot straddling the sheet lip.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onLongPress: onMascotLongPress,
                      child: MascotWidget(mood: mood, size: mascotSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The panel body: streak, today's status, and the action list. The same
/// three sections show whether or not a program exists yet.
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.streak,
    required this.doneWeekdays,
    required this.sessions,
    required this.programCount,
    required this.onStartSession,
    required this.onHistory,
    required this.onPrograms,
    required this.onReminders,
  });

  final int streak;

  /// 1=Mon..7=Sun indices of this week's completed days.
  final Set<int> doneWeekdays;
  final List<SessionView> sessions;
  final int programCount;
  final ValueChanged<String> onStartSession;
  final VoidCallback onHistory;
  final VoidCallback onPrograms;
  final VoidCallback onReminders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CreakColors>()!;
    final pending = sessions
        .where((s) => s.outcome == SessionOutcome.pending)
        .firstOrNull;
    final allDone =
        sessions.isNotEmpty &&
        sessions.every(
          (s) =>
              s.outcome == SessionOutcome.completed ||
              s.outcome == SessionOutcome.partial,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: AppAnimate.staggered(
        context,
        children: [
          Text(
            streak == 0 ? 'Start your streak' : '$streak-day streak 🔥',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: streak == 0
                  ? theme.colorScheme.onSurface
                  : colors.streakFlame,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _WeekDots(doneWeekdays: doneWeekdays),
          const SizedBox(height: 16),
          // Start-session prompt only appears when a session is actually due.
          if (pending != null) ...[
            _StartSessionCard(
              programName: pending.program.name,
              onTap: () => onStartSession(pending.program.id),
            ),
            const SizedBox(height: 10),
          ] else if (allDone) ...[
            Text(
              'All done today 🎉',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          _ActionRow(
            icon: Icons.fitness_center,
            title: 'Programs',
            trailing: '$programCount',
            onTap: onPrograms,
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: Icons.notifications_active_outlined,
            title: 'Reminders',
            subtitle: 'Set your reminder times',
            onTap: onReminders,
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: Icons.history,
            title: 'History',
            subtitle: 'Your logged sessions',
            onTap: onHistory,
          ),
        ],
      ),
    );
  }
}

/// The attention-grabbing "do your session" card.
///
/// Shares the action-row shape but uses the primary colour, a looping pulse,
/// and lightning-bolt emojis flickering around it like a storm (the mascot
/// is a cloud) so it clearly reads as the thing to do next.
class _StartSessionCard extends StatelessWidget {
  const _StartSessionCard({required this.programName, required this.onTap});

  /// Program whose session is due.
  final String programName;

  /// Starts the session.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulsingCard = AppAnimate(
      onPlay: (c) => c.repeat(reverse: true),
      effects: AppAnimations.pulse,
      child: Card(
        color: theme.colorScheme.primary,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start today’s session',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        programName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow_rounded,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The card is the only non-positioned child, so it sizes the stack;
        // a scatter of bolts flickers around its edges like a storm.
        pulsingCard,
        for (final bolt in _bolts)
          Positioned(
            top: bolt.top,
            bottom: bolt.bottom,
            left: bolt.left,
            right: bolt.right,
            child: _Bolt(
              size: bolt.size,
              period: bolt.period,
              delayMs: bolt.delay,
              minOpacity: bolt.minOpacity,
            ),
          ),
      ],
    );
  }
}

/// Placement + timing for one storm bolt.
class _BoltSpec {
  const _BoltSpec(
    this.size,
    this.period,
    this.delay,
    this.minOpacity, {
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final double size;
  final int period;
  final int delay;

  /// Opacity at the trough; 0 fully vanishes, >0 just dims.
  final double minOpacity;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
}

/// Mixed sizes, periods, and phase delays keep the storm lively and
/// unsynchronised.
const _bolts = [
  _BoltSpec(22, 700, 0, 0, top: -12, left: 6),
  _BoltSpec(14, 1300, 250, 0.3, top: -18, left: 96),
  _BoltSpec(16, 1100, 500, 0, top: -8, right: 120),
  _BoltSpec(26, 900, 150, 0, top: -14, right: 20),
  _BoltSpec(18, 1000, 350, 0, bottom: -14, left: 28),
  _BoltSpec(13, 1500, 600, 0.35, bottom: -8, left: 132),
  _BoltSpec(24, 800, 100, 0, bottom: -16, right: 84),
  _BoltSpec(15, 1200, 450, 0, bottom: -6, right: 12),
  _BoltSpec(14, 1400, 700, 0.3, top: 18, left: -8),
  _BoltSpec(16, 1050, 200, 0, top: 20, right: -6),
];

/// A single flickering lightning-bolt emoji.
class _Bolt extends StatelessWidget {
  const _Bolt({
    required this.size,
    required this.period,
    required this.delayMs,
    required this.minOpacity,
  });

  /// Glyph size.
  final double size;

  /// Flicker period in milliseconds.
  final int period;

  /// One-time start delay that offsets this bolt's phase from the others.
  final int delayMs;

  /// Opacity at the trough; 0 makes the bolt fully appear and disappear.
  final double minOpacity;

  @override
  Widget build(BuildContext context) {
    return AppAnimate(
      delay: Duration(milliseconds: delayMs),
      onPlay: (c) => c.repeat(reverse: true),
      effects: [
        FadeEffect(
          begin: minOpacity,
          end: 1,
          duration: period.ms,
          curve: Curves.easeInOut,
        ),
        ScaleEffect(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.15, 1.15),
          duration: period.ms,
          curve: Curves.easeInOut,
        ),
      ],
      child: Text('⚡', style: TextStyle(fontSize: size)),
    );
  }
}

/// One dot per weekday (Mon–Sun), filled when that day's sessions were done.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.doneWeekdays});

  final Set<int> doneWeekdays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CreakColors>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          Column(
            children: [
              Text(
                weekdayShortLabel(day).substring(0, 1),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              CircleAvatar(
                radius: 6,
                backgroundColor: doneWeekdays.contains(day)
                    ? colors.streakFlame
                    : theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
      ],
    );
  }
}

/// One tappable action row: icon, title, optional value, chevron.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  /// Leading glyph.
  final IconData icon;

  /// Bold row title.
  final String title;

  /// Tap handler.
  final VoidCallback onTap;

  /// Optional supporting line.
  final String? subtitle;

  /// Optional trailing value shown before the chevron.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[
                Text(trailing!, style: theme.textTheme.titleMedium),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
