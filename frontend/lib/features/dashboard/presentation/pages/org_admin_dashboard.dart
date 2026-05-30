import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/widgets/custom_loading_indicator.dart';

class OrgAdminDashboard extends ConsumerStatefulWidget {
  const OrgAdminDashboard({super.key});

  @override
  ConsumerState<OrgAdminDashboard> createState() => _OrgAdminDashboardState();
}

class _OrgAdminDashboardState extends ConsumerState<OrgAdminDashboard> {
  bool _isLoading = false;
  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'totalTeachers': 0,
    'pendingCount': 0,
    'approvedCount': 0,
    'rejectedCount': 0,
  };
  List<dynamic> _permissions = [];
  String? _errorMessage;
  int _currentTabIndex = 0;

  // Toggle states for creation forms (hidden by default)
  bool _showClassForm = false;
  bool _showTeacherForm = false;
  bool _showStudentForm = false;

  // Directory Data
  List<dynamic> _classrooms = [];
  List<dynamic> _teachers = [];
  List<dynamic> _students = [];
  bool _isDirLoading = false;

  // Permissions Data (Aktivitas)
  bool _isPermissionsLoading = false;
  List<dynamic> _pendingPermissions = [];
  List<dynamic> _historyPermissions = [];

  // Form State: Add Classroom
  final _classFormKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();

  // Form State: Add Teacher
  final _teacherFormKey = GlobalKey<FormState>();
  final _teacherNameController = TextEditingController();
  final _teacherNipController = TextEditingController();
  final _teacherEmailController = TextEditingController();
  final _teacherPasswordController = TextEditingController();
  String? _teacherSelectedClassroomId;

  // Form State: Add Student
  final _studentFormKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _studentNisnController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _studentPasswordController = TextEditingController();
  String? _studentSelectedClassroomId;

  // Form State: Org PDF Settings
  bool _showPdfSettingsForm = false;
  final _pdfSettingsFormKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _orgLogoUrlController = TextEditingController();
  final _orgAddressController = TextEditingController();
  final _orgContactController = TextEditingController();
  final _orgTemplateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchData();
      _fetchDirectoryData();
      _fetchPermissions();
    });
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _teacherNameController.dispose();
    _teacherNipController.dispose();
    _teacherEmailController.dispose();
    _teacherPasswordController.dispose();
    _studentNameController.dispose();
    _studentNisnController.dispose();
    _studentEmailController.dispose();
    _studentPasswordController.dispose();

    _orgNameController.dispose();
    _orgLogoUrlController.dispose();
    _orgAddressController.dispose();
    _orgContactController.dispose();
    _orgTemplateController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      
      // 1. Fetch Organization Stats
      final statsResponse = await dio.get('/permissions/org-stats');
      
      // 2. Fetch All Permissions in the Organization
      final permissionsResponse = await dio.get('/permissions');

      // 3. Fetch Organization Settings
      final settingsResponse = await dio.get('/organizations/settings');

      if (mounted) {
        setState(() {
          _stats = statsResponse.data as Map<String, dynamic>;
          _permissions = permissionsResponse.data as List<dynamic>;

          final orgData = settingsResponse.data['organization'];
          final templateData = settingsResponse.data['template'];
          if (orgData != null) {
            _orgNameController.text = orgData['name'] ?? '';
            _orgLogoUrlController.text = orgData['logoUrl'] ?? '';
            _orgAddressController.text = orgData['address'] ?? '';
            _orgContactController.text = orgData['contact'] ?? '';
          }
          if (templateData != null) {
            _orgTemplateController.text = templateData['contentHtml'] ?? '';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data dashboard. Pastikan server aktif!';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDirectoryData() async {
    setState(() => _isDirLoading = true);
    try {
      final dio = ref.read(apiClientProvider);
      
      final classResponse = await dio.get('/auth/classrooms');
      final teacherResponse = await dio.get('/auth/teachers');
      final studentResponse = await dio.get('/auth/students');
      
      if (mounted) {
        setState(() {
          _classrooms = classResponse.data as List<dynamic>;
          _teachers = teacherResponse.data as List<dynamic>;
          _students = studentResponse.data as List<dynamic>;
          _isDirLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDirLoading = false);
    }
  }

  Future<void> _fetchPermissions() async {
    setState(() => _isPermissionsLoading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/permissions');
      if (response.statusCode == 200) {
        final List<dynamic> perms = response.data;
        setState(() {
          _pendingPermissions = perms.where((p) => p['status'] == 'PENDING').toList();
          _historyPermissions = perms.where((p) => p['status'] != 'PENDING').toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memuat daftar izin'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPermissionsLoading = false);
    }
  }

  Future<void> _processPermission(String permissionId, String action, String note) async {
    setState(() => _isPermissionsLoading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/permissions/$permissionId/$action',
        data: {'note': note},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Berhasil memproses izin'), backgroundColor: Colors.green),
          );
          _fetchPermissions();
          _fetchData(); // update overview stats
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses pengajuan izin'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPermissionsLoading = false);
    }
  }

  void _showNoteDialog(String permissionId, String action) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action == 'approve' ? 'Setujui Izin' : 'Tolak Izin'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Catatan Tambahan (Opsional)',
            hintText: 'Misal: Semoga lekas sembuh...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _processPermission(permissionId, action, noteController.text);
            },
            child: Text(action == 'approve' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
  }
  // --- PDF Management Operations ---
  int get _bottomNavIndex {
    if (_currentTabIndex == 0) return 0;
    if (_currentTabIndex >= 1 && _currentTabIndex <= 2) return 1;
    if (_currentTabIndex >= 3 && _currentTabIndex <= 5) return 2;
    if (_currentTabIndex >= 6 && _currentTabIndex <= 8) return 3;
    return 0;
  }

  // --- SUBMIT OPERATIONS ---

  Future<void> _submitClassroom() async {
    if (_classFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final dio = ref.read(apiClientProvider);
        await dio.post('/auth/classrooms', data: {
          'name': _classNameController.text,
        });
        
        if (mounted) {
          setState(() {
            _classNameController.clear();
            _showClassForm = false; // Auto collapse form!
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kelas baru berhasil dibuat!'), backgroundColor: Colors.green),
          );
          _fetchData();
          _fetchDirectoryData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuat kelas baru.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _submitTeacher() async {
    if (_teacherFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final dio = ref.read(apiClientProvider);
        await dio.post('/auth/teachers', data: {
          'fullName': _teacherNameController.text,
          'employeeNumber': _teacherNipController.text,
          'email': _teacherEmailController.text,
          'password': _teacherPasswordController.text,
          'classRoomId': _teacherSelectedClassroomId,
        });

        if (mounted) {
          setState(() {
            _teacherNameController.clear();
            _teacherNipController.clear();
            _teacherEmailController.clear();
            _teacherPasswordController.clear();
            _teacherSelectedClassroomId = null;
            _showTeacherForm = false; // Auto collapse form!
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun Guru berhasil didaftarkan!'), backgroundColor: Colors.green),
          );
          _fetchData();
          _fetchDirectoryData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mendaftarkan guru baru.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _submitStudent() async {
    if (_studentFormKey.currentState!.validate()) {
      if (_studentSelectedClassroomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih kelas terlebih dahulu!'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final dio = ref.read(apiClientProvider);
        await dio.post('/auth/students', data: {
          'fullName': _studentNameController.text,
          'studentIdNumber': _studentNisnController.text,
          'email': _studentEmailController.text,
          'password': _studentPasswordController.text,
          'classRoomId': _studentSelectedClassroomId,
        });

        if (mounted) {
          setState(() {
            _studentNameController.clear();
            _studentNisnController.clear();
            _studentEmailController.clear();
            _studentPasswordController.clear();
            _studentSelectedClassroomId = null;
            _showStudentForm = false; // Auto collapse form!
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun Siswa berhasil didaftarkan!'), backgroundColor: Colors.green),
          );
          _fetchData();
          _fetchDirectoryData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mendaftarkan siswa baru.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _submitOrgSettings() async {
    if (_pdfSettingsFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final dio = ref.read(apiClientProvider);
        await dio.put('/organizations/settings', data: {
          'name': _orgNameController.text,
          'logoUrl': _orgLogoUrlController.text,
          'address': _orgAddressController.text,
          'contact': _orgContactController.text,
          'templateContentHtml': _orgTemplateController.text,
        });

        if (mounted) {
          setState(() {
            _showPdfSettingsForm = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengaturan berhasil disimpan!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan pengaturan.'), backgroundColor: Colors.red),
          );
        }
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

  Future<void> _previewSettingsPDF() async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/organizations/settings/preview',
        data: {
          'name': _orgNameController.text,
          'logoUrl': _orgLogoUrlController.text,
          'address': _orgAddressController.text,
          'contact': _orgContactController.text,
          'templateContentHtml': _orgTemplateController.text,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      // In Flutter Web this could create a blob URL, but for native/general we can just save it or show it.
      // Since it's web, we can use dart:html, but we don't have it imported.
      // So instead, we'll inform the user that it downloaded or we could launch it.
      // Wait, without dart:html, we can't easily preview it instantly on Web from bytes.
      // Let's just download it as a byte preview or show a message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fungsionalitas Preview PDF memerlukan akses file (bytes diunduh).'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat pratinjau template.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _previewPDF(String permissionId) async {
    final url = Uri.parse('http://localhost:3000/api/v1/letters/$permissionId/download');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka pratinjau PDF.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- CRUD Actions ---

  Future<void> _deleteClassroom(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus kelas ini?'),
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
      await ref.read(apiClientProvider).delete('/auth/classrooms/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas dihapus'), backgroundColor: Colors.green));
        _fetchDirectoryData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus kelas'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTeacher(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus data guru ini?'),
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
      await ref.read(apiClientProvider).delete('/auth/teachers/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guru dihapus'), backgroundColor: Colors.green));
        _fetchDirectoryData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus guru'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStudent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus data siswa ini?'),
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
      await ref.read(apiClientProvider).delete('/auth/students/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siswa dihapus'), backgroundColor: Colors.green));
        _fetchDirectoryData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus siswa'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditClassDialog(dynamic c) {
    final txtCtrl = TextEditingController(text: c['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Kelas'),
        content: TextFormField(
          controller: txtCtrl,
          decoration: const InputDecoration(labelText: 'Nama Kelas', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await ref.read(apiClientProvider).put('/auth/classrooms/${c['id']}', data: {'name': txtCtrl.text});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas diperbarui'), backgroundColor: Colors.green));
                  _fetchDirectoryData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui kelas'), backgroundColor: Colors.red));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }, 
            child: const Text('Simpan')
          ),
        ],
      ),
    );
  }

  void _showEditTeacherDialog(dynamic t) {
    final nameCtrl = TextEditingController(text: t['user']['fullName']);
    final nipCtrl = TextEditingController(text: t['employeeNumber']);
    final emailCtrl = TextEditingController(text: t['user']['email']);
    String? classId = _classrooms.isNotEmpty ? _classrooms.first['id'] : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Guru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
              TextFormField(controller: nipCtrl, decoration: const InputDecoration(labelText: 'NIP')),
              TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await ref.read(apiClientProvider).put('/auth/teachers/${t['id']}', data: {
                  'fullName': nameCtrl.text,
                  'employeeNumber': nipCtrl.text,
                  'email': emailCtrl.text,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guru diperbarui'), backgroundColor: Colors.green));
                  _fetchDirectoryData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui guru'), backgroundColor: Colors.red));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }, 
            child: const Text('Simpan')
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(dynamic s) {
    final nameCtrl = TextEditingController(text: s['user']['fullName']);
    final nisnCtrl = TextEditingController(text: s['studentIdNumber']);
    final emailCtrl = TextEditingController(text: s['user']['email']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Siswa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
              TextFormField(controller: nisnCtrl, decoration: const InputDecoration(labelText: 'NISN')),
              TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await ref.read(apiClientProvider).put('/auth/students/${s['id']}', data: {
                  'fullName': nameCtrl.text,
                  'studentIdNumber': nisnCtrl.text,
                  'email': emailCtrl.text,
                  'classRoomId': s['classRoomId'],
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siswa diperbarui'), backgroundColor: Colors.green));
                  _fetchDirectoryData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui siswa'), backgroundColor: Colors.red));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }, 
            child: const Text('Simpan')
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab(bool isDesktop, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengajuan Izin Masuk', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text('Tinjau dan setujui izin siswa yang menunggu keputusan.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          if (_isPermissionsLoading)
            const Expanded(child: CustomLoadingIndicator())
          else if (_pendingPermissions.isEmpty)
            const Expanded(child: Center(child: Text('Tidak ada pengajuan izin tertunda saat ini.', style: TextStyle(color: Colors.grey))))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPermissions,
                child: ListView.builder(
                  itemCount: _pendingPermissions.length,
                  itemBuilder: (context, index) {
                    final permit = _pendingPermissions[index];
                    final student = permit['student'];
                    final user = student != null ? student['user'] : null;
                    final classRoom = student != null ? student['classRoom'] : null;
                    final studentName = user != null ? user['fullName'] : 'Siswa';
                    final className = classRoom != null ? classRoom['name'] : '-';
                    final type = permit['type'];
                    final reason = permit['reason'];
                    final startDate = DateTime.parse(permit['startDate']).toLocal();
                    final endDate = DateTime.parse(permit['endDate']).toLocal();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.timelapse_rounded, color: Colors.orange),
                          ),
                          title: Text('$studentName ($className)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Izin $type', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Alasan: $reason'),
                                  const SizedBox(height: 8),
                                  Text('Tanggal: ${startDate.toString().split(' ')[0]} s/d ${endDate.toString().split(' ')[0]}'),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        label: const Text('Tolak'),
                                        onPressed: () => _showNoteDialog(permit['id'], 'reject'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check_rounded, size: 18),
                                        label: const Text('Setujui'),
                                        onPressed: () => _showNoteDialog(permit['id'], 'approve'),
                                      ),
                                    ],
                                  ),
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

  Widget _buildHistoryTab(bool isDesktop, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riwayat Izin', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text('Daftar pengajuan izin yang telah disetujui atau ditolak.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          if (_isPermissionsLoading)
            const Expanded(child: CustomLoadingIndicator())
          else if (_historyPermissions.isEmpty)
            const Expanded(child: Center(child: Text('Belum ada riwayat izin.', style: TextStyle(color: Colors.grey))))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPermissions,
                child: ListView.builder(
                  itemCount: _historyPermissions.length,
                  itemBuilder: (context, index) {
                    final permit = _historyPermissions[index];
                    final student = permit['student'];
                    final user = student != null ? student['user'] : null;
                    final classRoom = student != null ? student['classRoom'] : null;
                    final studentName = user != null ? user['fullName'] : 'Siswa';
                    final className = classRoom != null ? classRoom['name'] : '-';
                    final type = permit['type'];
                    final status = permit['status'];
                    final reason = permit['reason'];
                    
                    final isApproved = status == 'APPROVED';
                    final statusColor = isApproved ? Colors.green : Colors.red;
                    final statusIcon = isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(statusIcon, color: statusColor),
                        ),
                        title: Text('$studentName ($className)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Izin $type - Alasan: $reason', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
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


  void _handleLogout() async {
    ref.read(authTokenProvider.notifier).state = null;
    ref.read(tenantIdProvider.notifier).state = null;
    ref.read(userRoleProvider.notifier).state = null;
    await ref.read(localAuthStorageProvider).clearAuthData();
    if (mounted) context.go('/login');
  }
  Widget _buildAccountSettingsTab(bool isDesktop, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengaturan Akun', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text('Kelola informasi profil dan keamanan akun Anda.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.manage_accounts_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Segera Hadir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Fitur pengaturan akun sedang dalam pengembangan.', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgSettingsTab(bool isDesktop, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengaturan Lembaga', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text('Kelola informasi dan preferensi institusi Anda.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.domain_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Segera Hadir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Fitur pengaturan lembaga sedang dalam pengembangan.', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);

    // 9 Distinct view tabs
    final List<Widget> views = [
      _buildOverviewTab(isDesktop, theme),       // 0
      _buildPendingTab(isDesktop, theme),        // 1
      _buildHistoryTab(isDesktop, theme),        // 2
      _buildClassroomTab(isDesktop, theme),      // 3
      _buildTeacherTab(isDesktop, theme),        // 4
      _buildStudentTab(isDesktop, theme),        // 5
      _buildPdfManagementTab(isDesktop, theme),  // 6
      _buildAccountSettingsTab(isDesktop, theme),// 7
      _buildOrgSettingsTab(isDesktop, theme),    // 8
    ];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 260,
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                        child: Row(
                          children: [
                            Icon(Icons.school_rounded, color: theme.colorScheme.primary, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              'IzinFlow Admin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Theme(
                          data: theme.copyWith(dividerColor: Colors.transparent),
                          child: ListTileTheme(
                            selectedColor: theme.colorScheme.primary,
                            selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            iconColor: theme.colorScheme.onSurfaceVariant,
                            textColor: theme.colorScheme.onSurface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    leading: const Icon(Icons.dashboard_rounded),
                                    title: const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w600)),
                                    selected: _currentTabIndex == 0,
                                    onTap: () => setState(() => _currentTabIndex = 0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.assessment_rounded),
                                title: const Text('Aktivitas', style: TextStyle(fontWeight: FontWeight.w600)),
                                initiallyExpanded: _currentTabIndex >= 1 && _currentTabIndex <= 2,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                          leading: const Icon(Icons.pending_actions_rounded, size: 20),
                                          title: const Text('Pengajuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          selected: _currentTabIndex == 1,
                                          onTap: () => setState(() => _currentTabIndex = 1),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                          leading: const Icon(Icons.history_rounded, size: 20),
                                          title: const Text('Riwayat Izin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          selected: _currentTabIndex == 2,
                                          onTap: () => setState(() => _currentTabIndex = 2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.dataset_rounded),
                                title: const Text('Master Data', style: TextStyle(fontWeight: FontWeight.w600)),
                                initiallyExpanded: _currentTabIndex >= 3 && _currentTabIndex <= 5,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                          leading: const Icon(Icons.class_rounded, size: 20),
                                          title: const Text('Data Kelas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          selected: _currentTabIndex == 3,
                                          onTap: () => setState(() => _currentTabIndex = 3),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                          leading: const Icon(Icons.people_alt_rounded, size: 20),
                                          title: const Text('Data Guru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          selected: _currentTabIndex == 4,
                                          onTap: () => setState(() => _currentTabIndex = 4),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                          leading: const Icon(Icons.group_rounded, size: 20),
                                          title: const Text('Data Siswa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          selected: _currentTabIndex == 5,
                                          onTap: () => setState(() => _currentTabIndex = 5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.settings_rounded),
                                title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w600)),
                                initiallyExpanded: _currentTabIndex >= 6 && _currentTabIndex <= 8,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                          leading: const Icon(Icons.manage_accounts_rounded, size: 20),
                                          title: const Text('Pengaturan Akun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          selected: _currentTabIndex == 7,
                                          onTap: () => setState(() => _currentTabIndex = 7),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                          leading: const Icon(Icons.domain_rounded, size: 20),
                                          title: const Text('Pengaturan Lembaga', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          selected: _currentTabIndex == 8,
                                          onTap: () => setState(() => _currentTabIndex = 8),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 48.0, right: 16.0),
                                          leading: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                                          title: const Text('Manajemen PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          selected: _currentTabIndex == 6,
                                          onTap: () => setState(() => _currentTabIndex = 6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.red),
                          onPressed: _handleLogout,
                        ),
                      ),
                    ],
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
                ? 'IzinFlow Admin' 
                : (_currentTabIndex == 1 
                    ? 'Pengajuan Izin'
                    : (_currentTabIndex == 2 ? 'Riwayat Izin' : (_currentTabIndex == 3 ? 'Data Kelas' : (_currentTabIndex == 4 ? 'Data Guru' : (_currentTabIndex == 5 ? 'Data Siswa' : (_currentTabIndex == 6 ? 'Manajemen PDF' : (_currentTabIndex == 7 ? 'Pengaturan Akun' : 'Pengaturan Lembaga')))))))
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : () {
                _fetchData();
                _fetchDirectoryData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: views[_currentTabIndex],
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            if (index == 0) {
              setState(() => _currentTabIndex = 0);
            } else if (index == 1) {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFFF1F4EA),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pilih Aktivitas', 
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w700, 
                            color: Color(0xFF1E2923)
                          )
                        ),
                        const SizedBox(height: 24),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.pending_actions_rounded, color: Color(0xFF3B4D43), size: 28),
                          title: const Text('Pengajuan Izin', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2923))),
                          onTap: () {
                            setState(() => _currentTabIndex = 1);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.history_rounded, color: Color(0xFF3B4D43), size: 28),
                          title: const Text('Riwayat Izin', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2923))),
                          onTap: () {
                            setState(() => _currentTabIndex = 2);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if (index == 2) {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFFF1F4EA),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pilih Master Data', 
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w700, 
                            color: Color(0xFF1E2923)
                          )
                        ),
                        const SizedBox(height: 24),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.book, color: Color(0xFF3B4D43), size: 28),
                          title: const Text('Data Kelas', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2923))),
                          onTap: () {
                            setState(() => _currentTabIndex = 3);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.people_alt_rounded, color: Color(0xFF3B4D43), size: 28),
                          title: const Text('Data Guru', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2923))),
                          onTap: () {
                            setState(() => _currentTabIndex = 4);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.groups_rounded, color: Color(0xFF3B4D43), size: 28),
                          title: const Text('Data Siswa', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2923))),
                          onTap: () {
                            setState(() => _currentTabIndex = 5);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if (index == 3) {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFFF1F4EA),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pengaturan', 
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w700, 
                            color: Color(0xFF1E2923)
                          )
                        ),
                        const SizedBox(height: 24),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF3B4D43), size: 28),
                          title: const Text('Pengaturan Akun', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2923))),
                          onTap: () {
                            setState(() => _currentTabIndex = 7);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.domain_rounded, color: Color(0xFF3B4D43), size: 28),
                          title: const Text('Pengaturan Lembaga', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2923))),
                          onTap: () {
                            setState(() => _currentTabIndex = 8);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF3B4D43), size: 28),
                          title: const Text('Manajemen PDF', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E2923))),
                          onTap: () {
                            setState(() => _currentTabIndex = 6);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
          items: [
            CustomNavBarItem(icon: Icons.dashboard_rounded, label: 'Ringkasan'),
            CustomNavBarItem(icon: Icons.assessment_rounded, label: 'Aktivitas'),
            CustomNavBarItem(icon: Icons.dataset_rounded, label: 'Master Data'),
            CustomNavBarItem(icon: Icons.settings_rounded, label: 'Pengaturan'),
          ],
        ),
      );
    }
  }

  // --- COMPONENT VIEWS ---

  Widget _buildOverviewTab(bool isDesktop, ThemeData theme) {
    final schoolName = ref.watch(userFullNameProvider) ?? 'Administrator Sekolah';

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
                    Text('Portal Admin Sekolah', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('Kelola pendaftaran anggota sekolah, kelas, dan proses approval surat izin', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _isLoading ? null : () {
                    _fetchData();
                    _fetchDirectoryData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          Card(
            color: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.school_rounded, color: theme.colorScheme.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schoolName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Portal Admin Instansi  •  Kelola seluruh kelas, guru, dan siswa.',
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

          // Statistics
          LayoutBuilder(
            builder: (context, constraints) {
              final int crossAxisCount = isDesktop ? 3 : 2;
              final double cardWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: cardWidth, child: _buildStatCard('Pending', _stats['pendingCount'].toString(), Colors.orange, Icons.hourglass_empty_rounded, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildStatCard('Disetujui', _stats['approvedCount'].toString(), Colors.green, Icons.check_circle_outline_rounded, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildStatCard('Ditolak', _stats['rejectedCount'].toString(), Colors.red, Icons.cancel_outlined, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildStatCard('Siswa', _stats['totalStudents'].toString(), Colors.blue, Icons.people_outline_rounded, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildStatCard('Guru', _stats['totalTeachers'].toString(), Colors.purple, Icons.assignment_ind_outlined, isDesktop)),
                  SizedBox(width: cardWidth, child: _buildStatCard('Status', 'AKTIF', Colors.teal, Icons.domain_rounded, isDesktop)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          Text('Daftar Pengajuan Surat Izin Sekolah', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
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
                      onPressed: _fetchData,
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
                  'Belum ada pengajuan izin di sekolah Anda.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            )
          else
            Expanded(
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
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: Icon(
                        type == 'SICK' ? Icons.sick_outlined : Icons.event_note_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        '$studentName ($className)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Izin $type • $status',
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
                          padding: const EdgeInsets.all(16.0),
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
                              Text(
                                'Tanggal: ${startDate.toString().split(' ')[0]} s/d ${endDate.toString().split(' ')[0]}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (status == 'PENDING') ...[
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      label: const Text('Tolak'),
                                      onPressed: () => _showNoteDialog(permit['id'], 'reject'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Setujui'),
                                      onPressed: () => _showNoteDialog(permit['id'], 'approve'),
                                    ),
                                  ],
                                ),
                              ] else if (status == 'APPROVED') ...[
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.download_rounded, size: 16),
                                      label: const Text('Unduh PDF'),
                                      onPressed: () => _downloadPDF(permit['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassroomTab(bool isDesktop, ThemeData theme) {
    final formCard = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _classFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.add_box_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Buat Kelas Baru', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _classNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kelas',
                  hintText: 'misal: XII IPA 1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama kelas wajib diisi.' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitClassroom,
                child: const Text('Buat Kelas Baru', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );

    final listCard = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.class_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Daftar Kelas Aktif', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                // Toggle Button for Classroom Form
                IconButton.filledTonal(
                  icon: Icon(_showClassForm ? Icons.close_rounded : Icons.add_rounded),
                  onPressed: () => setState(() => _showClassForm = !_showClassForm),
                  tooltip: _showClassForm ? 'Tutup Formulir' : 'Tambah Kelas',
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: _isDirLoading
                  ? const CustomLoadingIndicator()
                  : _classrooms.isEmpty
                      ? const Center(child: Text('Belum ada kelas.', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          itemCount: _classrooms.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, idx) {
                            final c = _classrooms[idx];
                            final hr = c['homeroomTeacher'];
                            final teacherName = hr != null && hr['user'] != null ? hr['user']['fullName'] : 'Belum diatur';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(c['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Wali Kelas: $teacherName', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.blue), onPressed: () => _showEditClassDialog(c)),
                                  IconButton(icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red), onPressed: () => _deleteClassroom(c['id'])),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );

    if (_showClassForm) {
      if (isDesktop) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: formCard)),
              const SizedBox(width: 24),
              Expanded(child: listCard),
            ],
          ),
        );
      } else {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              formCard,
              const SizedBox(height: 16),
              SizedBox(height: 400, child: listCard),
            ],
          ),
        );
      }
    } else {
      // Form is hidden, show list in full screen/width
      return Padding(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: listCard,
      );
    }
  }

  Widget _buildTeacherTab(bool isDesktop, ThemeData theme) {
    final formCard = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _teacherFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Daftarkan Akun Guru Baru', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teacherNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap & Gelar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _teacherNipController,
                decoration: const InputDecoration(
                  labelText: 'NIP / No. Induk Guru',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _teacherEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Guru',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _teacherPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _teacherSelectedClassroomId,
                decoration: const InputDecoration(
                  labelText: 'Wali Kelas Untuk',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('-- Tanpa Kelas --')),
                  ..._classrooms.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'].toString()))),
                ],
                onChanged: (val) {
                  setState(() => _teacherSelectedClassroomId = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitTeacher,
                child: const Text('Daftarkan Guru Baru', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );

    final listCard = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Daftar Guru Aktif', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                // Toggle Button for Teacher Form
                IconButton.filledTonal(
                  icon: Icon(_showTeacherForm ? Icons.close_rounded : Icons.add_rounded),
                  onPressed: () => setState(() => _showTeacherForm = !_showTeacherForm),
                  tooltip: _showTeacherForm ? 'Tutup Formulir' : 'Tambah Guru',
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: _isDirLoading
                  ? const CustomLoadingIndicator()
                  : _teachers.isEmpty
                      ? const Center(child: Text('Belum ada guru.', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          itemCount: _teachers.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, idx) {
                            final t = _teachers[idx];
                            final name = t['user'] != null ? t['user']['fullName'] : 'Guru';
                            final email = t['user'] != null ? t['user']['email'] : '-';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Email: $email  •  NIP: ${t['employeeNumber'] ?? "-"}', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.blue), onPressed: () => _showEditTeacherDialog(t)),
                                  IconButton(icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red), onPressed: () => _deleteTeacher(t['id'])),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );

    if (_showTeacherForm) {
      if (isDesktop) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: formCard)),
              const SizedBox(width: 24),
              Expanded(child: listCard),
            ],
          ),
        );
      } else {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              formCard,
              const SizedBox(height: 16),
              SizedBox(height: 400, child: listCard),
            ],
          ),
        );
      }
    } else {
      return Padding(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: listCard,
      );
    }
  }

  Widget _buildStudentTab(bool isDesktop, ThemeData theme) {
    final formCard = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _studentFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.group_add_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Daftarkan Akun Siswa Baru', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentNisnController,
                decoration: const InputDecoration(
                  labelText: 'NISN / NIS',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Siswa',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _studentSelectedClassroomId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Kelas',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('-- Pilih Kelas --')),
                  ..._classrooms.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'].toString()))),
                ],
                onChanged: (val) {
                  setState(() => _studentSelectedClassroomId = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitStudent,
                child: const Text('Daftarkan Siswa Baru', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );

    final listCard = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Daftar Siswa Aktif', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                // Toggle Button for Student Form
                IconButton.filledTonal(
                  icon: Icon(_showStudentForm ? Icons.close_rounded : Icons.add_rounded),
                  onPressed: () => setState(() => _showStudentForm = !_showStudentForm),
                  tooltip: _showStudentForm ? 'Tutup Formulir' : 'Tambah Siswa',
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: _isDirLoading
                  ? const CustomLoadingIndicator()
                  : _students.isEmpty
                      ? const Center(child: Text('Belum ada siswa.', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          itemCount: _students.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, idx) {
                            final s = _students[idx];
                            final name = s['user'] != null ? s['user']['fullName'] : 'Siswa';
                            final cls = s['classRoom'] != null ? s['classRoom']['name'] : '-';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Kelas: $cls  •  NISN: ${s['studentIdNumber'] ?? "-"}', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.blue), onPressed: () => _showEditStudentDialog(s)),
                                  IconButton(icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red), onPressed: () => _deleteStudent(s['id'])),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );

    if (_showStudentForm) {
      if (isDesktop) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: formCard)),
              const SizedBox(width: 24),
              Expanded(child: listCard),
            ],
          ),
        );
      } else {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              formCard,
              const SizedBox(height: 16),
              SizedBox(height: 400, child: listCard),
            ],
          ),
        );
      }
    } else {
      return Padding(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: listCard,
      );
    }
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon, bool isDesktop) {
    if (!isDesktop) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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

  Widget _buildPdfManagementTab(bool isDesktop, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manajemen Cetak Surat Izin (PDF)', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 4),
                      Text('Atur template surat izin yang akan dicetak oleh sistem', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _isLoading ? null : _fetchData,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
              child: Form(
                key: _pdfSettingsFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings_applications_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Pengaturan Profil & Template PDF', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _orgNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lembaga', 
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orgLogoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Logo Lembaga',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orgAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lembaga',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orgContactController,
                      decoration: const InputDecoration(
                        labelText: 'Kontak Lembaga',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orgTemplateController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Teks Pembuka Surat',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitOrgSettings,
                              child: const Text('Simpan Pengaturan'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue.shade700,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                              label: const Text('Preview Template'),
                              onPressed: _previewSettingsPDF,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: _submitOrgSettings,
                            child: const Text('Simpan Pengaturan'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue.shade700,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                            label: const Text('Preview Template'),
                            onPressed: _previewSettingsPDF,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
