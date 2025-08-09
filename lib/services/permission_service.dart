import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) => PermissionService());

class PermissionService {
  Future<bool> ensurePhotoPermission() async {
    // Android 13+ uses READ_MEDIA_IMAGES; older versions use READ_EXTERNAL_STORAGE.
    // permission_handler abstracts this via photos permission.
    final status = await Permission.photos.status;
    if (status.isGranted) return true;
    final result = await Permission.photos.request();
    return result.isGranted;
  }
}


