/// Every backend endpoint the app calls, in one place.
///
/// Repositories build request paths from this enum instead of hardcoding
/// strings, so the full API surface is discoverable and typo-safe. Paths are
/// relative to `AppConfig.apiBaseUrl` (see `dioProvider`).
enum ApiPath {
  /// Anthropic Messages API (absolute URL, bypasses the dio base URL).
  anthropicMessages('https://api.anthropic.com/v1/messages'),

  /// OpenAI chat completions API (absolute URL, bypasses the dio base URL).
  openAiChatCompletions('https://api.openai.com/v1/chat/completions');

  const ApiPath(this.path);

  /// The URL path, resolved against the configured base URL.
  ///
  /// Absolute `https://` values are sent as-is; dio only prepends the base
  /// URL to relative paths.
  final String path;
}

/// Thrown when the backend returns an error response.
///
/// Repositories catch `DioException` and rethrow this so the rest of the app
/// depends on a domain-owned error type, not on transport (dio) types.
class ApiException implements Exception {
  const ApiException(this.body, this.statusCode);

  /// The decoded error payload, when the server sent one.
  final Map<String, dynamic> body;

  /// The HTTP status code of the failed response.
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $body';
}
