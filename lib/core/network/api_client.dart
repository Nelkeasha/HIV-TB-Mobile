import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(storage);
});

class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final token = await _storage.getAccessToken();
            e.requestOptions.headers['Authorization'] = 'Bearer $token';
            final retryResponse = await _dio.fetch(e.requestOptions);
            return handler.resolve(retryResponse);
          }
          await _storage.clearAll();
        }
        handler.next(e);
      },
    ));
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;
      final response = await _dio.post(ApiEndpoints.refreshToken,
          data: {'refreshToken': refreshToken});
      final newToken = response.data['accessToken'] as String?;
      if (newToken != null) {
        await _storage.saveAccessToken(newToken);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  /// Converts any exception into a short, user-friendly message.
  static String friendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection is too slow. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Check your network and try again.';
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          if (code == 400) return 'Some information is missing or incorrect. Please check and try again.';
          if (code == 401) return 'Your session has expired. Please sign in again.';
          if (code == 403) return 'You do not have permission to do this.';
          if (code == 404) return 'The requested information was not found.';
          if (code == 409) return 'This record already exists.';
          if (code != null && code >= 500) return 'Server error. Please try again later.';
          return 'Something went wrong. Please try again.';
        default:
          return 'Could not connect to the server. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
