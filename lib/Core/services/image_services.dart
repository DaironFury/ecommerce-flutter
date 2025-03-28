import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ImageService {
  final _picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;

  // Obtener directorio externo dinámico
  Future<Directory> _getExternalDirectory() async {
    final directories = await getExternalStorageDirectories(type: StorageDirectory.pictures);
    final dir = directories?.first ?? await getExternalStorageDirectory();

    final appFolder = Directory('${dir!.path}/PhotoGalleryApp');
    if (!await appFolder.exists()) {
      await appFolder.create(recursive: true);
    }
    return appFolder;
  }

 
  Future<File?> pickImage({bool fromCamera = false}) async {
    final pickedFile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return null;

    final externalDir = await _getExternalDirectory();
    final fileName = basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${externalDir.path}/$fileName');

    await _firestore.collection('images').add({
      'path': savedImage.path,
      'createdAt': Timestamp.now(),
    });

    return savedImage;
  }

  Future<File?> pickImageFromGallery() => pickImage(fromCamera: false);
  Future<File?> pickImageFromCamera() => pickImage(fromCamera: true);

  Future<List<File>> getSavedImages() async {
    final result = await _firestore.collection('images').orderBy('createdAt', descending: true).get();
    return result.docs.map((doc) => File(doc['path'])).toList();
  }

  Future<void> deleteImage(String path) async {
    final snapshot = await _firestore.collection('images').where('path', isEqualTo: path).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
