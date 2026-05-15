import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedAll() async {
    final batch = _firestore.batch();

    final users = _seedUsers();
    final places = _seedPlaces();
    final reviewsByPlace = _seedReviews();

    // =========================
    // USERS
    // =========================
    for (final user in users) {
      final userRef = _firestore.collection('users').doc(user['uid']);
      batch.set(userRef, user, SetOptions(merge: true));
    }

    // =========================
    // PLACES
    // =========================
    for (final place in places) {
      final placeRef = _firestore.collection('places').doc(place['id']);

      final placeData = Map<String, dynamic>.from(place);
      placeData.remove('id');

      batch.set(placeRef, placeData, SetOptions(merge: true));
    }

    // =========================
    // REVIEWS SUBCOLLECTIONS
    // =========================
    reviewsByPlace.forEach((placeId, reviews) {
      for (final review in reviews) {
        final reviewRef = _firestore
            .collection('places')
            .doc(placeId)
            .collection('reviews')
            .doc();

        batch.set(reviewRef, review);
      }
    });

    await batch.commit();
  }

  List<Map<String, dynamic>> _seedUsers() {
    return [
      {
        'uid': 'seed_user_zeina',
        'name': 'Zeina',
        'email': 'zeina@example.com',
        'preferences': ['Food', 'Cafés', 'Hidden Gems'],
        'maxDistance': 15.0,
        'priceRange': 2,
        'pinsCount': 3,
        'placesAdded': 2,
        'reviewsCount': 3,
        'isSuperUser': true,
        'isPremium': false,
        'chatEnabled': true,
        'notificationsEnabled': true,
        'badges': ['Local Explorer', 'First Review'],
        'profileImageUrl': '',
        'bio': 'Always looking for cozy hidden spots around Cairo.',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_user_mariam',
        'name': 'Mariam',
        'email': 'mariam@example.com',
        'preferences': ['Art', 'History', 'Cafés'],
        'maxDistance': 20.0,
        'priceRange': 3,
        'pinsCount': 5,
        'placesAdded': 1,
        'reviewsCount': 4,
        'isSuperUser': false,
        'isPremium': true,
        'chatEnabled': true,
        'notificationsEnabled': true,
        'badges': ['Culture Lover'],
        'profileImageUrl': '',
        'bio': 'Museums, old streets, galleries, and calm cafés.',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_user_omar',
        'name': 'Omar',
        'email': 'omar@example.com',
        'preferences': ['Food', 'Nightlife', 'Shopping'],
        'maxDistance': 10.0,
        'priceRange': 2,
        'pinsCount': 1,
        'placesAdded': 1,
        'reviewsCount': 2,
        'isSuperUser': false,
        'isPremium': false,
        'chatEnabled': true,
        'notificationsEnabled': false,
        'badges': [],
        'profileImageUrl': '',
        'bio': 'Food spots and casual weekend plans.',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];
  }

  List<Map<String, dynamic>> _seedPlaces() {
    return [
      {
        'id': 'place_zamalek_cafe',
        'name': 'Garden Nook Café',
        'description':
            'A cozy café tucked inside a quiet Zamalek side street, perfect for studying, catching up with friends, or slow weekend mornings.',
        'category': 'Cafés',
        'images': [
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24',
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93',
        ],
        'location': const GeoPoint(30.0610, 31.2197),
        'createdBy': 'seed_user_zeina',
        'createdAt': FieldValue.serverTimestamp(),
        'tips': [
          {
            'text': 'Go before 5 PM if you want a quiet table.',
            'authorId': 'seed_user_zeina',
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 4)),
            ),
          },
          {
            'text': 'Their outdoor corner is better than the indoor seating.',
            'authorId': 'seed_user_mariam',
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 2)),
            ),
          },
        ],
        'recommendedDishes': [
          {
            'name': 'Iced Spanish Latte',
            'description': 'Sweet, creamy, and very consistent.',
            'authorId': 'seed_user_zeina',
            'upvotes': 8,
          },
          {
            'name': 'Turkey Croissant',
            'description': 'Good light brunch option.',
            'authorId': 'seed_user_mariam',
            'upvotes': 5,
          },
        ],
        'rating': 4.7,
        'reviewCount': 3,
      },
      {
        'id': 'place_khan_hidden_rooftop',
        'name': 'Old Cairo Rooftop',
        'description':
            'A hidden rooftop overlooking old Cairo streets, with traditional tea, calm lighting, and a beautiful sunset view.',
        'category': 'Hidden Gems',
        'images': [
          'https://images.unsplash.com/photo-1512453979798-5ea266f8880c',
          'https://images.unsplash.com/photo-1548013146-72479768bada',
        ],
        'location': const GeoPoint(30.0478, 31.2625),
        'createdBy': 'seed_user_mariam',
        'createdAt': FieldValue.serverTimestamp(),
        'tips': [
          {
            'text': 'Best time is around sunset.',
            'authorId': 'seed_user_mariam',
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 7)),
            ),
          },
          {
            'text': 'Ask for mint tea and sit near the edge view.',
            'authorId': 'seed_user_omar',
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 3)),
            ),
          },
        ],
        'recommendedDishes': [
          {
            'name': 'Mint Tea',
            'description': 'Simple but very fresh.',
            'authorId': 'seed_user_mariam',
            'upvotes': 12,
          },
        ],
        'rating': 4.5,
        'reviewCount': 2,
      },
      {
        'id': 'place_maadi_bites',
        'name': 'Maadi Bites',
        'description':
            'A casual comfort-food spot in Maadi with burgers, fries, and friendly service. Good for group outings.',
        'category': 'Food',
        'images': [
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
          'https://images.unsplash.com/photo-1550547660-d9450f859349',
        ],
        'location': const GeoPoint(29.9602, 31.2569),
        'createdBy': 'seed_user_omar',
        'createdAt': FieldValue.serverTimestamp(),
        'tips': [
          {
            'text': 'Avoid peak dinner time if you hate waiting.',
            'authorId': 'seed_user_omar',
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 5)),
            ),
          },
        ],
        'recommendedDishes': [
          {
            'name': 'Classic Beef Burger',
            'description': 'Juicy and filling.',
            'authorId': 'seed_user_omar',
            'upvotes': 10,
          },
          {
            'name': 'Loaded Fries',
            'description': 'Better shared with friends.',
            'authorId': 'seed_user_zeina',
            'upvotes': 7,
          },
        ],
        'rating': 4.2,
        'reviewCount': 3,
      },
      {
        'id': 'place_downtown_gallery',
        'name': 'Downtown Art Corner',
        'description':
            'A small independent gallery with rotating exhibitions, handmade pieces, and a calm creative atmosphere.',
        'category': 'Art',
        'images': [
          'https://images.unsplash.com/photo-1541961017774-22349e4a1262',
          'https://images.unsplash.com/photo-1531058020387-3be344556be6',
        ],
        'location': const GeoPoint(30.0444, 31.2357),
        'createdBy': 'seed_user_mariam',
        'createdAt': FieldValue.serverTimestamp(),
        'tips': [
          {
            'text': 'Check their Instagram before going because events change.',
            'authorId': 'seed_user_mariam',
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 6)),
            ),
          },
        ],
        'recommendedDishes': [],
        'rating': 4.8,
        'reviewCount': 2,
      },
    ];
  }

  Map<String, List<Map<String, dynamic>>> _seedReviews() {
    return {
      'place_zamalek_cafe': [
        {
          'userId': 'seed_user_zeina',
          'userName': 'Zeina',
          'text':
              'Very calm and cozy. I liked that it does not feel overcrowded during the afternoon.',
          'rating': 5,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 6)),
          ),
        },
        {
          'userId': 'seed_user_mariam',
          'userName': 'Mariam',
          'text':
              'The place is pretty and the coffee is good, but weekends can get a bit noisy.',
          'rating': 4,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3)),
          ),
        },
        {
          'userId': 'seed_user_omar',
          'userName': 'Omar',
          'text':
              'Good spot for casual meetups. The outdoor seating is the best part.',
          'rating': 5,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
        },
      ],
      'place_khan_hidden_rooftop': [
        {
          'userId': 'seed_user_mariam',
          'userName': 'Mariam',
          'text':
              'Beautiful view and very peaceful. It feels like a hidden gem, especially at sunset.',
          'rating': 5,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 5)),
          ),
        },
        {
          'userId': 'seed_user_omar',
          'userName': 'Omar',
          'text':
              'Nice atmosphere and affordable drinks. The stairs are a bit tiring though.',
          'rating': 4,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2)),
          ),
        },
      ],
      'place_maadi_bites': [
        {
          'userId': 'seed_user_omar',
          'userName': 'Omar',
          'text': 'The burger was really good and the portions were generous.',
          'rating': 4,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 8)),
          ),
        },
        {
          'userId': 'seed_user_zeina',
          'userName': 'Zeina',
          'text':
              'Nice for groups. I would not go there for a quiet meal, but the food is solid.',
          'rating': 4,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 4)),
          ),
        },
        {
          'userId': 'seed_user_mariam',
          'userName': 'Mariam',
          'text': 'Good comfort food, but I wish they had more light options.',
          'rating': 4,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
        },
      ],
      'place_downtown_gallery': [
        {
          'userId': 'seed_user_mariam',
          'userName': 'Mariam',
          'text': 'Small but beautiful. The atmosphere is very inspiring.',
          'rating': 5,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        },
        {
          'userId': 'seed_user_zeina',
          'userName': 'Zeina',
          'text':
              'Loved the handmade pieces. It is a calm place to visit after walking downtown.',
          'rating': 5,
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3)),
          ),
        },
      ],
    };
  }
} // import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'categories.dart';

