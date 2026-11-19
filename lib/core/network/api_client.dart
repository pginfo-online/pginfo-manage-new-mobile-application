import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://pginfo.space/api/v1',
);
final storageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

class ApiFailure implements Exception {
  const ApiFailure(this.message, this.status);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.storage) {
    if (kReleaseMode && Uri.parse(apiBaseUrl).scheme != 'https') {
      throw StateError('Release builds require an HTTPS API_BASE_URL');
    }
    dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'accessToken');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          options.headers['X-Request-Id'] = DateTime.now()
              .microsecondsSinceEpoch
              .toRadixString(36);
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              'API ${response.requestOptions.method} ${response.statusCode} ${response.requestOptions.headers['X-Request-Id']}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
              'API ${error.requestOptions.method} ${error.response?.statusCode ?? 'network'} ${error.requestOptions.headers['X-Request-Id']}',
            );
          }
          if (error.response?.statusCode != 401 ||
              error.requestOptions.extra['retried'] == true ||
              error.requestOptions.path.contains('/auth/')) {
            handler.next(error);
            return;
          }
          try {
            final current = await storage.read(key: 'accessToken');
            final accessToken =
                current != null &&
                    error.requestOptions.headers['Authorization'] !=
                        'Bearer $current'
                ? current
                : await (_refreshing ??= _refreshAccessToken());
            final request = error.requestOptions;
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $accessToken';
            handler.resolve(await dio.fetch<dynamic>(request));
          } catch (_) {
            await clearTokens();
            handler.next(error);
          } finally {
            _refreshing = null;
          }
        },
      ),
    );
  }
  final FlutterSecureStorage storage;
  late final Dio dio;
  Future<String>? _refreshing;
  Future<String> _refreshAccessToken() async {
    final refresh = await storage.read(key: 'refreshToken');
    if (refresh == null) throw const ApiFailure('Session expired', 401);
    final response = await Dio(BaseOptions(baseUrl: apiBaseUrl))
        .post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refresh},
        );
    final tokens = response.data!['tokens'] as Map<String, dynamic>;
    await saveTokens(tokens);
    return tokens['accessToken'] as String;
  }

  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    await storage.write(
      key: 'accessToken',
      value: tokens['accessToken'] as String?,
    );
    if (tokens['refreshToken'] != null) {
      await storage.write(
        key: 'refreshToken',
        value: tokens['refreshToken'] as String,
      );
    }
  }

  Future<void> clearTokens() async {
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async => _request(
    () => dio.get<dynamic>(
      path,
      queryParameters: query,
      cancelToken: cancelToken,
    ),
  );
  Future<dynamic> post(String path, Map<String, dynamic> data) async =>
      _request(() => dio.post<dynamic>(path, data: data));
  Future<dynamic> upload(
    String path, {
    required String filePath,
    required String filename,
    required String purpose,
  }) async => _request(
    () async => dio.post<dynamic>(
      path,
      queryParameters: {'purpose': purpose},
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      }),
    ),
  );
  Future<dynamic> patch(String path, Map<String, dynamic> data) async =>
      _request(() => dio.patch<dynamic>(path, data: data));
  Future<dynamic> delete(String path) async =>
      _request(() => dio.delete<dynamic>(path));
  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      final body = e.response?.data;
      final message = body is Map
          ? (body['detail'] ?? body['message'] ?? body['title'])?.toString()
          : null;
      throw ApiFailure(
        message ??
            (e.type == DioExceptionType.connectionError
                ? 'Connection unavailable. Check your network.'
                : 'Request failed. Please try again.'),
        e.response?.statusCode,
      );
    }
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(storageProvider)),
);
