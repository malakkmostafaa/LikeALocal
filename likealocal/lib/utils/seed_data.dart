import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> seedEverything() async {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("❌ No logged in user");
    return;
  }

  final uid = user.uid;

  print("🚀 Seeding started...");

  // =========================
  // 👤 USER
  // =========================
  await firestore.collection('users').doc(uid).set({
    'uid': uid,
    'name': user.displayName ?? "Test User",
    'email': user.email,
    'preferences': ['Cafe', 'Food'],
    'pinsCount': 0,
    'placesAdded': 0,
    'reviewsCount': 0,
    'isSuperUser': false,
    'isPremium': false,
    'pinLimit': 5,
    'chatEnabled': true,
    'notificationsEnabled': true,
    'badges': [],
    'createdAt': FieldValue.serverTimestamp(),
  });

  // =========================
  // 📍 PLACES
  // =========================
  final place1 = await firestore.collection('places').add({
    'name': 'Hidden Cafe',
    'description': 'Cozy local cafe',
    'category': 'Cafe',
    'imageUrl': '',
    'location': const GeoPoint(30.0444, 31.2357),
    'createdBy': uid,
    'tips': 'Try iced latte',
    'recommendedDishes': ['Latte', 'Cake'],
    'rating': 4.5,
    'reviewsCount': 0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  final place2 = await firestore.collection('places').add({
    'name': 'Street Food Spot',
    'description': 'Best koshary in town',
    'category': 'Food',
    'imageUrl': '',
    'location': const GeoPoint(30.0500, 31.2400),
    'createdBy': uid,
    'tips': 'Try koshary',
    'recommendedDishes': ['Koshary', 'Foul'],
    'rating': 4.0,
    'reviewsCount': 0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // =========================
  // ⭐ REVIEWS
  // =========================
  await firestore
      .collection('places')
      .doc(place1.id)
      .collection('reviews')
      .add({
    'userId': uid,
    'userName': user.displayName ?? "User",
    'text': 'Amazing place!',
    'rating': 5,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // =========================
  // 📌 PINS
  // =========================
  await firestore
      .collection('users')
      .doc(uid)
      .collection('pins')
      .doc(place1.id)
      .set({
    'placeId': place1.id,
    'savedAt': FieldValue.serverTimestamp(),
  });

  // update pin count
  await firestore.collection('users').doc(uid).update({
    'pinsCount': 1,
  });

  // =========================
  // 💬 CHAT
  // =========================
  final chat = await firestore.collection('chats').add({
    'users': [uid, 'dummyUser'],
    'lastMessage': 'Hello!',
    'updatedAt': FieldValue.serverTimestamp(),
  });

  await firestore.collection('chats').doc(chat.id).collection('messages').add({
    'senderId': uid,
    'text': 'Hello!',
    'createdAt': FieldValue.serverTimestamp(),
  });

  // =========================
  // 🔔 NOTIFICATIONS
  // =========================
  await firestore.collection('notifications').add({
    'userId': uid,
    'title': 'Nearby place',
    'body': 'Check out Hidden Cafe!',
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // =========================
  // 🎮 CHALLENGE
  // =========================
  final challenge = await firestore.collection('challenges').add({
    'title': 'Visit a cafe',
    'description': 'Explore a new cafe',
    'reward': 'Explorer Badge',
  });

  await firestore
      .collection('users')
      .doc(uid)
      .collection('challenges')
      .doc(challenge.id)
      .set({
    'completed': false,
    'completedAt': null,
  });

  print("✅ Seeding completed!");
}
