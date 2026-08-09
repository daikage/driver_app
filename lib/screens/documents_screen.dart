import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  Map<String, dynamic>? _document;
  bool _loading = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchDocument();
  }

  Future<void> _fetchDocument() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.dio.get('/driver/documents');
      if (mounted) {
        setState(() {
          _document = res.data['document'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _upload(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _loading = true);

    try {
      final formData = FormData.fromMap({
        type: await MultipartFile.fromFile(image.path, filename: image.name),
      });

      final res =
          await ApiService.instance.dio.post('/driver/documents', data: formData);
      if (mounted) {
        setState(() {
          _document = res.data['document'];
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Uploaded successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ApiService.friendlyError(e as Exception)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Documents'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primary),
        ),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Status card ─────────────────────────────────────
                if (_document != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _statusColor(_document!['status'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _statusIcon(_document!['status']),
                            color: _statusColor(_document!['status']),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verification Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _document!['status']
                                    .toString()
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color:
                                      _statusColor(_document!['status']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Upload cards ────────────────────────────────────
                _buildUploadCard(
                  title: "Driver's License",
                  subtitle: 'Government-issued driving license',
                  path: _document?['license_path'],
                  icon: Icons.badge_outlined,
                  onTap: () => _upload('license'),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildUploadCard(
                  title: 'Vehicle Insurance',
                  subtitle: 'Valid vehicle insurance certificate',
                  path: _document?['insurance_path'],
                  icon: Icons.shield_outlined,
                  onTap: () => _upload('insurance'),
                  isDark: isDark,
                ),
              ],
            ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    String? path,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isUploaded = path != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: isUploaded
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isUploaded ? AppColors.success : AppColors.electricBlue)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isUploaded ? Icons.check_circle_outline_rounded : icon,
              color: isUploaded ? AppColors.success : AppColors.electricBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded ? 'Uploaded ✓' : subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUploaded
                        ? AppColors.success
                        : Colors.grey.shade500,
                    fontWeight:
                        isUploaded ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Upload',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
