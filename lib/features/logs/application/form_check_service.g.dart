// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_check_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The configured form-check service, or null when no Gemini key is set (the
/// UI hides the analyse action in that case).

@ProviderFor(formCheckService)
final formCheckServiceProvider = FormCheckServiceProvider._();

/// The configured form-check service, or null when no Gemini key is set (the
/// UI hides the analyse action in that case).

final class FormCheckServiceProvider
    extends
        $FunctionalProvider<
          FormCheckService?,
          FormCheckService?,
          FormCheckService?
        >
    with $Provider<FormCheckService?> {
  /// The configured form-check service, or null when no Gemini key is set (the
  /// UI hides the analyse action in that case).
  FormCheckServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'formCheckServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$formCheckServiceHash();

  @$internal
  @override
  $ProviderElement<FormCheckService?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FormCheckService? create(Ref ref) {
    return formCheckService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FormCheckService? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FormCheckService?>(value),
    );
  }
}

String _$formCheckServiceHash() => r'91d9a7371d63eef66976dea973e8233d7418ee97';
