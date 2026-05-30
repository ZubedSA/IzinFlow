import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/widgets/custom_loading_indicator.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  bool _isLoading = false;
  Map<String, dynamic> _stats = {
    'totalOrganizations': 0,
    'totalUsers': 0,
    'totalLettersGenerated': 0,
    'totalPendingRequests': 0,
    'totalApprovedRequests': 0,
    'organizations': [],
  };
  String? _errorMessage;
  int _currentTabIndex = 0;

  // Form State: Add Organization
  final _orgFormKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _orgSlugController = TextEditingController();
  final _orgAddressController = TextEditingController();
  final _orgContactController = TextEditingController();
  final _orgAdminNameController = TextEditingController();
  final _orgAdminEmailController = TextEditingController();
  final _orgAdminPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchGlobalData());
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _orgSlugController.dispose();
    _orgAddressController.dispose();
    _orgContactController.dispose();
    _orgAdminNameController.dispose();
    _orgAdminEmailController.dispose();
    _orgAdminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchGlobalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/permissions/global-stats');

      if (mounted) {
        setState(() {
          _stats = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat analitik platform global. Pastikan server aktif!';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitOrg() async {
    if (_orgFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final payload = {
        'orgName': _orgNameController.text,
        'orgSlug': _orgSlugController.text.toLowerCase().trim(),
        'orgAddress': _orgAddressController.text,
        'orgContact': _orgContactController.text,
        'adminFullName': _orgAdminNameController.text,
        'adminEmail': _orgAdminEmailController.text.trim(),
        'adminPassword': _orgAdminPasswordController.text,
      };

      try {
        final dio = ref.read(apiClientProvider);
        final response = await dio.post(
          '/auth/register-organization',
          data: payload,
        );

        if (mounted) {
          _orgNameController.clear();
          _orgSlugController.clear();
          _orgAddressController.clear();
          _orgContactController.clear();
          _orgAdminNameController.clear();
          _orgAdminEmailController.clear();
          _orgAdminPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Organisasi berhasil terdaftar!'),
              backgroundColor: Colors.green,
            ),
          );
          
          setState(() {
            _currentTabIndex = 2; // Switch to Directory list
          });
          _fetchGlobalData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          String errMsg = 'Gagal mendaftarkan organisasi baru.';
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

  Future<void> _deleteOrganization(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menonaktifkan/menghapus organisasi ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Hapus')
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(apiClientProvider).delete('/auth/organizations/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Organisasi berhasil dihapus'), backgroundColor: Colors.green));
        _fetchGlobalData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus organisasi'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    ref.read(authTokenProvider.notifier).state = null;
    ref.read(tenantIdProvider.notifier).state = null;
    ref.read(userRoleProvider.notifier).state = null;
    await ref.read(localAuthStorageProvider).clearAuthData();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);

    // List of tab panels mapped to views
    final List<Widget> views = [
      _buildSaaSOverviewTab(isDesktop, theme),
      _buildAddOrgTab(isDesktop, theme),
      _buildOrgsListTab(isDesktop, theme),
    ];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: NavigationRail(
                    selectedIndex: _currentTabIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _currentTabIndex = index;
                      });
                    },
                    backgroundColor: Colors.transparent,
                    extended: true,
                    minExtendedWidth: 240,
                    indicatorColor: theme.colorScheme.primaryContainer,
                    useIndicator: true,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: theme.colorScheme.primary, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            'SaaS Control',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.show_chart_rounded),
                        label: Text('SaaS Overview', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.add_business_rounded),
                        label: Text('Daftarkan Baru', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.domain_rounded),
                        label: Text('Daftar Sekolah', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.red),
                            onPressed: _handleLogout,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: views[_currentTabIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _currentTabIndex == 0 
                ? 'SaaS Super Admin' 
                : (_currentTabIndex == 1 ? 'Registrasi Lembaga Baru' : 'Daftar Lembaga Aktif')
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : _fetchGlobalData,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: views[_currentTabIndex],
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          items: [
            CustomNavBarItem(icon: Icons.show_chart_rounded, label: 'Overview'),
            CustomNavBarItem(icon: Icons.add_business_rounded, label: 'Daftarkan'),
            CustomNavBarItem(icon: Icons.domain_rounded, label: 'Daftar Sekolah'),
          ],
        ),
      );
    }
  }

  // --- SAAS TAB PANEL WIDGETS ---

  Widget _buildSaaSOverviewTab(bool isDesktop, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SaaS Global Overview', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('Analitik multitenant, integrasi sekolah, dan live monitoring status SaaS.', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _isLoading ? null : _fetchGlobalData,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          Card(
            color: Colors.blue.shade900,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.analytics_outlined, color: theme.colorScheme.onPrimary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'SaaS Control Panel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelola seluruh infrastruktur sekolah, integrasi multi-tenant, dan analitik performa.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Platform Global Stats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          LayoutBuilder(
            builder: (context, constraints) {
              final int crossAxisCount = isDesktop ? 3 : 2;
              final double cardWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: cardWidth, child: _buildGlobalStatCard('Sekolah', _stats['totalOrganizations'].toString(), Colors.blue, Icons.school_rounded, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildGlobalStatCard('Pengguna', _stats['totalUsers'].toString(), Colors.teal, Icons.people_rounded, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildGlobalStatCard('Surat Terbit', _stats['totalLettersGenerated'].toString(), Colors.purple, Icons.picture_as_pdf_rounded, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildGlobalStatCard('Pending', _stats['totalPendingRequests'].toString(), Colors.orange, Icons.timelapse_rounded, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildGlobalStatCard('Disetujui', _stats['totalApprovedRequests'].toString(), Colors.green, Icons.check_circle_rounded, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildGlobalStatCard('Sistem', 'ONLINE', Colors.green.shade700, Icons.circle_rounded, isDesktop)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddOrgTab(bool isDesktop, ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop) ...[
              Text('Daftarkan Lembaga / Sekolah Baru', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              Text('Sediakan akses multitenant terisolasi baru beserta kredensial Admin Sekolah', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
            ],

            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _orgFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informasi Sekolah', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orgNameController,
                        decoration: const InputDecoration(labelText: 'Nama Instansi/Sekolah'),
                        validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _orgSlugController,
                        decoration: const InputDecoration(labelText: 'Slug Organisasi (Domain)', hintText: 'misal: sman1-jkt'),
                        validator: (v) => v == null || v.isEmpty ? 'Slug wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _orgAddressController,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _orgContactController,
                        decoration: const InputDecoration(labelText: 'Kontak Telepon'),
                      ),
                      const Divider(height: 40),
                      Text('Akun Administrator Utama Sekolah', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orgAdminNameController,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap Admin'),
                        validator: (v) => v == null || v.isEmpty ? 'Nama Admin wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _orgAdminEmailController,
                        decoration: const InputDecoration(labelText: 'Email Admin'),
                        validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _orgAdminPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password Admin'),
                        validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                      ),
                      const SizedBox(height: 28),
                      _isLoading 
                          ? const CustomLoadingIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 54),
                              ),
                              onPressed: _submitOrg,
                              child: const Text('Daftarkan Lembaga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgsListTab(bool isDesktop, ThemeData theme) {
    final organizations = _stats['organizations'] as List<dynamic>? ?? [];

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            Text('Sekolah Terdaftar', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text('Daftar direktori seluruh sekolah / instansi aktif dalam database IzinFlow SaaS', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
          ],

          if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchGlobalData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          else if (organizations.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Belum ada sekolah terdaftar di sistem.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: organizations.length,
                itemBuilder: (context, index) {
                  final org = organizations[index];
                  final name = org['name'] ?? 'Instansi';
                  final slug = org['slug'] ?? 'slug';
                  final address = org['address'] ?? 'Alamat tidak diisi';
                  final isActive = org['isActive'] ?? true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.domain_rounded, color: theme.colorScheme.primary),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Slug/Domain: $slug.izinflow.com', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(address, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActive ? 'AKTIF' : 'NON-AKTIF',
                              style: TextStyle(
                                color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                            onPressed: () => _deleteOrganization(org['id']),
                            tooltip: 'Hapus Organisasi',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatCard(String title, String count, Color color, IconData icon, bool isDesktop) {
    if (!isDesktop) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
