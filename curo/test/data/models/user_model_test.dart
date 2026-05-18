import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curo/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_snapshot.dart';

void main() {
  final baseDate = DateTime(2024, 1, 15);

  // ── name getter ────────────────────────────────────────────────────────────

  group('UserModel.name', () {
    test('returns full name when both parts provided', () {
      final user = UserModel(
        uid: 'u1',
        firstName: 'Ali',
        lastName: 'Khan',
        createdAt: baseDate,
      );
      expect(user.name, 'Ali Khan');
    });

    test('returns only firstName when lastName is null', () {
      final user = UserModel(
        uid: 'u1',
        firstName: 'Ali',
        createdAt: baseDate,
      );
      expect(user.name, 'Ali');
    });

    test('returns only lastName when firstName is null', () {
      final user = UserModel(
        uid: 'u1',
        lastName: 'Khan',
        createdAt: baseDate,
      );
      expect(user.name, 'Khan');
    });

    test('returns empty string when both parts are null', () {
      final user = UserModel(uid: 'u1', createdAt: baseDate);
      expect(user.name, '');
    });

    test('ignores empty string parts', () {
      final user = UserModel(
        uid: 'u1',
        firstName: '',
        lastName: 'Khan',
        createdAt: baseDate,
      );
      expect(user.name, 'Khan');
    });
  });

  // ── fromFirestore ──────────────────────────────────────────────────────────

  group('UserModel.fromFirestore', () {
    test('parses all fields correctly', () {
      final ts = Timestamp.fromDate(baseDate);
      final doc = FakeDoc('uid123', {
        'firstName': 'Fatima',
        'lastName': 'Ahmed',
        'phone': '+923001234567',
        'email': 'fatima@example.com',
        'createdAt': ts,
      });

      final user = UserModel.fromFirestore(doc);

      expect(user.uid, 'uid123');
      expect(user.firstName, 'Fatima');
      expect(user.lastName, 'Ahmed');
      expect(user.phone, '+923001234567');
      expect(user.email, 'fatima@example.com');
      expect(user.createdAt, baseDate);
    });

    test('handles null optional fields gracefully', () {
      final doc = FakeDoc('uid456', {
        'createdAt': Timestamp.fromDate(baseDate),
      });

      final user = UserModel.fromFirestore(doc);

      expect(user.uid, 'uid456');
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
      expect(user.phone, isNull);
      expect(user.email, isNull);
    });

    test('falls back to DateTime.now() when createdAt is missing', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final doc = FakeDoc('uid789', <String, dynamic>{});
      final user = UserModel.fromFirestore(doc);
      final after = DateTime.now().add(const Duration(seconds: 1));

      expect(user.createdAt.isAfter(before), isTrue);
      expect(user.createdAt.isBefore(after), isTrue);
    });
  });

  // ── toFirestore ────────────────────────────────────────────────────────────

  group('UserModel.toFirestore', () {
    test('includes all non-null fields', () {
      final user = UserModel(
        uid: 'u1',
        firstName: 'Ali',
        lastName: 'Khan',
        phone: '+923000000000',
        email: 'ali@example.com',
        createdAt: baseDate,
      );

      final map = user.toFirestore();

      expect(map['uid'], 'u1');
      expect(map['firstName'], 'Ali');
      expect(map['lastName'], 'Khan');
      expect(map['phone'], '+923000000000');
      expect(map['email'], 'ali@example.com');
      expect(map['createdAt'], Timestamp.fromDate(baseDate));
    });

    test('excludes null optional fields from output map', () {
      final user = UserModel(uid: 'u1', createdAt: baseDate);
      final map = user.toFirestore();

      expect(map.containsKey('firstName'), isFalse);
      expect(map.containsKey('lastName'), isFalse);
      expect(map.containsKey('phone'), isFalse);
      expect(map.containsKey('email'), isFalse);
    });
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  group('UserModel.copyWith', () {
    final original = UserModel(
      uid: 'u1',
      firstName: 'Ali',
      lastName: 'Khan',
      phone: '+920000000000',
      email: 'ali@example.com',
      createdAt: baseDate,
    );

    test('updates specified fields', () {
      final updated = original.copyWith(firstName: 'Hassan', email: 'h@x.com');
      expect(updated.firstName, 'Hassan');
      expect(updated.email, 'h@x.com');
    });

    test('preserves unchanged fields', () {
      final updated = original.copyWith(firstName: 'Hassan');
      expect(updated.uid, 'u1');
      expect(updated.lastName, 'Khan');
      expect(updated.phone, '+920000000000');
      expect(updated.createdAt, baseDate);
    });
  });
}
