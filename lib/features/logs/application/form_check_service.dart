import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/config/app_config.dart';
import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/features/logs/domain/form_feedback.dart';
import 'package:flutter_template/utils/api.dart';
import 'package:flutter_template/utils/http_client.dart';

part 'form_check_service.g.dart';

/// Analyses a recorded form-check video and returns coaching feedback.
///
/// Runs entirely from the device (hackathon trade-off: no backend) against a
/// model with native video understanding.
// ignore: one_member_abstracts
abstract interface class FormCheckService {
  /// Analyses the clip at [videoPath] for the given exercise and returns
  /// structured feedback. Throws [FormCheckException] on failure.
  Future<FormFeedbackModel> analyze({
    required String videoPath,
    required String exerciseName,
    required int sets,
    required int reps,
    List<String> targetMuscles,
    List<String> instructions,
  });
}

/// The configured form-check service, or null when no Gemini key is set (the
/// UI hides the analyse action in that case).
@Riverpod(keepAlive: true)
FormCheckService? formCheckService(Ref ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.formCheckEnabled) return null;
  return GeminiFormCheckService(ref.read(dioProvider), config);
}

/// Gemini schema for the feedback JSON (OpenAPI subset: uppercase types).
const Map<String, dynamic> _feedbackSchema = {
  'type': 'OBJECT',
  'properties': {
    'score': {'type': 'INTEGER'},
    'summary': {'type': 'STRING'},
    'cues': {
      'type': 'ARRAY',
      'items': {'type': 'STRING'},
    },
    'encouragement': {'type': 'STRING'},
  },
  'required': ['score', 'summary', 'cues', 'encouragement'],
};

/// Analyses form-check videos with Google Gemini.
///
/// Uploads the clip via the Files API (handles any clip length), waits for it
/// to finish processing, then asks the model for structured feedback.
class GeminiFormCheckService implements FormCheckService {
  GeminiFormCheckService(this._dio, this._config);

  final Dio _dio;
  final AppConfig _config;

  static const _mimeType = 'video/mp4';

  String get _model =>
      _config.geminiModel.isEmpty ? 'gemini-3.6-flash' : _config.geminiModel;

  Map<String, String> get _authHeader => {
        'x-goog-api-key': _config.geminiApiKey,
      };

  @override
  Future<FormFeedbackModel> analyze({
    required String videoPath,
    required String exerciseName,
    required int sets,
    required int reps,
    List<String> targetMuscles = const [],
    List<String> instructions = const [],
  }) async {
    try {
      final file = File(videoPath);
      if (!file.existsSync()) {
        throw const FormCheckException('The recorded video is missing.');
      }
      final uploaded = await _uploadVideo(file);
      await _awaitActive(uploaded.name);
      final text = await _generate(
        fileUri: uploaded.uri,
        prompt: _prompt(
          exerciseName: exerciseName,
          sets: sets,
          reps: reps,
          targetMuscles: targetMuscles,
          instructions: instructions,
        ),
      );
      return _parse(text);
    } on DioException catch (e) {
      throw FormCheckException(_dioMessage(e));
    }
  }

