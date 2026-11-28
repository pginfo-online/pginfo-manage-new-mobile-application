import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://app.pginfo.business/api/v1',
);
final storageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

// Claims are used for local scoping. The server authenticates the token.
Map<String, dynamic>? readAccessTokenClaims(String? token) {
  final parts = token?.split('.');
  if (parts == null || parts.length != 3) return null;
  try {
    final claims = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return claims is Map<String, dynamic> ? claims : null;
  } on FormatException {
    return null;
  }
}

final sessionRevisionProvider = NotifierProvider<SessionRevision, int>(
  SessionRevision.new,
);

class SessionRevision extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

class ApiFailure implements Exception {
  const ApiFailure(this.message, this.status, {this.code, this.retryAfter});
  final String message;
  final int? status;
  final String? code;
  final Duration? retryAfter;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.storage, {this.onSessionExpired}) {
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
          if (!options.path.startsWith('/auth/otp/')) {
            final token = await storage.read(key: 'accessToken');
            if (token != null && options.extra['retried'] != true) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
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
          final authorization = error.requestOptions.headers['Authorization'];
          final previous =
              authorization is String && authorization.startsWith('Bearer ')
              ? authorization.substring(7)
              : null;
          try {
            final current = await storage.read(key: 'accessToken');
            if (previous == null || current == null) {
              handler.next(error);
              return;
            }
            final access = current == previous
                ? await (_refreshing ??= _refreshAccessToken(previous)
                      .whenComplete(() => _refreshing = null))
                : current;
            if (!_sameSession(previous, access)) {
              handler.next(error);
              return;
            }
            final request = error.requestOptions;
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $access';
            handler.resolve(await dio.fetch<dynamic>(request));
          } on DioException catch (failure) {
            handler.next(failure);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }
  final FlutterSecureStorage storage;
  final VoidCallback? onSessionExpired;
  late final Dio dio;
  Future<String>? _refreshing;

  bool _sameSession(String previous, String current) {
    final before = readAccessTokenClaims(previous);
    final after = readAccessTokenClaims(current);
    return before?['sub'] != null &&
        before?['sub'] == after?['sub'] &&
        before?['orgId'] == after?['orgId'];
  }

  Future<String> _refreshAccessToken(String previous) async {
    try {
      final refresh = await storage.read(key: 'refreshToken');
      if (refresh == null) throw const ApiFailure('Session expired', 401);
      final organization = readAccessTokenClaims(previous)?['orgId'];
      final response =
          await Dio(
            BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
            ),
          ).post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {
              'refreshToken': refresh,
              if (organization is String) 'organizationId': organization,
            },
          );
      final tokens = response.data!['tokens'] as Map<String, dynamic>;
      final access = tokens['accessToken'] as String;
      final current = await storage.read(key: 'accessToken');
      if (current != previous) {
        // Keep the access token selected by an organization switch, while
        // retaining the rotated refresh token for that authenticated account.
        if (current != null &&
            readAccessTokenClaims(current)?['sub'] ==
                readAccessTokenClaims(previous)?['sub']) {
          await storage.write(
            key: 'refreshToken',
            value: tokens['refreshToken'] as String,
          );
          return current;
        }
        throw const ApiFailure('Session changed', 401);
      }
      if (!_sameSession(previous, access)) {
        throw const ApiFailure('Session organization changed', 401);
      }
      await saveTokens(tokens);
      return access;
    } catch (failure) {
      final unauthorized = switch (failure) {
        DioException(:final response) => response?.statusCode == 401,
        ApiFailure(:final status) => status == 401,
        _ => false,
      };
      if (unauthorized && await storage.read(key: 'accessToken') == previous) {
        await clearTokens();
        onSessionExpired?.call();
      }
      rethrow;
    }
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
      _request(
        () => dio.post<dynamic>(
          path,
          data: data,
          options: path.startsWith('/auth/otp/')
              ? Options(receiveTimeout: const Duration(seconds: 35))
              : null,
        ),
      );
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
      final code = body is Map ? (body['code'] ?? body['title']) : null;
      final bodyDelay = body is Map ? body['retryAfterSeconds'] : null;
      final seconds = bodyDelay is int
          ? bodyDelay
          : int.tryParse(e.response?.headers.value('retry-after') ?? '');
      throw ApiFailure(
        message ??
            (e.type == DioExceptionType.connectionError
                ? 'Connection unavailable. Check your network.'
                : 'Request failed. Please try again.'),
        e.response?.statusCode,
        code: code is String ? code : null,
        retryAfter: seconds != null && seconds > 0
            ? Duration(seconds: seconds)
            : null,
      );
    }
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(storageProvider),
    onSessionExpired: () =>
        ref.read(sessionRevisionProvider.notifier).increment(),
  ),
);
