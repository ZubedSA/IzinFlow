import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/widgets/custom_loading_indicator.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgSlugController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _orgSlugController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final dio = ref.read(apiClientProvider);
        final response = await dio.post(
          '/auth/login',
          data: {
            'email': _emailController.text,
            'password': _passwordController.text,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data;
          final token = data['accessToken'];
          final organization = data['organization'];
          final user = data['user'];

          // Save resolved sessions in StateProviders
          ref.read(authTokenProvider.notifier).state = token;
          ref.read(tenantIdProvider.notifier).state = organization['id'];
          ref.read(userFullNameProvider.notifier).state = user['fullName'];
          ref.read(userEmailProvider.notifier).state = user['email'];
          
          final role = user['role'] as String;
          ref.read(userRoleProvider.notifier).state = role;

          // Save to local storage for persistence
          await ref.read(localAuthStorageProvider).saveAuthData(
            token: token,
            tenantId: organization['id'],
            role: role,
            fullName: user['fullName'],
            email: user['email'],
          );

          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selamat datang, ${user['fullName']}!'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate dynamically based on role
            if (role == 'STUDENT') {
              context.go('/student/dashboard');
            } else if (role == 'TEACHER') {
              context.go('/teacher/dashboard');
            } else if (role == 'ORG_ADMIN') {
              context.go('/org-admin/dashboard');
            } else if (role == 'SUPER_ADMIN') {
              context.go('/super-admin/dashboard');
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          String errMsg = 'Koneksi gagal atau kredensial salah.';
          if (e is DioException && e.response != null) {
            errMsg = e.response?.data['message'] ?? errMsg;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showServerSettingsDialog() {
    final currentUrl = ref.read(serverUrlProvider);
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pengaturan Server API', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan URL base API backend Anda. Gunakan IP laptop jika diuji dari perangkat fisik.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL API',
                hintText: 'http://192.168.1.10:3000/api/v1',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ref.read(sharedPreferencesProvider).setString('serverUrl', newUrl);
                ref.read(serverUrlProvider.notifier).state = newUrl;
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server URL berhasil diubah ke: $newUrl'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: isDesktop ? 450 : size.width * 0.9,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  shadowColor: Colors.black26,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Branding Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.vpn_key_rounded,
                              size: 40,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'IZINFLOW',
                            style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Satu Platform, Banyak Lembaga',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Organization Slug Input
                          TextFormField(
                            controller: _orgSlugController,
                            decoration: const InputDecoration(
                              labelText: 'Kode / Slug Organisasi',
                              prefixIcon: Icon(Icons.business_rounded),
                              hintText: 'contoh: sman1-jakarta',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kode organisasi wajib diisi.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Pengguna',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email wajib diisi.';
                              }
                              if (!value.contains('@')) {
                                return 'Format email tidak valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi.';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Action Button
                          _isLoading
                              ? const CustomLoadingIndicator()
                              : ElevatedButton(
                                  onPressed: _handleLogin,
                                  child: const Text('Masuk Ke Platform'),
                                ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              // Trigger dynamic organization register page
                            },
                            child: Text(
                              'Daftarkan Lembaga Baru',
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.grey),
              onPressed: _showServerSettingsDialog,
            ),
          ),
        ],
      ),
    );
  }
}
