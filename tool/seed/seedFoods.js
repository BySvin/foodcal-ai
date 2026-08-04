#!/usr/bin/env node
// Batch-imports tool/seed/foods_seed.json into the `foods` Firestore
// collection using the Admin SDK (which bypasses security rules, so
// seeded docs can be `isCustom: false` / `createdBy: null` — a shape
// clients are never allowed to write per firestore.rules).
//
// Usage:
//   1. Against the local emulator (recommended first pass):
//        firebase emulators:start --only firestore
//        FIRESTORE_EMULATOR_HOST=localhost:8080 node tool/seed/seedFoods.js
//   2. Against the real project, once tool/seed/serviceAccountKey.json
//      exists (Firebase Console -> Project Settings -> Service Accounts ->
//      Generate new private key). That file is gitignored — never commit it.
//        node tool/seed/seedFoods.js
//
// Re-running is safe: each food's Firestore doc id is a stable slug of its
// name (see foods_seed.json), so this is an idempotent upsert, not an
// append.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const SEED_PATH = path.join(__dirname, 'foods_seed.json');
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const BATCH_SIZE = 400; // Firestore batch writes cap at 500 operations.

function initializeApp() {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log(`Using Firestore emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`);
    admin.initializeApp({ projectId: 'foodcal-ai-emulator' });
    return;
  }

  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(
      `Missing ${SERVICE_ACCOUNT_PATH}.\n` +
        'Download it from Firebase Console -> Project Settings -> Service Accounts -> ' +
        'Generate new private key, or set FIRESTORE_EMULATOR_HOST to seed the emulator instead.'
    );
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
  });
}

async function seed() {
  initializeApp();
  const db = admin.firestore();

  const foods = JSON.parse(fs.readFileSync(SEED_PATH, 'utf-8'));
  console.log(`Seeding ${foods.length} foods into the 'foods' collection...`);

  for (let i = 0; i < foods.length; i += BATCH_SIZE) {
    const chunk = foods.slice(i, i + BATCH_SIZE);
    const batch = db.batch();

    for (const food of chunk) {
      const { id, ...data } = food;
      const ref = db.collection('foods').doc(id);
      batch.set(ref, { ...data, createdAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    }

    await batch.commit();
    console.log(`  committed ${Math.min(i + BATCH_SIZE, foods.length)}/${foods.length}`);
  }

  console.log('Done.');
  process.exit(0);
}

seed().catch((error) => {
  console.error('Seeding failed:', error);
  process.exit(1);
});
