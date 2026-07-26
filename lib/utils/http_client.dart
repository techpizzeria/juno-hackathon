import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/config/config_provider.dart';

part 'http_client.g.dart';

/// The app-wide [Dio] instance.
///
/// Base URL and timeouts come from [appConfigProvider]. Repositories in the
/// data layer read this with `ref.read(dioProvider)`; nothing else should
/// construct a [Dio] directly. Add interceptors (auth, logging) here so every
/// request shares them.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.requestTimeout,
      receiveTimeout: config.requestTimeout,
    ),
  );
}
