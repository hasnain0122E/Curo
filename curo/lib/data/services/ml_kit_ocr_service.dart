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
      // Skip lines that are purely numeric/symbolic or too long
      if (RegExp(r'^[\d\s\.\-\+\/\(\),]+$').hasMatch(line)) continue;
      if (line.length > 80) continue;

      // Try to extract medicine name from line with dosage info
      final dosageMatch = RegExp(
        r'^([A-Za-z][A-Za-z\s\-]+?)\s+\d+\s*(?:mg|ml|mcg|g|iu|units?)',
        caseSensitive: false,
      ).firstMatch(line);

      String candidate;
      if (dosageMatch != null) {
        candidate = dosageMatch.group(1)!.trim();
      } else {
        // Accept lines that look like medicine names (start with a letter)
        if (!RegExp(r'^[A-Za-z]').hasMatch(line)) continue;
        candidate = line.replaceAll(RegExp(r'[^a-zA-Z\s\-]'), '').trim();
      }

      if (candidate.length < 3 || candidate.length > 50) continue;

      // Normalize: capitalize first letter only
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
