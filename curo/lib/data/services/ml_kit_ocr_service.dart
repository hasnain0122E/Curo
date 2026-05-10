import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitOcrService {
  MlKitOcrService._();

  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts medicine names from a prescription image file.
  /// Returns a list of candidate medicine names (max 10).
  static Future<List<String>> scanPrescription(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(inputImage);
      return _parseMedicineNames(recognized.text);
    } catch (_) {
      return [];
    }
  }

  // Words/patterns that are never medicine names — used to filter OCR noise.
  static final _blocklistPattern = RegExp(
    r'^(dr|mr|mrs|ms|prof|patient|name|age|date|sex|gender|diagnosis|rx|'
    r'twice|thrice|daily|morning|night|evening|after|before|meals|days|weeks|'
    r'bd|tds|qid|od|sos|prn|stat|hs|ac|pc|'
    r'hospital|clinic|pharmacy|lab|laboratory|address|phone|tel|'
    r'cbc|lft|rft|urine|blood|sugar|glucose|hba1c|tsh|ecg|x.?ray|'
    r'fever|infection|hypertension|diabetes|cold|cough|pain|pressure|'
    r'take|use|apply|dissolve|swallow|tablet|capsule|syrup|injection|'
    r'signature|stamp|seal|ref|no\.|#)\b',
    caseSensitive: false,
  );

  static List<String> _parseMedicineNames(String rawText) {
    if (rawText.trim().isEmpty) return [];

    final medicines = <String>[];
    final seen = <String>{};

    final lines = rawText
        .split(RegExp(r'\n|;'))
        .map((l) => l.trim())
        .where((l) => l.length > 2)
        .toList();

    for (final line in lines) {
      // Skip purely numeric/symbolic lines and very long lines
      if (RegExp(r'^[\d\s\.\-\+\/\(\),]+$').hasMatch(line)) continue;
      if (line.length > 60) continue;

      // Must start with a letter (drug names always do)
      if (!RegExp(r'^[A-Za-z]').hasMatch(line)) continue;

      // Skip lines that match known non-medicine patterns
      if (_blocklistPattern.hasMatch(line.trim())) continue;

      String candidate;

      // Prefer lines that contain a dosage strength — most reliable signal
      final dosageMatch = RegExp(
        r'^([A-Za-z][A-Za-z\s\-]+?)\s+\d+\s*(?:mg|ml|mcg|g|iu|units?)',
        caseSensitive: false,
      ).firstMatch(line);

      if (dosageMatch != null) {
        // Keep the name + strength together (e.g. "Augmentin 625mg")
        candidate = line
            .substring(0, dosageMatch.end)
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ');
      } else {
        // No dosage — only accept if it looks like a single-word drug name
        // (multi-word non-dosage lines are usually diagnoses or instructions)
        final words = line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        if (words.length > 2) continue; // too many words without a dosage
        candidate = line.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-]'), '').trim();
      }

      if (candidate.length < 3 || candidate.length > 50) continue;

      // Normalize: capitalize first letter
      candidate = candidate[0].toUpperCase() + candidate.substring(1);

      final key = candidate.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        medicines.add(candidate);
      }

      if (medicines.length >= 10) break;
    }

    return medicines;
  }
}
