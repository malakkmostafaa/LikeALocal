/**
 * Migration script: move `reviews` array from places documents
 * into a `places/{placeId}/reviews` subcollection.
 *
 * Usage:
 * 1. Place a Firebase service account JSON at the repo root (or set env var)
 *    and set GOOGLE_APPLICATION_CREDENTIALS to its path, or pass the path as
 *    first arg to this script.
 * 2. Run: `node scripts/migrate_reviews.js [path/to/serviceAccount.json]`
 *
 * The script will:
 * - Iterate all documents in `places`.
 * - For documents with a non-empty `reviews` array, it will create documents under
 *   `places/{placeId}/reviews` for each review object.
 * - Remove the `reviews` field from the original place document.
 */

const admin = require('firebase-admin');
const fs = require('fs');

async function main() {
  const keyPath = process.argv[2] || process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (!keyPath || !fs.existsSync(keyPath)) {
    console.error('Service account JSON path required as arg or GOOGLE_APPLICATION_CREDENTIALS set.');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
  });

  const db = admin.firestore();

  const placesSnap = await db.collection('places').get();
  console.log(`Found ${placesSnap.size} places`);

  let migratedCount = 0;

  for (const doc of placesSnap.docs) {
    const data = doc.data();
    const reviews = data.reviews;

    if (!reviews || !Array.isArray(reviews) || reviews.length === 0) continue;

    console.log(`Migrating ${reviews.length} reviews for place ${doc.id} (${data.name})`);

    const batch = db.batch();

    for (const review of reviews) {
      const rref = db.collection('places').doc(doc.id).collection('reviews').doc();
      const newReview = Object.assign({}, review, { createdAt: admin.firestore.FieldValue.serverTimestamp() });
      batch.set(rref, newReview);
    }

    // remove the field
    batch.update(db.collection('places').doc(doc.id), { reviews: admin.firestore.FieldValue.delete() });

    await batch.commit();
    migratedCount += 1;
  }

  console.log(`Migration done. ${migratedCount} place documents migrated.`);
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(2);
});
