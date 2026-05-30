import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/storage_provider.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  final storage = container.read(localAuthStorageProvider);
  
  container.read(authTokenProvider.notifier).state = storage.token;
  container.read(tenantIdProvider.notifier).state = storage.tenantId;
  container.read(userRoleProvider.notifier).state = storage.role;
  container.read(userFullNameProvider.notifier).state = storage.fullName;
  container.read(userEmailProvider.notifier).state = storage.email;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const IzinFlowApp(),
    ),
  );
}

class IzinFlowApp extends ConsumerWidget {
  const IzinFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'IzinFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(), // Default M3 Green & White branding
      routerConfig: router,
    );
  }
}
