import 'package:flutter_riverpod/flutter_riverpod.dart';

class LabTestScanNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void setTests(List<String> tests) => state = tests;

  void removeTest(int index) {
    final list = [...state];
    list.removeAt(index);
    state = list;
  }

  void clear() => state = [];
}

final labTestScanProvider = NotifierProvider<LabTestScanNotifier, List<String>>(
  LabTestScanNotifier.new,
);
