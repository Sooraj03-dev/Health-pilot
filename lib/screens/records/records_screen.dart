import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicalRecord {
  final String id;
  final String userId;
  final String fileName;
  final String filePath;
  final String category;
  final int fileSize;
  final String? notes;
  final DateTime createdAt;

  MedicalRecord.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      userId = json['user_id'],
      fileName = json['file_name'],
      filePath = json['file_path'],
      category = json['category'],
      fileSize = json['file_size'] ?? 0,
      notes = json['notes'],
      createdAt = DateTime.parse(json['created_at']).toLocal();
}

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final List<String> _categories = [
    'Prescriptions',
    'Lab Results',
    'Scans',
    'General',
  ];

  List<MedicalRecord> _records = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadingFileName = '';

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final res = await _supabase
          .from('medical_records')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _records = (res as List).map((e) => MedicalRecord.fromJson(e)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching records: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._categories.map((cat) => ListTile(
                leading: Icon(_getIconForCategory(cat), color: Theme.of(context).primaryColor),
                title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w500)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadFile(cat);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Prescriptions':
        return Icons.medical_information;
      case 'Lab Results':
        return Icons.science;
      case 'Scans':
        return Icons.document_scanner;
      case 'General':
      default:
        return Icons.folder;
    }
  }

  Future<void> _pickAndUploadFile(String category) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        await _uploadFile(result.files.single, category);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _uploadFile(PlatformFile file, String category) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadingFileName = file.name;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      Uint8List fileBytes;
      if (kIsWeb) {
        if (file.bytes == null) throw Exception('File bytes are null on web');
        fileBytes = file.bytes!;
      } else {
        if (file.path == null) throw Exception('File path is null');
        fileBytes = await File(file.path!).readAsBytes();
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${user.id}/$category/${timestamp}_${file.name}';
      
      String contentType = 'application/octet-stream';
      if (file.extension != null) {
        final ext = file.extension!.toLowerCase();
        if (ext == 'pdf') contentType = 'application/pdf';
        else if (['jpg', 'jpeg'].contains(ext)) contentType = 'image/jpeg';
        else if (ext == 'png') contentType = 'image/png';
      }

      // 1. Upload exactly to storage
      await _supabase.storage.from('medical-docs').uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      setState(() {
        _uploadProgress = 0.5;
      });

      // 2. Insert metadata into Postgres
      await _supabase.from('medical_records').insert({
        'user_id': user.id,
        'file_name': file.name,
        'file_path': path,
        'category': category,
        'file_size': fileBytes.length,
      });

      setState(() {
        _uploadProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successfully recorded')));
      }
      _fetchRecords();
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft off-white background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.grey[50],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'My Records',
                style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            ),
          ),
          
          if (_isUploading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2.5)
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Uploading $_uploadingFileName...',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_uploadProgress > 0) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _uploadProgress, 
                            backgroundColor: Colors.grey[200],
                            minHeight: 6,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_records.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_system_daydream_rounded,
                        size: 64,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Records Found',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your latest medical records and lab\nresults will securely appear here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = _records[index];
                    final isPdf = record.fileName.toLowerCase().endsWith('.pdf');
                    
                    // Thematic Colors
                    final Color iconBgColor = isPdf ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1);
                    final Color iconColor = isPdf ? Colors.red[700]! : Colors.blue[700]!;
                    final IconData fileIcon = isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Can expand to show notes, preview, or download
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: iconBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(fileIcon, color: iconColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.fileName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(record.createdAt),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.sd_storage, size: 12, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatBytes(record.fileSize),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    record.category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _records.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showCategoryPicker,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('New Document', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
