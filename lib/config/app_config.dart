import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Immutable runtime configuration for the app.
///
/// Holds environment-dependent values (API base URL, timeouts). Resolved once
/// at launch by [AppConfig.resolve] and injected into the provider tree via an
/// override in `main.dart`, so feature code reads config through
/// `ref.watch(appConfigProvider)` instead of touching globals.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.llmProvider,
    required this.llmApiKey,
    required this.llmModel,
    required this.showDebugTools,
    this.requestTimeout = const Duration(seconds: 15),
  });

  /// Base URL every `dioProvider` request is resolved against.
  final String apiBaseUrl;

  /// Connect/receive timeout applied to outgoing requests.
  final Duration requestTimeout;

  /// LLM vendor for AI program creation: `openai` (default) or `anthropic`.
  final String llmProvider;

  /// API key for [llmProvider]. Empty disables AI program creation.
  final String llmApiKey;

  /// Model override; each provider implementation supplies a default.
  final String llmModel;

  /// Whether developer helpers (e.g. test-notification button) are shown.
  final bool showDebugTools;

  /// Whether AI program creation is available in this build.
  bool get llmEnabled => llmProvider.isNotEmpty && llmApiKey.isNotEmpty;

  /// Builds the config for the current build.
  ///
  /// LLM values come from the loaded `.env` file first (see
  /// `dotenv.load` in `main.dart`), falling back to `--dart-define` when the
  /// `.env` has no non-empty entry. So both of these work:
  /// `LLM_API_KEY=sk-...` in `.env`, or
  /// `flutter run --dart-define=LLM_API_KEY=sk-...`.
  factory AppConfig.resolve() {
    return AppConfig(
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://catfact.ninja',
      ),
      llmProvider: _envOr(
        'LLM_PROVIDER',
        const String.fromEnvironment('LLM_PROVIDER', defaultValue: 'openai'),
      ),
      llmApiKey: _envOr(
        'LLM_API_KEY',
        const String.fromEnvironment('LLM_API_KEY'),
      ),
      llmModel: _envOr('LLM_MODEL', const String.fromEnvironment('LLM_MODEL')),
      showDebugTools: const bool.fromEnvironment('SHOW_DEBUG_TOOLS'),
    );
  }
}

/// Reads [key] from the loaded `.env`, or returns [dartDefine] when the
/// file is absent, unloaded, or the entry is blank.
String _envOr(String key, String dartDefine) {
  final value = dotenv.isInitialized ? dotenv.maybeGet(key) : null;
  return (value != null && value.isNotEmpty) ? value : dartDefine;
}
