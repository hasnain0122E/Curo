// Seed medicines from medicines_dataset.json into Firestore.
// Run with: node seed_medicines.js  (from inside the scripts/ folder)

const admin = require('firebase-admin');
const fs    = require('fs');

const serviceAccount = require('./curo-healthcare-pk-firebase-adminsdk-fbsvc-501ea384b9.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── Parse the JSON file ───────────────────────────────────────────────────────
// The dataset uses { {...}, {...} } (outer braces, not brackets).
// Replace outer { } with [ ] to get a valid JSON array.
function loadDataset(path) {
  const raw = fs.readFileSync(path, 'utf8').trim();
  const fixed = raw.startsWith('[') ? raw : raw.replace(/^\{/, '[').replace(/\}$/, ']');
  return JSON.parse(fixed);
}

// ── Parse a single medicine row ───────────────────────────────────────────────
function parseMedicine(row) {
  const id   = String(row.id   || '').trim();
  const name = String(row.name || '').trim();
  if (!id || !name) return null;

  const priceBefore = parseInt(row.priceBeforeRs)  || 0;
  const priceAfter  = parseInt(row.priceAfterRs)   || priceBefore;
  const discount    = parseInt(row.discountPercent) || 0;

  return {
    id,
    name,
    nameLower:           name.toLowerCase(),
    genericName:         String(row.genericName  || '').trim(),
    genericNameLower:    String(row.genericName  || '').trim().toLowerCase(),
    manufacturer:        String(row.manufacturer || '').trim(),
    category:            String(row.category     || 'tablet').trim().toLowerCase(),
    description:         String(row.description  || '').trim(),
    strength:            String(row.strength     || '').trim(),
    packSize:            String(row.packSize      || '').trim(),
    available:           Boolean(row.available   ?? true),
    inStock:             Boolean(row.inStock      ?? true),
    prescriptionRequired: Boolean(row.prescriptionRequired ?? false),
    priceBeforeRs:       priceBefore,
    priceAfterRs:        priceAfter > 0 ? priceAfter : priceBefore,
    discountPercent:     discount,
    currency:            String(row.currency || 'PKR').trim(),
    pharmacies:          Array.isArray(row.pharmacies) ? row.pharmacies.map(String) : [],
    usage:               Array.isArray(row.usage)      ? row.usage.map(String)      : [],
    city:                String(row.city    || 'Karachi').trim(),
    country:             String(row.country || 'Pakistan').trim(),
  };
}

// ── Clear + batch-write a collection ─────────────────────────────────────────
async function clearCollection(name) {
  const snap = await db.collection(name).get();
  if (snap.empty) { console.log(`  '${name}' already empty.`); return; }
  console.log(`  Clearing ${snap.size} existing docs...`);
  let batch = db.batch(), n = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref); n++;
    if (n === 499) { await batch.commit(); batch = db.batch(); n = 0; }
  }
  if (n > 0) await batch.commit();
  console.log('  Cleared.');
}

async function batchWrite(items) {
  const total = items.length;
  let batch = db.batch(), count = 0, written = 0;
  for (const item of items) {
    batch.set(db.collection('medicines').doc(item.id), item);
    count++; written++;
    if (count === 499) {
      await batch.commit();
      console.log(`  Written ${written}/${total}...`);
      batch = db.batch(); count = 0;
    }
  }
  if (count > 0) {
    await batch.commit();
    console.log(`  Written ${written}/${total}.`);
  }
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function seed() {
  console.log('\n💊  Loading medicines_dataset.json...');
  const raw = loadDataset('./medicines_dataset.json');
  console.log(`    ${raw.length} raw records.`);

  const seen = new Set();
  const medicines = [];
  for (const row of raw) {
    const parsed = parseMedicine(row);
    if (!parsed) continue;
    if (!seen.has(parsed.id)) { seen.add(parsed.id); medicines.push(parsed); }
  }
  console.log(`    ${medicines.length} unique medicines (${raw.length - medicines.length} duplicates removed).`);

  await clearCollection('medicines');
  console.log(`    Writing ${medicines.length} medicines to Firestore...`);
  await batchWrite(medicines);

  console.log('\n✅  Medicines seeded.');
  console.log('    Medicine finder and prescription scanner are live.');
  process.exit(0);
}

seed().catch(err => {
  console.error('❌ Seeder failed:', err);
  process.exit(1);
});
