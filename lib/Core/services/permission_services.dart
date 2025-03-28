import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestPermissions() async {
    
    await Permission.photos.request();
    await Permission.camera.request();
    await Permission.storage.request();
  }

  static Future<bool> hasAllPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;

    return cameraStatus.isGranted &&
           storageStatus.isGranted &&
           photosStatus.isGranted;
  }
}
