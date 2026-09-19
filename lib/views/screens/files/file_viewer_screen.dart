import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/file_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class FileViewerScreen extends StatefulWidget {
  const FileViewerScreen({super.key});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  FileModel? _file;
  bool _downloading = false;
  double _progress = 0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _file = args?['file'] as FileModel?;
    if (_file?.absoluteUrl != null) {
      _downloadFile();
    }
  }

  Future<void> _downloadFile() async {
    if (_file?.absoluteUrl == null) return;
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      final token = StorageService.getToken();
      final request = http.Request('GET', Uri.parse(_file!.absoluteUrl!));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final response = await request.send();
      final total = response.contentLength ?? 1;
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${_file!.displayName}';
      final file = File(filePath);
      final sink = file.openWrite();
      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        setState(() => _progress = received / total);
      }
      await sink.close();
      setState(() {
        _localPath = filePath;
        _downloading = false;
      });
    } catch (e) {
      setState(() => _downloading = false);
      Get.snackbar('Error', 'Failed to load file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _file?.displayName ?? 'File Viewer / عرض الملف',
        showNotification: false,
        actions: [
          if (_localPath != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open with... / فتح بـ',
              onPressed: () => OpenFilex.open(_localPath!),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_file == null) {
      return const Center(child: Text('No file selected'));
    }

    if (_downloading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Downloading file... / جاري تحميل الملف'),
          ],
        ),
      );
    }

    if (_localPath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppHelpers.getFileIcon(_file!.displayName),
                size: 80, color: AppTheme.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(_file!.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _downloadFile,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Retry / إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    // File is downloaded — show preview or open prompt
    final ext = _localPath!.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Center(
        child: InteractiveViewer(
          child: Image.file(File(_localPath!)),
        ),
      );
    }

    // Non-image: show info + open button
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppHelpers.getFileIcon(_file!.displayName),
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _file!.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_file!.size != null) ...[
              const SizedBox(height: 8),
              Text(
                AppHelpers.formatFileSize(_file!.size!),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => OpenFilex.open(_localPath!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open with App / فتح بتطبيق'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                // Save to downloads
                final downloadsDir = await getApplicationDocumentsDirectory();
                final destPath =
                    '${downloadsDir.path}/${_file!.displayName}';
                await File(_localPath!).copy(destPath);
                Get.snackbar('Saved', 'File saved to documents / تم الحفظ');
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save to Documents / حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