  /// Resumable-uploads [file] and returns its Files API handle.
  Future<_UploadedFile> _uploadVideo(File file) async {
    final length = await file.length();
    final start = await _dio.post<Map<String, dynamic>>(
      ApiPath.geminiFilesUpload.path,
      data: {
        'file': {'display_name': 'form_check'},
      },
      options: Options(
        headers: {
          ..._authHeader,
          'X-Goog-Upload-Protocol': 'resumable',
          'X-Goog-Upload-Command': 'start',
          'X-Goog-Upload-Header-Content-Length': '$length',
          'X-Goog-Upload-Header-Content-Type': _mimeType,
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final uploadUrl = start.headers.value('x-goog-upload-url');
    if (uploadUrl == null) {
      throw const FormCheckException('The video upload could not start.');
    }

    // Stream the bytes to the returned URL and finalize in one request.
    final finalized = await _dio.post<Map<String, dynamic>>(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          'X-Goog-Upload-Command': 'upload, finalize',
          'X-Goog-Upload-Offset': '0',
          Headers.contentLengthHeader: length,
        },
        contentType: _mimeType,
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final fileJson = finalized.data?['file'] as Map<String, dynamic>?;
    final uri = fileJson?['uri'] as String?;
    final name = fileJson?['name'] as String?;
    if (uri == null || name == null) {
      throw const FormCheckException('The video upload did not complete.');
    }
    return _UploadedFile(uri: uri, name: name);
  }

  /// Polls the uploaded file until Gemini finishes processing it.
  Future<void> _awaitActive(String fileName) async {
    final statusUrl = '${ApiPath.geminiApiBase.path}/$fileName';
    for (var attempt = 0; attempt < 30; attempt++) {
      final response = await _dio.get<Map<String, dynamic>>(
        statusUrl,
        options: Options(headers: _authHeader),
      );
      final state = response.data?['state'] as String?;
      if (state == 'ACTIVE') return;
      if (state == 'FAILED') {
        throw const FormCheckException('The video could not be processed.');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw const FormCheckException('The video took too long to process.');
  }

  /// Runs generation against the processed video and returns the raw text.
  Future<String> _generate({
    required String fileUri,
    required String prompt,
  }) async {
    final url = '${ApiPath.geminiApiBase.path}/models/$_model:generateContent';
    final response = await _dio.post<Map<String, dynamic>>(
      url,
      options: Options(
        headers: _authHeader,
        receiveTimeout: const Duration(seconds: 120),
      ),
      data: {
        'contents': [
          {
            'parts': [
              {
                'file_data': {'mime_type': _mimeType, 'file_uri': fileUri},
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'responseSchema': _feedbackSchema,
        },
      },
    );
    final candidates = response.data?['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const FormCheckException('The model returned no feedback.');
    }
    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    final text = parts
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (part) => part['text'] != null,
          orElse: () => throw const FormCheckException('Empty model response.'),
        )['text']
        as String;
    return text;
  }

  /// Builds [FormFeedbackModel] leniently from the model's JSON text.
  FormFeedbackModel _parse(String jsonText) {
    try {
      final map = jsonDecode(jsonText) as Map<String, dynamic>;
      return FormFeedbackModel(
        score: (map['score'] as num?)?.toInt().clamp(1, 10) ?? 5,
        summary: (map['summary'] as String?)?.trim() ?? '',
        cues: (map['cues'] as List<dynamic>?)
                ?.map((cue) => cue.toString())
                .where((cue) => cue.trim().isNotEmpty)
                .toList() ??
            const [],
        encouragement: (map['encouragement'] as String?)?.trim() ?? '',
        analyzedAt: DateTime.now(),
      );
    } on FormCheckException {
      rethrow;
    } on Object catch (e) {
      throw FormCheckException('Could not read the feedback: $e');
    }
  }

  String _prompt({
    required String exerciseName,
    required int sets,
    required int reps,
    required List<String> targetMuscles,
    required List<String> instructions,
  }) {
    final muscles =
        targetMuscles.isEmpty ? 'not specified' : targetMuscles.join(', ');
    final how = instructions.isEmpty
        ? ''
        : '\nReference technique:\n- ${instructions.join('\n- ')}';
    return 'You are a supportive physiotherapy form coach reviewing a short '
        'self-recorded clip of someone doing a home exercise.\n\n'
        'Exercise: $exerciseName\n'
        'Prescription: $sets sets of $reps reps\n'
        'Target muscles: $muscles$how\n\n'
        'Watch the movement and give brief, encouraging, practical feedback. '
        'Return: score (1-10 rough form quality), summary (one sentence), '
        'cues (2 to 4 short, specific things to improve), and encouragement '
        '(one warm sentence). If the clip does not clearly show the exercise, '
        'say so in the summary and score conservatively. This is general '
        'movement guidance, not medical advice.';
  }

  String _dioMessage(DioException e) {
    final status = e.response?.statusCode;
    if (status != null) {
      return 'The AI service returned an error ($status). '
          'Check your Gemini API key and try again.';
    }
    return 'Could not reach the AI service. Check your connection.';
  }
}

/// A file handle returned by the Gemini Files API.
class _UploadedFile {
  const _UploadedFile({required this.uri, required this.name});

  /// Absolute file URI referenced in generation requests.
  final String uri;

  /// Resource name (`files/…`) used to poll processing state.
  final String name;
}
