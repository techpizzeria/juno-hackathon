// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The configured LLM service, or null when no provider/key is set (the UI
/// hides AI creation in that case; manual creation always works).

@ProviderFor(llmProgramService)
final llmProgramServiceProvider = LlmProgramServiceProvider._();

/// The configured LLM service, or null when no provider/key is set (the UI
/// hides AI creation in that case; manual creation always works).

final class LlmProgramServiceProvider
    extends
        $FunctionalProvider<
          LlmProgramService?,
          LlmProgramService?,
          LlmProgramService?
        >
    with $Provider<LlmProgramService?> {
  /// The configured LLM service, or null when no provider/key is set (the UI
  /// hides AI creation in that case; manual creation always works).
  LlmProgramServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmProgramServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmProgramServiceHash();

  @$internal
  @override
  $ProviderElement<LlmProgramService?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LlmProgramService? create(Ref ref) {
    return llmProgramService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LlmProgramService? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LlmProgramService?>(value),
    );
  }
}

String _$llmProgramServiceHash() => r'34d98cb848e0dc6de327a6d5367a0ebfd25785f0';
