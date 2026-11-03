import 'dart:io';

import 'package:dio/dio.dart';

Never _fail(String message) {
  stderr.writeln('Staging contract failed: $message');
  exit(1);
}

Future<void> main() async {
  final baseUrl = Platform.environment['API_BASE_URL'];
  final email = Platform.environment['PGINFO_TEST_EMAIL'];
  final password = Platform.environment['PGINFO_TEST_PASSWORD'];
  if ([
    baseUrl,
    email,
    password,
  ].any((value) => value == null || value.isEmpty)) {
    _fail('API_BASE_URL and disposable test credentials are required');
  }
  if (Uri.tryParse(baseUrl!)?.scheme != 'https') {
    _fail('staging API must use HTTPS');
  }

  final client = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final login = await client.post<Map<String, dynamic>>(
    '/auth/login',
    data: {'email': email, 'password': password},
  );
  final body = login.data ?? _fail('empty login response');
  final tokens = body['tokens'] as Map<String, dynamic>?;
  final user = body['user'] as Map<String, dynamic>?;
  final token = tokens?['accessToken'] as String?;
  final orgId = user?['activeOrganizationId'] as String?;
  if (token == null || orgId == null) _fail('invalid authentication contract');

  final options = Options(
    headers: {'Authorization': 'Bearer $token', 'X-Organization-Id': orgId},
  );
  final properties = await client.get<dynamic>('/properties', options: options);
  final payload = properties.data;
  final list = payload is Map ? payload['data'] as List? : payload as List?;
  if (list == null) _fail('invalid properties contract');
  final propertyId = list.isEmpty
      ? null
      : (list.first as Map<String, dynamic>)['id'] as String?;
  final metrics = await client.get<Map<String, dynamic>>(
    '/dashboard/metrics',
    queryParameters: {'propertyId': ?propertyId},
    options: options,
  );
  if (metrics.data?['operational'] is! Map ||
      metrics.data?['financial'] is! Map) {
    _fail('invalid dashboard contract');
  }
  stdout.writeln(
    'Staging authentication, property, and dashboard contracts passed.',
  );
}
