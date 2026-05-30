import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/custom_loading_indicator.dart';

class NewPermissionPage extends ConsumerStatefulWidget {
  const NewPermissionPage({super.key});

  @override
  ConsumerState<NewPermissionPage> createState() => _NewPermissionPageState();
}

class _NewPermissionPageState extends ConsumerState<NewPermissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String _selectedType = 'SICK';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

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
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.data['message'] ?? 'Pengajuan izin berhasil dikirim!'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(); // Go back to student dashboard (which will fetch updated records)
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pengajuan Izin'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formulir Ketidakhadiran Siswa',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan isi jenis izin beserta alasan yang valid untuk ditinjau oleh Wali Kelas.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 16),

                // Start Date Picker
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  tileColor: Colors.white,
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
                const SizedBox(height: 16),

                // End Date Picker
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  tileColor: Colors.white,
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
                const SizedBox(height: 16),

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
                const SizedBox(height: 32),

                // Form Submit Button
                _isLoading
                    ? const CustomLoadingIndicator()
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Ajukan Surat Izin Resmi'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
