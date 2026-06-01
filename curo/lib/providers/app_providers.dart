import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/lab_repository.dart';
import '../data/repositories/medicine_repository.dart';
import '../data/repositories/pharmacy_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/services/cloudinary_service.dart';
import '../data/services/firestore_seeder.dart';
import '../data/services/location_service.dart';

// ── Firebase singletons ───────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final db = FirebaseFirestore.instance;
  // Seed labs + pharmacies on first launch (per-collection, no-op if present)
  FirestoreSeeder.seedIfEmpty(db).catchError((Object e) {
    // ignore: avoid_print
    print('[FirestoreSeeder] ⚠️  Seed failed: $e');
  });
  return db;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

// ── Cloudinary ────────────────────────────────────────────────────────────────

final cloudinaryProvider = Provider<CloudinaryService>(
  (ref) =>
      CloudinaryService(cloudName: 'dzzeotvf7', uploadPreset: 'curo_reports'),
);

// ── Repositories ──────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  ),
);

final labRepositoryProvider = Provider<LabRepository>(
  (ref) => LabRepository(firestore: ref.watch(firestoreProvider)),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(
    firestore: ref.watch(firestoreProvider),
    cloudinary: ref.watch(cloudinaryProvider),
  ),
);

final medicineRepositoryProvider = Provider<MedicineRepository>(
  (ref) => MedicineRepository(firestore: ref.watch(firestoreProvider)),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(firestore: ref.watch(firestoreProvider)),
);

final pharmacyRepositoryProvider = Provider<PharmacyRepository>(
  (ref) => PharmacyRepository(firestore: ref.watch(firestoreProvider)),
);

// ── Auth state stream ─────────────────────────────────────────────────────────

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Watches the current user's Firestore document.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return authAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authRepositoryProvider).watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (e, s) => Stream.value(null),
  );
});

// ── Location ──────────────────────────────────────────────────────────────────

/// Fetches device GPS position once. Returns null if permission is denied.
final userLocationProvider = FutureProvider.autoDispose<Position?>((ref) async {
  return LocationService.getCurrentPosition();
});
