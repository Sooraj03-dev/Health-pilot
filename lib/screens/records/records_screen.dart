import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final patientRecordsProvider = FutureProvider.family<List<FileObject>, String>((ref, patientId) async {
  final supabase = Supabase.instance.client;
  // List files under medical-docs/{patientId}
  final files = await supabase.storage.from('medical-docs').list(path: patientId);
  // Filter out any hidden or placeholder directory objects
  return files.where((f) => f.name.isNotEmpty && !f.name.startsWith('.')).toList();
});

class RecordsViewerScreen extends ConsumerWidget {
  final String patientId;

  const RecordsViewerScreen({super.key, required this.patientId});

  Future<void> _downloadFile(BuildContext context, String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      // Generate a 60-second signed URL for the specific file
      final signedUrl = await supabase.storage
          .from('medical-docs')
          .createSignedUrl('$patientId/$fileName', 60);

      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the file link.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating download URL: $e')),
        );
      }
    }
  }

  String _formatDate(String isoDate) {
    try {
      final DateTime date = DateTime.parse(isoDate).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(patientRecordsProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Records'),
        centerTitle: true,
      ),
      body: recordsAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No medical records found',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(
                  file.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Uploaded: ${_formatDate(file.createdAt ?? '')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.download_rounded),
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: 'Download',
                  onPressed: () => _downloadFile(context, file.name),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Failed to load records:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(patientRecordsProvider(patientId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
