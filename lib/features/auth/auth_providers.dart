import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/permission_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    auth: ref.watch(firebaseAuthProvider),
    google: ref.watch(googleSignInProvider),
  );
});

class AuthController {
  AuthController({required this.auth, required this.google});

  final FirebaseAuth auth;
  final GoogleSignIn google;

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? account = await google.signIn();
    if (account == null) return null;
    final GoogleSignInAuthentication authTokens = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authTokens.accessToken,
      idToken: authTokens.idToken,
    );
    return await auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await google.signOut();
    await auth.signOut();
  }
}

// Local profile photo handling
final localProfilePhotoPathProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('local_profile_photo_path');
});

final profilePhotoControllerProvider = Provider<ProfilePhotoController>((ref) {
  return ProfilePhotoController(ref: ref);
});

class ProfilePhotoController {
  ProfilePhotoController({required this.ref});
  final Ref ref;

  Future<String?> pickAndSaveLocalProfilePhoto() async {
    final permissionOk = await ref.read(permissionServiceProvider).ensurePhotoPermission();
    if (!permissionOk) return null;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return null;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File target = File('${appDir.path}/$fileName');
    await File(image.path).copy(target.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_profile_photo_path', target.path);
    return target.path;
  }
}


