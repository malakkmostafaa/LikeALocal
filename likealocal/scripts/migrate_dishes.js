/**
 * Migration script: move `recommendedDishes` array from places documents
 * into a `places/{placeId}/dishes` subcollection.
 *
 * Usage:
 * 1. Place a Firebase service account JSON at the repo root (or set env var)
 *    and set GOOGLE_APPLICATION_CREDENTIALS to its path, or pass the path as
 *    first arg to this script.
 * 2. Run: `node scripts/migrate_dishes.js [path/to/serviceAccount.json]`
 *
 * The script will:
 * - Iterate all documents in `places`.
 * - For documents with a non-empty `recommendedDishes` array and a food category
 *   (Cafe/Restaurant/Food), it will create documents under
 *   `places/{placeId}/dishes` for each dish object.
 * - Remove the `recommendedDishes` field from the original place document.
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

  // categories considered food-related (keep in sync with app)
  const foodCategories = new Set(['Food', 'Restaurant', 'Cafe']);

  const placesSnap = await db.collection('places').get();
  console.log(`Found ${placesSnap.size} places`);

  let migratedCount = 0;

  for (const doc of placesSnap.docs) {
    const data = doc.data();
    const cat = data.category;
    const rec = data.recommendedDishes;

    if (!rec || !Array.isArray(rec) || rec.length === 0) continue;
    if (!foodCategories.has(cat)) continue;

    console.log(`Migrating ${rec.length} dishes for place ${doc.id} (${data.name})`);

    const batch = db.batch();

    for (const dish of rec) {
      const dref = db.collection('places').doc(doc.id).collection('dishes').doc();
      const newDish = Object.assign({}, dish, { createdAt: admin.firestore.FieldValue.serverTimestamp() });
      batch.set(dref, newDish);
    }

    // remove the field
    batch.update(db.collection('places').doc(doc.id), { recommendedDishes: admin.firestore.FieldValue.delete() });

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
