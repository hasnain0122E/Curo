// Run with: node scripts/seed_firestore.js
// Requires: npm install firebase-admin  (run once in the scripts/ folder)
//
// Get serviceAccountKey.json from:
// Firebase Console → Project Settings → Service Accounts → Generate new private key

const admin = require('firebase-admin');
const serviceAccount = require('./curo-healthcare-pk-firebase-adminsdk-fbsvc-501ea384b9.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Labs ─────────────────────────────────────────────────────────────────────

const labs = [
  {
    id: 'lab_001',
    name: 'Apollo Diagnostics',
    address: 'Block 7, Gulshan-e-Iqbal, Karachi',
    lat: 24.9200, lng: 67.0900,
    rating: 4.8, reviewCount: 312,
    startingPriceRs: 450,
    openingHours: 'Mon–Sat: 7AM–10PM',
    tests: ['CBC', 'Blood Sugar', 'Lipid Profile', 'TSH', 'Urine R/E'],
  },
  {
    id: 'lab_002',
    name: 'Chughtai Lab',
    address: 'Main Boulevard, Gulberg III, Lahore',
    lat: 31.5204, lng: 74.3587,
    rating: 4.7, reviewCount: 840,
    startingPriceRs: 350,
    openingHours: 'Mon–Sun: 6AM–11PM',
    tests: ['CBC', 'HbA1c', 'Liver Function', 'Kidney Function', 'ECG'],
  },
  {
    id: 'lab_003',
    name: 'Excel Labs',
    address: 'F-8 Markaz, Islamabad',
    lat: 33.7077, lng: 73.0479,
    rating: 4.6, reviewCount: 527,
    startingPriceRs: 400,
    openingHours: 'Mon–Sat: 7AM–9PM',
    tests: ['CBC', 'Blood Sugar', 'X-Ray', 'MRI', 'Ultrasound'],
  },
  {
    id: 'lab_004',
    name: 'Dr. Essa Laboratory',
    address: 'Saddar, Karachi',
    lat: 24.8607, lng: 67.0400,
    rating: 4.5, reviewCount: 203,
    startingPriceRs: 300,
    openingHours: 'Mon–Sat: 8AM–8PM',
    tests: ['CBC', 'Blood Sugar', 'Thyroid Panel', 'Hepatitis B/C'],
  },
  {
    id: 'lab_005',
    name: 'Aga Khan Lab',
    address: 'Stadium Road, Karachi',
    lat: 24.8901, lng: 67.0652,
    rating: 4.9, reviewCount: 1240,
    startingPriceRs: 600,
    openingHours: 'Mon–Sun: 24 hours',
    tests: ['CBC', 'Metabolic Panel', 'Tumour Markers', 'Genetic Tests', 'ECG'],
  },
];

// ── Medicines ─────────────────────────────────────────────────────────────────

const medicines = [
  { name: 'Panadol', genericName: 'Paracetamol', manufacturer: 'GSK', priceRs: 30, available: true, dosageForm: 'Tablet', strength: '500mg' },
  { name: 'Brufen', genericName: 'Ibuprofen', manufacturer: 'Abbott', priceRs: 45, available: true, dosageForm: 'Tablet', strength: '400mg' },
  { name: 'Augmentin', genericName: 'Amoxicillin + Clavulanate', manufacturer: 'GSK', priceRs: 320, available: true, dosageForm: 'Tablet', strength: '625mg' },
  { name: 'Flagyl', genericName: 'Metronidazole', manufacturer: 'Sanofi', priceRs: 60, available: true, dosageForm: 'Tablet', strength: '400mg' },
  { name: 'Amoxil', genericName: 'Amoxicillin', manufacturer: 'GSK', priceRs: 85, available: true, dosageForm: 'Capsule', strength: '500mg' },
  { name: 'Glucophage', genericName: 'Metformin', manufacturer: 'Merck', priceRs: 110, available: true, dosageForm: 'Tablet', strength: '500mg' },
  { name: 'Lipitor', genericName: 'Atorvastatin', manufacturer: 'Pfizer', priceRs: 280, available: true, dosageForm: 'Tablet', strength: '20mg' },
  { name: 'Zantac', genericName: 'Ranitidine', manufacturer: 'GSK', priceRs: 55, available: true, dosageForm: 'Tablet', strength: '150mg' },
  { name: 'Risek', genericName: 'Omeprazole', manufacturer: 'Searle', priceRs: 90, available: true, dosageForm: 'Capsule', strength: '20mg' },
  { name: 'Ventolin', genericName: 'Salbutamol', manufacturer: 'GSK', priceRs: 120, available: true, dosageForm: 'Syrup', strength: '2mg/5ml' },
  { name: 'Disprin', genericName: 'Aspirin', manufacturer: 'Reckitt', priceRs: 25, available: true, dosageForm: 'Tablet', strength: '300mg' },
  { name: 'Novaclox', genericName: 'Ampicillin + Cloxacillin', manufacturer: 'Novartis', priceRs: 95, available: true, dosageForm: 'Capsule', strength: '500mg' },
  { name: 'Calpol', genericName: 'Paracetamol', manufacturer: 'GSK', priceRs: 40, available: true, dosageForm: 'Syrup', strength: '120mg/5ml' },
  { name: 'Dermovate', genericName: 'Clobetasol', manufacturer: 'GSK', priceRs: 180, available: true, dosageForm: 'Tablet', strength: '0.05%' },
  { name: 'Ponstan', genericName: 'Mefenamic Acid', manufacturer: 'Pfizer', priceRs: 65, available: true, dosageForm: 'Capsule', strength: '250mg' },
];

async function seed() {
  const batch = db.batch();

  // Seed labs
  for (const lab of labs) {
    const { id, ...data } = lab;
    batch.set(db.collection('labs').doc(id), data);
  }

  // Seed medicines with lowercase search fields
  for (const med of medicines) {
    const ref = db.collection('medicines').doc();
    batch.set(ref, {
      ...med,
      nameLower: med.name.toLowerCase(),
      genericNameLower: med.genericName.toLowerCase(),
    });
  }

  await batch.commit();
  console.log(`✅ Seeded ${labs.length} labs and ${medicines.length} medicines`);
  process.exit(0);
}

seed().catch(err => { console.error(err); process.exit(1); });
