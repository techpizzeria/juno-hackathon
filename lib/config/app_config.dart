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
  /// Values can be overridden at build time with `--dart-define`, e.g.
  /// `flutter run --dart-define=LLM_PROVIDER=anthropic \
  ///  --dart-define=LLM_API_KEY=sk-...`.
  factory AppConfig.resolve() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://catfact.ninja',
      ),
      llmProvider: String.fromEnvironment(
        'LLM_PROVIDER',
        defaultValue: 'openai',
      ),
      llmApiKey: String.fromEnvironment('LLM_API_KEY'),
      llmModel: String.fromEnvironment('LLM_MODEL'),
      showDebugTools: bool.fromEnvironment('SHOW_DEBUG_TOOLS'),
    );
  }
}
