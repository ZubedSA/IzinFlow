import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/widgets/custom_loading_indicator.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  bool _isLoading = false;
  List<dynamic> _permissions = [];
  String? _errorMessage;
  int _currentTabIndex = 0;

  // Form State for Leave Application
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String _selectedType = 'SICK';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchPermissions());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
          _errorMessage = 'Gagal memuat riwayat pengajuan izin. Pastikan server aktif!';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPDF(String permissionId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyiapkan dan mengunduh berkas PDF...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get(
        '/letters/$permissionId/download',
        options: Options(responseType: ResponseType.bytes),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Surat Izin PDF (ID: $permissionId) berhasil diunduh (${response.data.length} bytes)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunduh berkas PDF.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final dio = ref.read(apiClientProvider);
        final response = await dio.post(
          '/permissions',
          data: {
            'type': _selectedType,
            'startDate': _startDate.toUtc().toIso8601String(),
            'endDate': _endDate.toUtc().toIso8601String(),
            'reason': _reasonController.text,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _currentTabIndex = 0; // Switch back to history view
              _selectedType = 'SICK';
              _startDate = DateTime.now();
              _endDate = DateTime.now();
              _reasonController.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.data['message'] ?? 'Pengajuan izin berhasil dikirim!'),
                backgroundColor: Colors.green,
              ),
            );
            _fetchPermissions(); // Reload history
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          String errMsg = 'Gagal mengirim pengajuan izin.';
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

  Future<void> _handleLogout() async {
    ref.read(authTokenProvider.notifier).state = null;
    ref.read(tenantIdProvider.notifier).state = null;
    ref.read(userRoleProvider.notifier).state = null;
    ref.read(userFullNameProvider.notifier).state = null;
    ref.read(userEmailProvider.notifier).state = null;
    await ref.read(localAuthStorageProvider).clearAuthData();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);

    // List of View widgets corresponding to active tab
    final List<Widget> views = [
      _buildHistoryView(isDesktop, theme),
      _buildApplyFormView(isDesktop, theme),
    ];

    if (isDesktop) {
      // Desktop Sidebar Layout
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
                          Icon(Icons.eco_rounded, color: theme.colorScheme.primary, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            'IzinFlow',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.history_rounded),
                        selectedIcon: Icon(Icons.history_rounded),
                        label: Text('Riwayat Izin', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.file_copy_outlined),
                        selectedIcon: Icon(Icons.file_copy_rounded),
                        label: Text('Ajukan Surat Izin', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
                          child: _buildDesktopProfileCard(theme),
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
      // Mobile Layout with Bottom Navbar
      return Scaffold(
        appBar: AppBar(
          title: Text(_currentTabIndex == 0 ? 'IzinFlow Siswa' : 'Ajukan Surat Izin'),
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
            CustomNavBarItem(
              icon: Icons.history_rounded,
              label: 'Riwayat',
            ),
            CustomNavBarItem(
              icon: Icons.file_copy_rounded,
              label: 'Ajukan Izin',
            ),
          ],
        ),
      );
    }
  }

  // --- COMPONENT VIEWS ---

  Widget _buildHistoryView(bool isDesktop, ThemeData theme) {
    final fullName = ref.watch(userFullNameProvider) ?? 'Siswa IzinFlow';
    final email = ref.watch(userEmailProvider) ?? 'student@izinflow.com';
    final initials = fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

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
                    Text('Riwayat Izin Siswa', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('Kelola pengajuan surat izin dan unduh bukti resmi PDF', style: TextStyle(color: Colors.grey.shade600)),
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

          // Profile card banner (Mobile-focused but neat on Desktop)
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
                      initials.isNotEmpty ? initials : 'S',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
            'Daftar Pengajuan Surat Izin',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isLoading && _permissions.isEmpty)
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
                  'Belum ada pengajuan surat izin.',
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
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: Icon(
                          type == 'SICK' ? Icons.sick_outlined : Icons.event_note_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          'Izin $type • ${startDate.toString().split(' ')[0]}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alasan Ketidakhadiran:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(reason),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sampai dengan: ${endDate.toString().split(' ')[0]}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (status == 'APPROVED')
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(100, 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        icon: const Icon(Icons.download_rounded, size: 16),
                                        label: const Text('Unduh PDF', style: TextStyle(fontSize: 12)),
                                        onPressed: () => _downloadPDF(permit['id']),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildApplyFormView(bool isDesktop, ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop) ...[
              Text('Ajukan Surat Izin Baru', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              Text('Kirim formulir permohonan surat izin belajar resmi sekolah', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formulir Ketidakhadiran Siswa',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Select Permission Type
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Izin',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'SICK', child: Text('Sakit (SICK)')),
                          DropdownMenuItem(value: 'FAMILY', child: Text('Keperluan Keluarga (FAMILY)')),
                          DropdownMenuItem(value: 'EVENT', child: Text('Kegiatan / Acara (EVENT)')),
                          DropdownMenuItem(value: 'LATE', child: Text('Terlambat Datang (LATE)')),
                          DropdownMenuItem(value: 'LEAVE_EARLY', child: Text('Pulang Awal (LEAVE_EARLY)')),
                          DropdownMenuItem(value: 'OTHER', child: Text('Lainnya (OTHER)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Start Date Picker
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        tileColor: Colors.grey.shade50,
                        leading: const Icon(Icons.date_range_rounded),
                        title: const Text('Tanggal Mulai'),
                        subtitle: Text('${_startDate.toLocal()}'.split(' ')[0]),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                              if (_endDate.isBefore(_startDate)) {
                                _endDate = _startDate;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // End Date Picker
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        tileColor: Colors.grey.shade50,
                        leading: const Icon(Icons.date_range_rounded),
                        title: const Text('Tanggal Selesai'),
                        subtitle: Text('${_endDate.toLocal()}'.split(' ')[0]),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Reason input area
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Alasan Izin / Keterangan Lengkap',
                          hintText: 'Berikan deskripsi detail alasan ketidakhadiran...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alasan izin wajib diisi.';
                          }
                          if (value.length < 10) {
                            return 'Berikan penjelasan minimal 10 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Form Submit Button
                      _isSubmitting
                          ? const CustomLoadingIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 54),
                              ),
                              onPressed: _submitForm,
                              child: const Text('Kirim Pengajuan Surat Izin', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildDesktopProfileCard(ThemeData theme) {
    final fullName = ref.watch(userFullNameProvider) ?? 'Siswa IzinFlow';
    final email = ref.watch(userEmailProvider) ?? 'student@izinflow.com';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout_rounded, size: 14, color: Colors.red),
                  SizedBox(width: 6),
                  Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
