import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/config/app_config.dart';
import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';
import 'package:flutter_template/features/programs/domain/chat_message.dart';
import 'package:flutter_template/features/programs/domain/generated_program.dart';
import 'package:flutter_template/utils/api.dart';
import 'package:flutter_template/utils/http_client.dart';

part 'llm_service.g.dart';

/// Turns a user's complaint into a structured physio program via an LLM.
///
/// Implementations call the vendor API directly from the device (hackathon
/// trade-off: no backend) and force schema-constrained JSON output so the
/// result parses deterministically.
abstract interface class LlmProgramService {
  /// Continues the creation conversation and returns the assistant's next
  /// reply as plain text. Throws [LlmException] on transport failure.
  Future<String> chat({
    required List<ChatMessage> history,
  });

  /// Generates a structured program from the conversation so far in
  /// [problemDescription], preferring exercises from [catalog]. Throws
  /// [LlmException] on transport or parse failure.
  Future<GeneratedProgramModel> generateProgram({
    required String problemDescription,
    required List<ExerciseModel> catalog,
  });
}

/// The configured LLM service, or null when no provider/key is set (the UI
/// hides AI creation in that case; manual creation always works).
@Riverpod(keepAlive: true)
LlmProgramService? llmProgramService(Ref ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.llmEnabled) return null;
  final dio = ref.read(dioProvider);
  return switch (config.llmProvider) {
    'anthropic' => AnthropicLlmService(dio, config),
    'openai' => OpenAiLlmService(dio, config),
    _ => null,
  };
}

/// JSON schema both providers are forced to follow.
///
/// No numeric min/max constraints (unsupported by structured outputs);
/// ranges are clamped in the converter instead.
const Map<String, dynamic> programJsonSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'name',
    'summary',
    'disclaimer',
    'exercises',
    'suggestedSchedule',
  ],
  'properties': {
    'name': {'type': 'string'},
    'summary': {'type': 'string'},
    'disclaimer': {'type': 'string'},
    'exercises': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'name',
          'catalogExerciseId',
          'sets',
          'reps',
          'description',
        ],
        'properties': {
          'name': {'type': 'string'},
          'catalogExerciseId': {
            'type': ['string', 'null'],
          },
          'sets': {'type': 'integer'},
          'reps': {'type': 'integer'},
          'description': {
            'type': ['string', 'null'],
          },
        },
      },
    },
    'suggestedSchedule': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['weekdays', 'hour', 'minute'],
      'properties': {
        'weekdays': {
          'type': 'array',
          'items': {'type': 'integer'},
        },
        'hour': {'type': 'integer'},
        'minute': {'type': 'integer'},
      },
    },
  },
};

String _chatSystemPrompt() =>
    'You are Creak, a warm, encouraging physiotherapy assistant helping the '
    'user shape a home exercise program through a short chat. Ask one or two '
    'brief questions at a time (what hurts, how long, how severe, their goal) '
    'to understand their situation. Keep every reply to one to three friendly '
    'sentences and feel free to use a light emoji. Do not list a full program '
    'or specific sets and reps in chat. Once you understand enough, reassure '
    'them and tell them to tap “Build my program ✨” below to see their plan. '
    'Never diagnose; gently suggest seeing a professional for severe or '
    'persistent pain.';

String _systemPrompt() =>
    'You are a careful physiotherapy exercise assistant inside a habit app. '
    "Given a user's complaint, produce a conservative, beginner-safe home "
    'exercise program: 2 to 6 exercises with realistic sets and reps, about '
    '3 sessions per week unless daily gentle mobility clearly fits better. '
    'Prefer exercises from the CATALOG provided; when you use one, set '
    'catalogExerciseId to its exact id, otherwise set it to null and give a '
    'clear name plus a one-line description. Never diagnose. Include a short '
    'disclaimer advising to see a professional for persistent pain. '
    'weekdays use 1=Monday..7=Sunday.';

String _userPrompt(String problem, List<ExerciseModel> catalog) {
  final lines = catalog
      .map((e) => '${e.id} | ${e.name} | ${e.primaryMuscles.join(",")} | '
          '${e.level}')
      .join('\n');
  return 'Complaint: $problem\n\nCATALOG:\n$lines';
}

