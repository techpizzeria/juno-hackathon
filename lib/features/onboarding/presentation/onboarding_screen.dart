import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter_template/features/onboarding/data/onboarding_repository.dart';
import 'package:flutter_template/features/programs/application/llm_service.dart';
import 'package:flutter_template/features/programs/presentation/ai_chat_screen.dart';
import 'package:flutter_template/features/programs/presentation/create_program_screen.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/mascot.dart';

/// First-run welcome that introduces Creaky and flows into program creation.
///
/// Shown once (gated by [OnboardingRepository]); afterwards the app opens on
/// the dashboard. Both actions mark the intro seen: "Let's build" hands off to
/// the conversational AI creation (or the manual fork when no LLM is
/// configured) over a dashboard base, and "Skip" drops the user on the
/// dashboard to explore first.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _begin(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingRepositoryProvider).markIntroSeen();
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final aiEnabled = ref.read(llmProgramServiceProvider) != null;
    // Land on the dashboard so backing out of creation returns there, then
    // open the creation flow on top.
    unawaited(
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      ),
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              aiEnabled ? const AiChatScreen() : const CreateProgramScreen(),
        ),
      ),
    );
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingRepositoryProvider).markIntroSeen();
    if (!context.mounted) return;
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAnimate(
                      effects: AppAnimations.cardEntrance,
                      child: const MascotWidget(
                        mood: CreakyHomeMood.sunny,
                        size: 160,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...AppAnimate.staggered(
                      context,
                      children: [
                        Text(
                          "Hi, I'm Creaky ☁️",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "I'll help you stick to your physio.\n"
                          "We'll build a quick plan, I'll nudge you at the "
                          'right times, and you keep your streak going.',
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => _begin(context, ref),
            child: const Text("Let's build your plan"),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _skip(context, ref),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}
