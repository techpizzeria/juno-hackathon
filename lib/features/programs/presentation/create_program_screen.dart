import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/programs/application/llm_service.dart';
import 'package:flutter_template/features/programs/presentation/ai_chat_screen.dart';
import 'package:flutter_template/features/programs/presentation/program_edit_screen.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/mascot.dart';

/// Entry fork for adding a program: bring your own, or let Creak help.
///
/// Routes to the manual editor or the AI chat. The AI option is disabled
/// when no LLM is configured; manual creation always works.
class CreateProgramScreen extends ConsumerWidget {
  const CreateProgramScreen({super.key});

  /// Pushes the create fork.
  static Future<void> push(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProgramScreen()),
    );
  }

  /// Replaces the chooser with [screen] so that finishing creation (which
  /// flows editor → reminders) returns to whatever launched the chooser,
  /// not back to the chooser itself.
  void _launch(BuildContext context, Widget screen) {
    unawaited(
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiEnabled = ref.watch(llmProgramServiceProvider) != null;
    return AppScaffold(
      title: 'New program',
      body: Column(
        children: [
          const Spacer(),
          const Center(
            child: MascotWidget(mood: CreakyHomeMood.grey, size: 96),
          ),
          const SizedBox(height: 20),
          Text(
            'How do you want to start?',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...AppAnimate.staggered(
            context,
            children: [
              _ChoiceCard(
                icon: Icons.auto_awesome,
                title: 'Help me build one',
                subtitle: aiEnabled
                    ? 'Chat with Creak about what hurts and get a plan.'
                    : 'Add an API key to enable AI creation.',
                enabled: aiEnabled,
                onTap: () => _launch(context, const AiChatScreen()),
              ),
              const SizedBox(height: 12),
              _ChoiceCard(
                icon: Icons.edit_outlined,
                title: 'I already have a program',
                subtitle: 'Add your exercises and prescriptions yourself.',
                enabled: true,
                onTap: () => _launch(context, const ProgramEditScreen()),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// One large tappable option in the create fork.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  /// Leading glyph.
  final IconData icon;

  /// Bold option title.
  final String title;

  /// Supporting explanation.
  final String subtitle;

  /// Whether the option can be chosen.
  final bool enabled;

  /// Tap handler, ignored while disabled.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Card(
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
