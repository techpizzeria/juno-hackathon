import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/exercise_catalog/data/exercise_catalog.dart';
import 'package:flutter_template/features/programs/application/llm_service.dart';
import 'package:flutter_template/features/programs/data/generated_program_converter.dart';
import 'package:flutter_template/features/programs/domain/catalog_shortlist.dart';
import 'package:flutter_template/features/programs/domain/chat_message.dart';
import 'package:flutter_template/features/programs/domain/generated_program.dart';
import 'package:flutter_template/features/programs/presentation/program_edit_screen.dart';
import 'package:flutter_template/utils/dates.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/mascot.dart';

/// Conversational AI program creation.
///
/// The user chats with Creaky about what hurts; once there's enough context
/// they tap "Build my program", which turns the conversation into an editable
/// plan. Nothing is saved until the user commits in the editor.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  /// Pushes the AI chat flow.
  static Future<void> push(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiChatScreen()),
    );
  }

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  static const _greeting =
      "Hi, I'm Creaky ☁️ Tell me what's bothering you — what hurts, "
      'and when does it act up?';

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [
    const ChatMessage(fromUser: false, text: _greeting),
  ];

  var _sending = false;
  var _building = false;
  GeneratedProgramModel? _proposal;

  bool get _hasUserSpoken => _messages.any((m) => m.fromUser);

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      unawaited(
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  Future<void> _send() async {
    final service = ref.read(llmProgramServiceProvider);
    final text = _input.text.trim();
    if (service == null || text.isEmpty || _sending) return;
    setState(() {
      _messages.add(ChatMessage(fromUser: true, text: text));
      _input.clear();
      _sending = true;
    });
    _scrollToEnd();
    try {
      final reply = await service.chat(history: _messages);
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(fromUser: false, text: reply)));
    } on LlmException {
      if (!mounted) return;
      setState(() => _messages.add(
            const ChatMessage(
              fromUser: false,
              text: "I couldn't reach my brain just now — check your "
                  'connection and try again.',
            ),
          ));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  Future<void> _build() async {
    final service = ref.read(llmProgramServiceProvider);
    if (service == null || _building) return;
    setState(() => _building = true);
    _scrollToEnd();
    try {
      final catalog = await ref.read(exerciseCatalogProvider.future);
      final transcript = _messages
          .map((m) => '${m.fromUser ? 'User' : 'Creaky'}: ${m.text}')
          .join('\n');
      // Send only the exercises relevant to the complaint so the model picks
      // from a focused set; the converter still resolves against the full
      // catalog.
      final shortlist = shortlistForComplaint(transcript, catalog);
      final generated = await service.generateProgram(
        problemDescription: transcript,
        catalog: shortlist,
      );
      if (!mounted) return;
      setState(() => _proposal = generated);
    } on LlmException {
      if (!mounted) return;
      setState(() => _messages.add(
            const ChatMessage(
              fromUser: false,
              text: "That didn't work — let's try building it again.",
            ),
          ));
    } finally {
      if (mounted) setState(() => _building = false);
      _scrollToEnd();
    }
  }

  Future<void> _usePlan() async {
    final catalog = await ref.read(exerciseCatalogProvider.future);
    final program = convertGeneratedProgram(_proposal!, catalog);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProgramEditScreen(
          initial: program,
          advanceToReminders: true,
          suggestedSchedule: _proposal!.suggestedSchedule,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proposal = _proposal;
    return AppScaffold(
      title: 'Create with Creaky ✨',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final message in _messages)
                  _ChatBubble(message: message),
                if (_sending || _building) const _TypingIndicator(),
                if (proposal != null)
                  _ProposalCard(proposal: proposal, onUse: _usePlan),
              ],
            ),
          ),
          if (proposal == null) _buildComposer(context),
        ],
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final canBuild = _hasUserSpoken && !_sending && !_building;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: canBuild ? _build : null,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_building ? 'Building…' : 'Build my program ✨'),
          ),
        ),
      ],
    );
  }
}

/// One chat bubble, aligned by sender.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromUser = message.fromUser;
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: fromUser
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(fromUser ? 20 : 6),
          bottomRight: Radius.circular(fromUser ? 6 : 20),
        ),
      ),
      child: Text(
        message.text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: fromUser
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      ),
    );
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AppAnimate(effects: AppAnimations.cardEntrance, child: bubble),
    );
  }
}

/// Three-dot "Creaky is typing" indicator.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Creaky is thinking…', style: theme.textTheme.bodyMedium),
      ),
    );
  }
}

/// The built plan, shown in-chat with a commit action.
class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal, required this.onUse});

  final GeneratedProgramModel proposal;
  final Future<void> Function() onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = proposal.suggestedSchedule;
    final days = schedule.weekdays.map(weekdayShortLabel).join(', ');
    final time = '${schedule.hour.toString().padLeft(2, '0')}:'
        '${schedule.minute.toString().padLeft(2, '0')}';
    // Mirror the converter: the plan runs from today for the chosen weeks.
    final weeks = proposal.durationWeeks.clamp(2, 12);
    final start = DateTime.now();
    final end = start.add(Duration(days: weeks * 7));
    return AppAnimate(
      effects: AppAnimations.cardEntrance,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const MascotWidget(
                    mood: CreakyHomeMood.sunny,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      proposal.name,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(proposal.summary, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                '📅 $weeks-week plan · '
                '${monthDayLabel(start)} → ${monthDayLabel(end)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final exercise in proposal.exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${exercise.name} — ${exercise.sets} × ${exercise.reps}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                '⏰ Suggested: $days at $time',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(proposal.disclaimer, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onUse,
                  child: const Text('Use this plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
