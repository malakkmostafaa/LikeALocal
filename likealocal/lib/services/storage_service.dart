import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadCurrentUserProfileImage(File imageFile) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    if (!await imageFile.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final fileSize = await imageFile.length();

    if (fileSize == 0) {
      throw Exception('Selected image file is empty.');
    }

    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('Image is too large. Please choose an image under 10MB.');
    }

    final uid = user.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final extension = _safeImageExtension(imageFile.path);
    final contentType = _contentTypeFromExtension(extension);

    final ref = _storage
        .ref()
        .child('users')
        .child(uid)
        .child('profile')
        .child('profile_$timestamp.$extension');

    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'uid': uid,
        'type': 'profile_image',
      },
    );

    final uploadTask = await ref.putFile(imageFile, metadata);
    return uploadTask.ref.getDownloadURL();
  }

  String _safeImageExtension(String path) {
    final extension = path.split('.').last.toLowerCase();

    if (extension == 'jpg') return 'jpeg';

    if (['jpeg', 'png', 'webp'].contains(extension)) {
      return extension;
    }

    return 'jpeg';
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
