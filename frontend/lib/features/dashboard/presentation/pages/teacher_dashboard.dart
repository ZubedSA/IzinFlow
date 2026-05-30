import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/widgets/custom_loading_indicator.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  bool _isLoading = false;
  List<dynamic> _permissions = [];
  String? _errorMessage;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchPermissions());
  }

  Future<void> _fetchPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/permissions');

      if (mounted) {
        setState(() {
          _permissions = response.data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data pengajuan izin. Pastikan server aktif!';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAction(String id, String action, String note) async {
    setState(() => _isLoading = true);

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/permissions/$id/$action',
        data: {'note': note},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Aksi berhasil diproses!'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
        _fetchPermissions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memproses pengajuan izin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNoteDialog(String id, String action) {
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            action == 'approve' ? 'Setujui Pengajuan Izin' : 'Tolak Pengajuan Izin',
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.9,
              child: TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan / Alasan',
                  hintText: action == 'approve' ? 'Berikan catatan (opsional)...' : 'Berikan alasan penolakan (wajib)...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (action == 'reject' && (value == null || value.trim().isEmpty)) {
                    return 'Alasan penolakan wajib diisi.';
                  }
                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  _handleAction(id, action, noteController.text);
                }
              },
              child: Text(action == 'approve' ? 'Setujui' : 'Tolak'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
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

    // Views Mapping
    final List<Widget> views = [
      _buildPermissionsTab(isDesktop, theme),
      _buildProfileTab(isDesktop, theme),
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
                    minExtendedWidth: 260,
                    indicatorColor: theme.colorScheme.primaryContainer,
                    useIndicator: true,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.assignment_ind_rounded, color: theme.colorScheme.primary, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            'Guru Portal',
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
                        icon: Icon(Icons.rate_review_rounded),
                        label: Text('Persetujuan Siswa', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.account_box_rounded),
                        label: Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.w600)),
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
          title: Text(_currentTabIndex == 0 ? 'Surat Izin Siswa' : 'Profil Guru'),
          actions: [
            if (_currentTabIndex == 0)
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _isLoading ? null : _fetchPermissions,
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
            CustomNavBarItem(icon: Icons.rate_review_rounded, label: 'Persetujuan'),
            CustomNavBarItem(icon: Icons.account_box_rounded, label: 'Profil'),
          ],
        ),
      );
    }
  }

  // --- TEACHER TAB PANEL WIDGETS ---

  Widget _buildPermissionsTab(bool isDesktop, ThemeData theme) {
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
                    Text('Persetujuan Surat Izin Siswa', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('Tinjau, setujui, atau tolak surat pengajuan izin siswa yang ada di bawah perwalian Anda.', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _isLoading ? null : _fetchPermissions,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wali Kelas Portal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tinjau dan proses surat izin belajar siswa kelas Anda dengan cepat dan mudah.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Daftar Pengajuan Izin Siswa',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Expanded(child: CustomLoadingIndicator())
          else if (_errorMessage != null)
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
                      onPressed: _fetchPermissions,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          else if (_permissions.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Tidak ada pengajuan surat izin kelas saat ini.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPermissions,
                child: ListView.builder(
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final permit = _permissions[index];
                    final student = permit['student'];
                    final user = student != null ? student['user'] : null;
                    final classRoom = student != null ? student['classRoom'] : null;
                    final studentName = user != null ? user['fullName'] : 'Siswa';
                    final className = classRoom != null ? classRoom['name'] : '-';
                    final status = permit['status'];
                    final type = permit['type'];
                    final reason = permit['reason'];
                    final startDate = DateTime.parse(permit['startDate']).toLocal();
                    final endDate = DateTime.parse(permit['endDate']).toLocal();

                    Color statusColor;
                    IconData statusIcon;

                    switch (status) {
                      case 'APPROVED':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle_outline_rounded;
                        break;
                      case 'PENDING':
                        statusColor = Colors.orange;
                        statusIcon = Icons.timelapse_rounded;
                        break;
                      default:
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel_outlined;
                    }

                    return Card(
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: type == 'SICK' ? Colors.blue.shade50 : Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              type == 'SICK' ? Icons.sick_outlined : Icons.event_note_rounded,
                              color: type == 'SICK' ? Colors.blue : Colors.purple,
                            ),
                          ),
                          title: Text(
                            '$studentName ($className)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, color: statusColor, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Izin $type',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.notes_rounded, size: 20, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Alasan Ketidakhadiran:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(reason, style: const TextStyle(height: 1.5)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tanggal: ${startDate.toString().split(' ')[0]} s/d ${endDate.toString().split(' ')[0]}',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (status == 'PENDING') ...[
                                    const SizedBox(height: 20),
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onPressed: () => _showNoteDialog(permit['id'], 'reject'),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.check_rounded, size: 18),
                                          label: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onPressed: () => _showNoteDialog(permit['id'], 'approve'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(bool isDesktop, ThemeData theme) {
    final fullName = ref.watch(userFullNameProvider) ?? 'Wali Kelas';
    final email = ref.watch(userEmailProvider) ?? 'teacher@sekolah.sch.id';
    final initials = fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

    // Custom quick statistics for teachers
    final totalPending = _permissions.where((p) => p['status'] == 'PENDING').length;
    final totalApproved = _permissions.where((p) => p['status'] == 'APPROVED').length;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            Text('Profil & Statistik Guru', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text('Kredensial dan ringkasan kerja perwalian kelas', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
          ],

          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(email, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge_outlined, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            const Text(
                              'Wali Kelas / Homeroom Teacher',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Ringkasan Perwalian Kelas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.timelapse_rounded, color: Colors.orange, size: 24),
                      ),
                      const SizedBox(height: 16),
                      Text(totalPending.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange)),
                      const SizedBox(height: 4),
                      const Text('Izin Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
                      ),
                      const SizedBox(height: 16),
                      Text(totalApproved.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 4),
                      const Text('Izin Disetujui', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _handleLogout,
          ),
        ],
      ),
    );
  }
}
