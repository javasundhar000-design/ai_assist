import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/errors/app_exception.dart';

/// Firebase Storage is used only for large binary files — room photos,
/// profile pictures, design previews, furniture images, GLB/glTF models
/// (Sec. 25). Realtime Database stores only the resulting download URL.
class StorageService {
  final FirebaseStorage _storage;
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String folder,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('$folder/$fileName');
      final task = ref.putFile(file);
      if (onProgress != null) {
        task.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
          }
        });
      }
      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw StorageException('File upload failed. Please try again.',
          cause: e);
    }
  }

  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw StorageException('Could not delete file.', cause: e);
    }
  }
}
