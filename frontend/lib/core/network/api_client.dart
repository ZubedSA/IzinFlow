import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/storage_provider.dart';

// Providers for tracking JWT active session and Tenant Context
final tenantIdProvider = StateProvider<String?>((ref) => null);
final authTokenProvider = StateProvider<String?>((ref) => null);
final userFullNameProvider = StateProvider<String?>((ref) => null);
final userEmailProvider = StateProvider<String?>((ref) => null);

final serverUrlProvider = StateProvider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('serverUrl') ?? 'http://localhost:3000/api/v1';
});

final apiClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(serverUrlProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // 1. Retrieve organization ID and inject as multi-tenant scope header
        final tenantId = ref.read(tenantIdProvider);
        if (tenantId != null) {
          options.headers['X-Organization-Id'] = tenantId;
        }

        // 2. Retrieve JWT authorization token
        final token = ref.read(authTokenProvider);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Centralized Network Error Mapping
        return handler.next(e);
      },
    ),
  );

  return dio;
});
