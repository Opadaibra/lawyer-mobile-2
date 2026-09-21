import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/api_service.dart';
import '../../data/models/file_model.dart';
import '../../data/models/file_type_model.dart';
import '../../core/constants/app_constants.dart';

class FileController extends GetxController {
  final ApiService _api = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  final files = <FileModel>[].obs;
  final fileTypes = <FileTypeModel>[].obs;
  final isLoading = false.obs;
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Do not fetch all files here — scoped screens (case/minute/task)
    // would race with fetchFiles() and briefly/permanently show every file.
    fetchFileTypes();
  }

  Future<void> fetchFileTypes() async {
    try {
      final response = await _api.getList('file-types');
      final list = _parseList(response);
      fileTypes.value = list.map((e) => FileTypeModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Failed to fetch file types: $e');
    }
  }

  Future<void> fetchFiles() async {
    isLoading.value = true;
    try {
      final response = await _api.getList(AppConstants.files);
      final list = _parseList(response);
      files.value = list.map((e) => FileModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFilesByCase(int caseId) async {
    isLoading.value = true;
    files.clear();
    try {
      final response = await _api.getList('/files/by-case/$caseId');
      final list = _parseList(response);
      files.value = list.map((e) => FileModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFilesByMinute(int minuteId) async {
    isLoading.value = true;
    files.clear();
    try {
      final response = await _api.getList('/files/by-minute/$minuteId');
      final list = _parseList(response);
      files.value = list.map((e) => FileModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFilesByTask(int taskId) async {
    isLoading.value = true;
    files.clear();
    try {
      final response = await _api.getList('/files/by-task/$taskId');
      final list = _parseList(response);
      files.value = list.map((e) => FileModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> pickAndUpload({
    Map<String, String>? extraFields,
    bool allowMultiple = false,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return false;

      isUploading.value = true;
      var anySuccess = false;

      for (final file in result.files) {
        if (file.path == null) continue;

        final customName = await _askForFileName(file.name);
        if (customName == null) continue;

        final response = await _api.uploadFile(
          filePath: file.path!,
          fileName: customName,
          fields: extraFields,
        );

        final parsed = _parseUploadResponse(response);
        for (final item in parsed) {
          files.insert(0, item);
        }
        anySuccess = true;
      }

      if (anySuccess) {
        _showSuccess(allowMultiple
            ? 'Files uploaded / تم رفع الملفات'
            : 'File uploaded / تم رفع الملف');
      }
      return anySuccess;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  /// Pick an image from the camera and upload it
  Future<bool> pickAndUploadFromCamera({
    Map<String, String>? extraFields,
  }) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return false;

      final customName = await _askForFileName(photo.name);
      if (customName == null) return false;

      isUploading.value = true;
      final response = await _api.uploadFile(
        filePath: photo.path,
        fileName: customName,
        fields: extraFields,
      );

      final parsed = _parseUploadResponse(response);
      for (final item in parsed) {
        files.insert(0, item);
      }
      _showSuccess('تم رفع الصورة بنجاح');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  /// Pick an image from the gallery and upload it
  Future<bool> pickAndUploadFromGallery({
    Map<String, String>? extraFields,
    bool allowMultiple = false,
  }) async {
    try {
      if (allowMultiple) {
        final List<XFile> photos = await _imagePicker.pickMultiImage(
          imageQuality: 85,
        );
        if (photos.isEmpty) return false;

        isUploading.value = true;
        var anySuccess = false;
        for (final photo in photos) {
          final customName = await _askForFileName(photo.name);
          if (customName == null) continue;

          final response = await _api.uploadFile(
            filePath: photo.path,
            fileName: customName,
            fields: extraFields,
          );
          final parsed = _parseUploadResponse(response);
          for (final item in parsed) {
            files.insert(0, item);
          }
          anySuccess = true;
        }
        if (anySuccess) _showSuccess('تم رفع الصور بنجاح');
        return anySuccess;
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo == null) return false;

      final customName = await _askForFileName(photo.name);
      if (customName == null) return false;

      isUploading.value = true;
      final response = await _api.uploadFile(
        filePath: photo.path,
        fileName: customName,
        fields: extraFields,
      );

      final parsed = _parseUploadResponse(response);
      for (final item in parsed) {
        files.insert(0, item);
      }
      _showSuccess('تم رفع الصورة بنجاح');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> deleteFile(int id) async {
    try {
      await _api.delete('${AppConstants.files}/$id');
      files.removeWhere((f) => f.id == id);
      _showSuccess('moved_to_recycle_bin'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<bool> updateFileType(int id, int? fileTypeId) async {
    try {
      final response = await _api.put('${AppConstants.files}/$id', data: {
        'file_type_id': fileTypeId,
      });
      final data = (response['data'] as Map<String, dynamic>?) ??
          (response['file'] as Map<String, dynamic>?) ??
          response;
      if (data.isNotEmpty && data.containsKey('id')) {
        final updatedFile = FileModel.fromJson(data);
        final index = files.indexWhere((f) => f.id == id);
        if (index != -1) {
          files[index] = updatedFile;
        }
      }
      _showSuccess('تم تحديث تصنيف الملف بنجاح');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<String?> _askForFileName(String originalName) async {
    final TextEditingController controller =
        TextEditingController(text: originalName);
    String? newName = originalName;
    bool confirmed = false;

    await Get.defaultDialog(
      title: 'اسم الملف / File Name',
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'أدخل اسم الملف',
        ),
      ),
      textConfirm: 'تأكيد',
      textCancel: 'إلغاء',
      onConfirm: () {
        newName = controller.text;
        confirmed = true;
        Get.back();
      },
      onCancel: () {
        confirmed = false;
      },
    );

    return confirmed ? newName : null;
  }

  List<FileModel> _parseUploadResponse(Map<String, dynamic> response) {
    final result = <FileModel>[];
    final data = response['data'];
    if (data is List) {
      for (final e in data) {
        if (e is Map) {
          result.add(FileModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      return result;
    }
    if (data is Map) {
      result.add(FileModel.fromJson(Map<String, dynamic>.from(data)));
      return result;
    }
    if (response['files'] is List) {
      for (final e in response['files'] as List) {
        if (e is Map) {
          result.add(FileModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      return result;
    }
    if (response['file'] is Map) {
      result.add(
          FileModel.fromJson(Map<String, dynamic>.from(response['file'])));
    }
    return result;
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? response['files'] as List? ?? [];
    }
    return [];
  }

  void _showError(dynamic e) {
    Get.snackbar('Error / خطأ',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success / نجاح', msg, snackPosition: SnackPosition.BOTTOM);
  }
}
