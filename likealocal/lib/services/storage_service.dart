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

    final uid = user.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final extension = imageFile.path.split('.').last.toLowerCase();
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';

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
    return await uploadTask.ref.getDownloadURL();
  }
}