// Future<void> seedEverything() async {
//   final firestore = FirebaseFirestore.instance;
//   final user = FirebaseAuth.instance.currentUser;

//   if (user == null) {
//     print("❌ No logged in user");
//     return;
//   }

//   final uid = user.uid;

//   print("🚀 Seeding started...");

//   // =========================
//   // 👤 USER
//   // =========================
//   await firestore.collection('users').doc(uid).set({
//     'uid': uid,
//     'name': user.displayName ?? "Test User",
//     'email': user.email,
//     'preferences': [Categories.cafe, Categories.food],
//     'pinsCount': 0,
//     'placesAdded': 0,
//     'reviewsCount': 0,
//     'isSuperUser': false,
//     'isPremium': false,
//     'pinLimit': 5,
//     'chatEnabled': true,
//     'notificationsEnabled': true,
//     'badges': [],
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   // =========================
//   // 📍 PLACES
//   // =========================
//   final place1 = await firestore.collection('places').add({
//     'name': 'Hidden Cafe',
//     'description': 'Cozy local cafe',
//     'category': Categories.cafe,
//     'images': [],
//     'location': const GeoPoint(30.0444, 31.2357),
//     'createdBy': uid,
//     'tips': [
//       {
//         'text': 'Try iced latte',
//         'authorId': uid,
//         'createdAt': FieldValue.serverTimestamp(),
//       }
//     ],
//     'rating': 4.5,
//     'reviewCount': 0,
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   // add dishes as subcollection for food places
//   await firestore.collection('places').doc(place1.id).collection('dishes').add({
//     'name': 'Latte',
//     'description': 'Creamy and smooth',
//     'authorId': uid,
//     'upvotes': 0,
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   await firestore.collection('places').doc(place1.id).collection('dishes').add({
//     'name': 'Cake',
//     'description': 'Homemade slices',
//     'authorId': uid,
//     'upvotes': 0,
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   final place2 = await firestore.collection('places').add({
//     'name': 'Street Food Spot',
//     'description': 'Best koshary in town',
//     'category': Categories.food,
//     'images': [],
//     'location': const GeoPoint(30.0500, 31.2400),
//     'createdBy': uid,
//     'tips': [
//       {
//         'text': 'Try koshary',
//         'authorId': uid,
//         'createdAt': FieldValue.serverTimestamp(),
//       }
//     ],
//     'rating': 4.0,
//     'reviewCount': 0,
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   await firestore.collection('places').doc(place2.id).collection('dishes').add({
//     'name': 'Koshary',
//     'description': 'Street-style mix',
//     'authorId': uid,
//     'upvotes': 0,
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   await firestore.collection('places').doc(place2.id).collection('dishes').add({
//     'name': 'Foul',
//     'description': 'Hearty fava beans',
//     'authorId': uid,
//     'upvotes': 0,
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   // =========================
//   // ⭐ REVIEWS
//   // =========================
//   await firestore
//       .collection('places')
//       .doc(place1.id)
//       .collection('reviews')
//       .add({
//     'userId': uid,
//     'userName': user.displayName ?? "User",
//     'text': 'Amazing place!',
//     'rating': 5,
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   // =========================
//   // 📌 PINS
//   // =========================
//   await firestore
//       .collection('users')
//       .doc(uid)
//       .collection('pins')
//       .doc(place1.id)
//       .set({
//     'placeId': place1.id,
//     'savedAt': FieldValue.serverTimestamp(),
//   });

//   // update pin count
//   await firestore.collection('users').doc(uid).update({
//     'pinsCount': 1,
//   });

//   // =========================
//   // 💬 CHAT
//   // =========================
//   final chat = await firestore.collection('chats').add({
//     'users': [uid, 'dummyUser'],
//     'lastMessage': 'Hello!',
//     'updatedAt': FieldValue.serverTimestamp(),
//   });

//   await firestore.collection('chats').doc(chat.id).collection('messages').add({
//     'senderId': uid,
//     'text': 'Hello!',
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   // =========================
//   // 🔔 NOTIFICATIONS
//   // =========================
//   await firestore.collection('notifications').add({
//     'userId': uid,
//     'title': 'Nearby place',
//     'body': 'Check out Hidden Cafe!',
//     'isRead': false,
//     'createdAt': FieldValue.serverTimestamp(),
//   });

//   // =========================
//   // 🎮 CHALLENGE
//   // =========================
//   final challenge = await firestore.collection('challenges').add({
//     'title': 'Visit a cafe',
//     'description': 'Explore a new cafe',
//     'reward': 'Explorer Badge',
//   });

//   await firestore
//       .collection('users')
//       .doc(uid)
//       .collection('challenges')
//       .doc(challenge.id)
//       .set({
//     'completed': false,
//     'completedAt': null,
//   });

//   print("✅ Seeding completed!");
// }
