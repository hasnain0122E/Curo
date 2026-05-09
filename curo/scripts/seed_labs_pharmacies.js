// Seed labs and pharmacies from JSON files into Firestore.
// Run from the scripts/ folder:  node seed_labs_pharmacies.js

const admin = require('firebase-admin');
const fs    = require('fs');

const serviceAccount = require('./curo-healthcare-pk-firebase-adminsdk-fbsvc-501ea384b9.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Converts openingHours to a display string.
 * Accepts: a string, an object {monday: "...", ...}, or null/undefined.
 */
function toHoursString(hours, is24h) {
  if (is24h) return 'Open 24 Hours';
  if (!hours) return 'Mon–Sat: 8AM–8PM';
  if (typeof hours === 'string') return hours.trim();

  // Object with day keys
  const vals = Object.values(hours).filter(Boolean);
  if (vals.length === 0) return 'Mon–Sat: 8AM–8PM';

  const allSame = vals.every(v => v === vals[0]);
  if (allSame) return vals[0];

  const wdHours = hours['monday'] || hours['Monday'] || '';
  const weHours = hours['saturday'] || hours['Saturday'] || '';
  if (wdHours && weHours && wdHours !== weHours) {
    return `Mon–Fri: ${wdHours}, Sat–Sun: ${weHours}`;
  }
  return wdHours || vals[0];
}

async function clearCollection(name) {
  const snap = await db.collection(name).get();
  if (snap.empty) { console.log(`  Collection '${name}' already empty.`); return; }
  console.log(`  Clearing ${snap.size} existing '${name}' docs...`);
  let batch = db.batch(), n = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref); n++;
    if (n === 499) { await batch.commit(); batch = db.batch(); n = 0; }
  }
  if (n > 0) await batch.commit();
  console.log(`  Cleared.`);
}

async function batchWrite(collectionName, items) {
  const total = items.length;
  let batch = db.batch(), count = 0, written = 0;
  for (const item of items) {
    const docId = item.id;
    batch.set(db.collection(collectionName).doc(docId), item);
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

// ── Lab parser ────────────────────────────────────────────────────────────────

function parseLab(row) {
  const id = String(row.id || '').trim();
  if (!id || !row.name || row.lat == null || row.lng == null) return null;

  return {
    id,
    name:            String(row.name).trim(),
    address:         String(row.address || '').trim(),
    area:            String(row.area    || '').trim(),
    city:            String(row.city    || '').trim(),
    country:         String(row.country || 'Pakistan').trim(),
    lat:             Number(row.lat),
    lng:             Number(row.lng),
    rating:          Number(row.rating)      || 0,
    reviewCount:     parseInt(row.reviewCount) || 0,
    startingPriceRs: parseInt(row.startingPriceRs) || 0,
    openingHours:    toHoursString(row.openingHours, row.is24Hours),
    phone:           String(row.phone   || '').trim(),
    website:         String(row.website || '').trim(),
    is24Hours:       Boolean(row.is24Hours),
    tests:           Array.isArray(row.tests) ? row.tests.map(String) : [],
  };
}

// ── Pharmacy parser ───────────────────────────────────────────────────────────

function parsePharmacy(row) {
  const id = String(row.id || '').trim();
  if (!id || !row.name || row.lat == null || row.lng == null) return null;

  return {
    id,
    name:         String(row.name).trim(),
    address:      String(row.address || '').trim(),
    area:         String(row.area    || '').trim(),
    city:         String(row.city    || '').trim(),
    country:      String(row.country || 'Pakistan').trim(),
    lat:          Number(row.lat),
    lng:          Number(row.lng),
    rating:       Number(row.rating)        || 0,
    reviewCount:  parseInt(row.reviewCount) || 0,
    openingHours: toHoursString(row.openingHours, row.is24Hours),
    phone:        String(row.phone   || '').trim(),
    website:      String(row.website || '').trim(),
    is24Hours:    Boolean(row.is24Hours),
    services:     Array.isArray(row.services) ? row.services.map(String) : [],
  };
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function seed() {

  // ── Labs ──────────────────────────────────────────────────────────────────
  console.log('\n🔬  Loading labs_data.json...');
  const rawLabs = JSON.parse(fs.readFileSync('./labs_data.json', 'utf8'));
  // Accept flat array or { labs: [...] }
  const labsRaw = Array.isArray(rawLabs) ? rawLabs : (rawLabs.labs || []);
  console.log(`    ${labsRaw.length} raw records.`);

  const labsSeen = new Set();
  const labs = [];
  for (const row of labsRaw) {
    const parsed = parseLab(row);
    if (!parsed) continue;
    if (!labsSeen.has(parsed.id)) { labsSeen.add(parsed.id); labs.push(parsed); }
  }
  console.log(`    ${labs.length} unique labs (${labsRaw.length - labs.length} duplicates removed).`);

  await clearCollection('labs');
  console.log(`    Writing ${labs.length} labs to Firestore...`);
  await batchWrite('labs', labs);
  console.log('✅  Labs seeded.\n');

  // ── Pharmacies ────────────────────────────────────────────────────────────
  console.log('💊  Loading pharmacies_data.json...');
  const rawPharm = JSON.parse(fs.readFileSync('./pharmacies_data.json', 'utf8'));
  // Accept flat array or { pharmacies: [...] }
  const pharmRaw = Array.isArray(rawPharm) ? rawPharm : (rawPharm.pharmacies || []);
  console.log(`    ${pharmRaw.length} raw records.`);

  const pharmSeen = new Set();
  const pharmacies = [];
  for (const row of pharmRaw) {
    const parsed = parsePharmacy(row);
    if (!parsed) continue;
    if (!pharmSeen.has(parsed.id)) { pharmSeen.add(parsed.id); pharmacies.push(parsed); }
  }
  console.log(`    ${pharmacies.length} unique pharmacies (${pharmRaw.length - pharmacies.length} duplicates removed).`);

  await clearCollection('pharmacies');
  console.log(`    Writing ${pharmacies.length} pharmacies to Firestore...`);
  await batchWrite('pharmacies', pharmacies);
  console.log('✅  Pharmacies seeded.\n');

  console.log('🎉  All done! Labs and pharmacies are live in Firestore.');
  console.log('    The app will load real data on next launch.');
  process.exit(0);
}

seed().catch(err => {
  console.error('❌  Seeder failed:', err);
  process.exit(1);
});
