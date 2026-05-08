// Seed medicines from Excel dataset into Firestore.
// Run with: node seed_medicines.js  (from inside the scripts/ folder)
// Requires: npm install firebase-admin xlsx

const admin = require('firebase-admin');
const XLSX  = require('xlsx');

const serviceAccount = require('./curo-healthcare-pk-firebase-adminsdk-fbsvc-501ea384b9.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── Parse a single row ────────────────────────────────────────────────────────

function parseRow(row) {
  const name = String(row.Name || '').trim();
  if (!name) return null;

  const manufacturer = String(row.Company || '').trim();

  // Some rows have a pack-size value shifted into the Availability column
  let packSize    = String(row.Pack_Size    || '').trim();
  let availRaw    = String(row.Availability || '').trim();
  let available   = true;

  if (availRaw === 'Available')  { available = true;  }
  else if (availRaw === 'Sold Out') { available = false; }
  else if (availRaw !== '' && !packSize) {
    // Availability column actually contains the pack size
    packSize  = availRaw;
    available = true;
  }

  const priceBefore = parseInt(String(row.Price_before || '').replace(/[^0-9]/g, '')) || 0;
  const priceAfter  = parseInt(String(row.Price_After  || '').replace(/[^0-9]/g, '')) || priceBefore;

  const discountMatch   = String(row.Discount || '').match(/(\d+)/);
  const discountPercent = discountMatch ? parseInt(discountMatch[1]) : 0;

  return {
    name,
    nameLower: name.toLowerCase(),
    manufacturer,
    packSize: packSize.replace(/^\s+/, ''),
    priceBeforeRs: priceBefore,
    priceAfterRs:  priceAfter > 0 ? priceAfter : priceBefore,
    discountPercent,
    available,
  };
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function seed() {
  const wb    = XLSX.readFile('./medicines_dataset.xlsx');
  const sheet = wb.Sheets[wb.SheetNames[0]];
  const rows  = XLSX.utils.sheet_to_json(sheet, { defval: '' });

  // Deduplicate by name + manufacturer + packSize
  const seen      = new Set();
  const medicines = [];
  for (const row of rows) {
    const parsed = parseRow(row);
    if (!parsed) continue;
    const key = `${parsed.nameLower}|${parsed.manufacturer.toLowerCase()}|${parsed.packSize.toLowerCase()}`;
    if (!seen.has(key)) { seen.add(key); medicines.push(parsed); }
  }

  console.log(`Parsed ${medicines.length} unique medicines (${rows.length} raw rows).`);

  // Delete existing medicines
  const existing = await db.collection('medicines').get();
  if (!existing.empty) {
    console.log(`Deleting ${existing.size} existing medicines...`);
    let batch = db.batch(); let n = 0;
    for (const doc of existing.docs) {
      batch.delete(doc.ref); n++;
      if (n === 500) { await batch.commit(); batch = db.batch(); n = 0; }
    }
    if (n > 0) await batch.commit();
  }

  // Write in batches of 500
  let batch = db.batch(); let count = 0; let total = 0;
  for (const med of medicines) {
    batch.set(db.collection('medicines').doc(), med);
    count++; total++;
    if (count === 500) {
      await batch.commit();
      console.log(`  Written ${total}/${medicines.length}...`);
      batch = db.batch(); count = 0;
    }
  }
  if (count > 0) await batch.commit();

  console.log(`✅ Seeded ${medicines.length} medicines from dataset`);
  process.exit(0);
}

seed().catch(err => { console.error(err); process.exit(1); });
