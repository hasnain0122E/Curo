// Seed medicines from JSON dataset into Firestore.
// Run with: node seed_medicines.js  (from inside the scripts/ folder)

const admin = require('firebase-admin');
const fs    = require('fs');

const serviceAccount = require('./curo-healthcare-pk-firebase-adminsdk-fbsvc-501ea384b9.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── Parse a single row ────────────────────────────────────────────────────────

function parseRow(row) {
  const name = String(row['Name'] || '').trim();
  if (!name) return null;

  const manufacturer = String(row['Company'] || '').trim();
  const packSize     = String(row['Pack_Size'] || '').trim();
  const availRaw     = String(row['Availability'] || '').trim().toLowerCase();
  const available    = availRaw === 'available';

  const priceBefore = parseInt(String(row['Price_before'] || '').replace(/[^0-9]/g, '')) || 0;
  const priceAfter  = Math.round(parseFloat(row['Price_After'] || 0)) || priceBefore;

  const discountMatch   = String(row['Discount'] || '').match(/(\d+)/);
  const discountPercent = discountMatch ? parseInt(discountMatch[1]) : 0;

  return {
    name,
    nameLower:       name.toLowerCase(),
    manufacturer,
    packSize,
    priceBeforeRs:   priceBefore,
    priceAfterRs:    priceAfter > 0 ? priceAfter : priceBefore,
    discountPercent,
    available,
  };
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function seed() {
  // Load JSON dataset
  const raw = JSON.parse(fs.readFileSync('./medicines_dataset.json', 'utf8'));
  console.log(`Loaded ${raw.length} raw records from JSON.`);

  // Deduplicate by name + manufacturer + packSize
  const seen      = new Set();
  const medicines = [];
  for (const row of raw) {
    const parsed = parseRow(row);
    if (!parsed) continue;
    const key = `${parsed.nameLower}|${parsed.manufacturer.toLowerCase()}|${parsed.packSize.toLowerCase()}`;
    if (!seen.has(key)) { seen.add(key); medicines.push(parsed); }
  }

  console.log(`Unique medicines after dedup: ${medicines.length} (removed ${raw.length - medicines.length} duplicates).`);

  // Delete existing medicines collection
  const existing = await db.collection('medicines').get();
  if (!existing.empty) {
    console.log(`Clearing ${existing.size} existing documents...`);
    let batch = db.batch(); let n = 0;
    for (const doc of existing.docs) {
      batch.delete(doc.ref); n++;
      if (n === 499) { await batch.commit(); batch = db.batch(); n = 0; }
    }
    if (n > 0) await batch.commit();
    console.log('  Existing data cleared.');
  }

  // Write in batches of 499
  let batch = db.batch(); let count = 0; let total = 0;
  for (const med of medicines) {
    batch.set(db.collection('medicines').doc(), med);
    count++; total++;
    if (count === 499) {
      await batch.commit();
      console.log(`  Written ${total}/${medicines.length}...`);
      batch = db.batch(); count = 0;
    }
  }
  if (count > 0) {
    await batch.commit();
    console.log(`  Written ${total}/${medicines.length}...`);
  }

  console.log(`\n✅  Seeded ${medicines.length} medicines into Firestore.`);
  console.log('    Medicine finder and prescription scanner are now live for all users.');
  process.exit(0);
}

seed().catch(err => { console.error('❌ Seeder failed:', err); process.exit(1); });
