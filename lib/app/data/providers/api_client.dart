import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../core/constants/app_config.dart';
import '../../services/token_service.dart';
import 'api_exception.dart';

/// Single HTTP entry point. Repositories use this; controllers never touch Dio.
///
/// - Adds `Authorization: Bearer <access>` when a token exists.
/// - On 401 calls [onRefresh] once (wired in M1) and retries the request.
/// - Maps every failure to [ApiException].
class ApiClient extends GetxService {
  static ApiClient get to => Get.find();

  /// Returns true when tokens were refreshed. Set by AuthService in M1.
  Future<bool> Function()? onRefresh;

  /// Called when the session is dead (refresh failed). Set by AuthService in M1.
  void Function()? onSessionExpired;

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiV1,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {'Accept': 'application/json'},
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Get.isRegistered<TokenService>() ? TokenService.to.accessToken : null;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        final retried = e.requestOptions.extra['retried'] == true;
        if (e.response?.statusCode == 401 && !retried && onRefresh != null) {
          if (await onRefresh!()) {
            final opts = e.requestOptions..extra['retried'] = true;
            opts.headers['Authorization'] = 'Bearer ${TokenService.to.accessToken}';
            try {
              return handler.resolve(await _dio.fetch(opts));
            } on DioException catch (e2) {
              return handler.next(e2);
            }
          }
          onSessionExpired?.call();
        }
        handler.next(e);
      },
    ));

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put(path, data: body));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  /// Root-level probes (/health, /ready) live outside /api/v1.
  Future<dynamic> getRoot(String path) =>
      _send(() => _dio.get('${AppConfig.apiBaseUrl}$path'));

  /// Returns the `data` field of the success envelope.
  Future<dynamic> _send(Future<Response> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      return body is Map && body.containsKey('data') ? body['data'] : body;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  ApiException _map(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['error'] is Map) {
      final err = body['error'] as Map;
      return ApiException(
        statusCode: e.response?.statusCode,
        code: '${err['code'] ?? 'UNKNOWN'}',
        message: '${err['message'] ?? 'Something went wrong'}',
        details: (err['details'] as Map?)?.cast<String, dynamic>(),
      );
    }
    if (e.response == null) {
      return const ApiException(
        code: 'NETWORK',
        message: 'Cannot reach server. Check your connection.',
      );
    }
    return ApiException(
      statusCode: e.response?.statusCode,
      code: 'HTTP_${e.response?.statusCode}',
      message: e.message ?? 'Request failed',
    );
  }
}
