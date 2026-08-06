import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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

      final res = await ApiService.instance.dio.post('/driver/documents', data: formData);
      if (mounted) {
        setState(() {
          _document = res.data['document'];
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiService.friendlyError(e as Exception))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Documents (KYC)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_document != null) ...[
                  ListTile(
                    title: const Text('Status'),
                    subtitle: Text(
                      _document!['status'].toUpperCase(),
                      style: TextStyle(
                        color: _document!['status'] == 'approved'
                            ? Colors.green
                            : _document!['status'] == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                _buildUploadCard(
                  title: "Driver's License",
                  path: _document?['license_path'],
                  onTap: () => _upload('license'),
                ),
                const SizedBox(height: 16),
                _buildUploadCard(
                  title: "Vehicle Insurance",
                  path: _document?['insurance_path'],
                  onTap: () => _upload('insurance'),
                ),
              ],
            ),
    );
  }

  Widget _buildUploadCard({required String title, String? path, required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: path != null ? const Text('Uploaded') : const Text('Not uploaded yet'),
        trailing: ElevatedButton(
          onPressed: onTap,
          child: const Text('Upload'),
        ),
      ),
    );
  }
}