GeneratedProgramModel _parse(String jsonText) {
  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const LlmException('Model returned non-object JSON');
    }
    return GeneratedProgramModel.fromJson(decoded);
  } on LlmException {
    rethrow;
  } on Object catch (e) {
    throw LlmException('Could not parse the generated program: $e');
  }
}

/// Calls the Anthropic Messages API with schema-constrained output.
class AnthropicLlmService implements LlmProgramService {
  AnthropicLlmService(this._dio, this._config);

  final Dio _dio;
  final AppConfig _config;

  String get _model =>
      _config.llmModel.isEmpty ? 'claude-opus-4-8' : _config.llmModel;

  Options get _options => Options(
        headers: {
          'x-api-key': _config.llmApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        receiveTimeout: const Duration(seconds: 90),
      );

  @override
  Future<String> chat({required List<ChatMessage> history}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPath.anthropicMessages.path,
        options: _options,
        data: {
          'model': _model,
          'max_tokens': 1024,
          'system': _chatSystemPrompt(),
          'messages': [
            for (final message in history)
              {'role': message.role, 'content': message.text},
          ],
        },
      );
      final content = response.data!['content'] as List<dynamic>;
      return content
          .cast<Map<String, dynamic>>()
          .firstWhere((block) => block['type'] == 'text')['text'] as String;
    } on DioException catch (e) {
      throw LlmException(_dioMessage(e));
    }
  }

  @override
  Future<GeneratedProgramModel> generateProgram({
    required String problemDescription,
    required List<ExerciseModel> catalog,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPath.anthropicMessages.path,
        options: _options,
        data: {
          'model': _model,
          'max_tokens': 4096,
          'output_config': {
            'format': {'type': 'json_schema', 'schema': programJsonSchema},
          },
          'system': _systemPrompt(),
          'messages': [
            {
              'role': 'user',
              'content': _userPrompt(problemDescription, catalog),
            },
          ],
        },
      );
      final content = response.data!['content'] as List<dynamic>;
      final text = content
          .cast<Map<String, dynamic>>()
          .firstWhere((block) => block['type'] == 'text')['text'] as String;
      return _parse(text);
    } on DioException catch (e) {
      throw LlmException(_dioMessage(e));
    }
  }
}

/// Calls the OpenAI chat completions API with strict JSON schema output.
class OpenAiLlmService implements LlmProgramService {
  OpenAiLlmService(this._dio, this._config);

  final Dio _dio;
  final AppConfig _config;

  String get _model => _config.llmModel.isEmpty ? 'gpt-4o' : _config.llmModel;

  Options get _options => Options(
        headers: {
          'Authorization': 'Bearer ${_config.llmApiKey}',
          'content-type': 'application/json',
        },
        receiveTimeout: const Duration(seconds: 90),
      );

  @override
  Future<String> chat({required List<ChatMessage> history}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPath.openAiChatCompletions.path,
        options: _options,
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _chatSystemPrompt()},
            for (final message in history)
              {'role': message.role, 'content': message.text},
          ],
        },
      );
      final choices = response.data!['choices'] as List<dynamic>;
      final message = (choices.first as Map<String, dynamic>)['message']
          as Map<String, dynamic>;
      return message['content'] as String;
    } on DioException catch (e) {
      throw LlmException(_dioMessage(e));
    }
  }

  @override
  Future<GeneratedProgramModel> generateProgram({
    required String problemDescription,
    required List<ExerciseModel> catalog,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPath.openAiChatCompletions.path,
        options: _options,
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt()},
            {
              'role': 'user',
              'content': _userPrompt(problemDescription, catalog),
            },
          ],
          'response_format': {
            'type': 'json_schema',
            'json_schema': {
              'name': 'physio_program',
              'strict': true,
              'schema': programJsonSchema,
            },
          },
        },
      );
      final choices = response.data!['choices'] as List<dynamic>;
      final message =
          (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>;
      return _parse(message['content'] as String);
    } on DioException catch (e) {
      throw LlmException(_dioMessage(e));
    }
  }
}

String _dioMessage(DioException e) {
  final status = e.response?.statusCode;
  if (status != null) {
    return 'The AI service returned an error ($status). '
        'Check your API key and try again.';
  }
  return 'Could not reach the AI service. Check your connection.';
}
