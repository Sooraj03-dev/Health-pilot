import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<FileObject> _files = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final res = await _supabase.storage.from('medical-docs').list(path: user.id);
      
      // Filter out a placeholder empty file if supabase creates one (e.g. '.emptyFolderPlaceholder')
      setState(() {
        _files = res.where((f) => f.name != '.emptyFolderPlaceholder').toList()
                    ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching files: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        await _uploadFile(result.files.single);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Check if file.path is null (can happen on web, but this is a mobile app)
      if (file.path == null) throw Exception('File path is null');
      
      final fileBytes = await File(file.path!).readAsBytes();
      final path = '${user.id}/${file.name}';
      
      String contentType = 'application/octet-stream';
      if (file.extension != null) {
        final ext = file.extension!.toLowerCase();
        if (ext == 'pdf') contentType = 'application/pdf';
        else if (['jpg', 'jpeg'].contains(ext)) contentType = 'image/jpeg';
        else if (ext == 'png') contentType = 'image/png';
      }

      await _supabase.storage.from('medical-docs').uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      setState(() {
        _uploadProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful')));
      }
      _fetchFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Records'),
      ),
      body: Column(
        children: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Uploading...'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(child: Text('No files uploaded yet.'))
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          // Supabase metadata contains size
                          final size = file.metadata?['size'] as int? ?? 0;

                          IconData fileIcon = Icons.insert_drive_file;
                          final fileName = file.name.toLowerCase();
                          if (fileName.endsWith('.pdf')) {
                            fileIcon = Icons.picture_as_pdf;
                          } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
                            fileIcon = Icons.image;
                          }

                          return ListTile(
                            leading: Icon(
                              fileIcon,
                              color: Colors.blue,
                              size: 32,
                            ),
                            title: Text(file.name),
                            subtitle: Text('Uploaded: ${_formatDate(file.createdAt ?? '')}'),
                            trailing: Text(_formatBytes(size)),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }
}
