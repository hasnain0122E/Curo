import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

// Injected at build time via: flutter run --dart-define-from-file=dart_defines/secrets.json
const _kGroqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
const _kGroqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _kGroqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
const _kRequestTimeout = Duration(seconds: 60);

/// Thrown by [AiVisionService] when preprocessing or a Groq API call fails.
class AiVisionException implements Exception {
  const AiVisionException(this.message);
  final String message;

  @override
  String toString() => 'AiVisionException: $message';
}

/// Low-level vision pipeline: image optimisation + Groq multimodal inference.
///
/// All public feature calls (prescription scan, lab test scan, report analysis)
/// are built on top of the two private primitives defined here.
class AiVisionService {
  // Singleton — callers obtain the instance via [AiVisionService.instance].
  AiVisionService._();
  static final AiVisionService instance = AiVisionService._();

  // ── Key guard ──────────────────────────────────────────────────────────────

  static void _assertGroqKey() {
    if (_kGroqApiKey.isEmpty) {
      throw const AiVisionException(
        'GROQ_API_KEY is not configured. '
        'Add it to dart_defines/secrets.json and run with '
        '--dart-define-from-file=dart_defines/secrets.json.',
      );
    }
  }

  // ── 1. Image preprocessing ─────────────────────────────────────────────────

  /// Converts [rawImage] to grayscale and applies a mild contrast boost so
  /// that faint or overlapping handwritten strokes read more cleanly by the
  /// vision model.
  ///
  /// Writes the result to a temp JPEG and returns the new [File].
  /// Caller is responsible for deleting the temp file after use.
  Future<File> optimizeImageForOcr(File rawImage) async {
    // ── Read raw bytes ───────────────────────────────────────────────────────
    final Uint8List rawBytes;
    try {
      rawBytes = await rawImage.readAsBytes();
    } catch (e) {
      throw AiVisionException('Could not read source image file: $e');
    }

    // ── Decode ───────────────────────────────────────────────────────────────
    img.Image? decoded;
    try {
      decoded = img.decodeImage(rawBytes);
    } catch (e) {
      throw AiVisionException('Image decode failed during preprocessing: $e');
    }

    if (decoded == null) {
      throw AiVisionException(
        'Unsupported image format — decodeImage returned null '
        'for: ${rawImage.path}',
      );
    }

    // ── Grayscale ────────────────────────────────────────────────────────────
    // Removes colour noise from ink bleed, patterned paper, and camera WB
    // shifts that confuse character recognition for Urdu/English scripts.
    final img.Image gray;
    try {
      gray = img.grayscale(decoded);
    } catch (e) {
      throw AiVisionException('Grayscale conversion failed: $e');
    }

    // ── Contrast boost ───────────────────────────────────────────────────────
    // contrast > 1.0 increases contrast; 1.2 is mild — enough to sharpen
    // light pencil or faded printer ink without crushing fine strokes.
    final img.Image enhanced;
    try {
      enhanced = img.adjustColor(gray, contrast: 1.2);
    } catch (e) {
      throw AiVisionException('Contrast adjustment failed: $e');
    }

    // ── Encode & write to temp ───────────────────────────────────────────────
    final Uint8List outputBytes;
    try {
      outputBytes = img.encodeJpg(enhanced, quality: 90);
    } catch (e) {
      throw AiVisionException('JPEG re-encoding failed: $e');
    }

    final File tmpFile = File(
      '${Directory.systemTemp.path}'
      '/curo_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    try {
      await tmpFile.writeAsBytes(outputBytes, flush: true);
    } catch (e) {
      throw AiVisionException(
        'Failed to write preprocessed image to temp directory: $e',
      );
    }

    return tmpFile;
  }

  // ── 2. Groq vision request ─────────────────────────────────────────────────

  /// Sends [processedImage] to Groq's vision endpoint together with
  /// [systemPrompt] and returns the **parsed JSON object** extracted from
  /// `choices[0].message.content`.
  ///
  /// The model is forced into JSON mode via `response_format: json_object`.
  /// [systemPrompt] must therefore instruct the model to reply with JSON or
  /// the API will reject the request.
  Future<Map<String, dynamic>> executeGroqVisionRequest({
    required File processedImage,
    required String systemPrompt,
  }) async {
    _assertGroqKey();

    // ── Read & base64-encode image ────────────────────────────────────────────
    final Uint8List imageBytes;
    try {
      imageBytes = await processedImage.readAsBytes();
    } catch (e) {
      throw AiVisionException('Could not read processed image file: $e');
    }

    final String base64Image = base64Encode(imageBytes);
    final String mimeType = _mimeTypeFor(processedImage.path);

    // ── Build request payload ─────────────────────────────────────────────────
    final Map<String, dynamic> requestBody = {
      'model': _kGroqModel,
      'response_format': {'type': 'json_object'},
      'temperature': 0.1,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
            },
            {
              'type': 'text',
              'text':
                  'Analyze the image and return valid JSON exactly as the '
                  'system prompt specifies. Do not include any prose outside '
                  'the JSON object.',
            },
          ],
        },
      ],
    };

    // ── HTTP POST ─────────────────────────────────────────────────────────────
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_kGroqEndpoint),
            headers: {
              HttpHeaders.authorizationHeader: 'Bearer $_kGroqApiKey',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_kRequestTimeout);
    } on SocketException catch (e) {
      throw AiVisionException('Network error reaching Groq API: $e');
    } on TimeoutException {
      throw AiVisionException(
        'Groq API request timed out after ${_kRequestTimeout.inSeconds}s — '
        'check network connectivity and try again.',
      );
    }

    // ── HTTP error guard ──────────────────────────────────────────────────────
    if (response.statusCode != 200) {
      String detail = '';
      try {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        detail =
            ((errBody['error'] as Map<String, dynamic>?)?['message']
                as String?) ??
            '';
      } catch (_) {
        // If the body is not JSON, surface the raw text for debugging.
        detail = response.body.substring(0, response.body.length.clamp(0, 300));
      }
      throw AiVisionException(
        'Groq API error ${response.statusCode}'
        '${detail.isEmpty ? '' : ': $detail'}',
      );
    }

    // ── Decode outer API envelope ─────────────────────────────────────────────
    final Map<String, dynamic> apiJson;
    try {
      apiJson = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AiVisionException(
        'Failed to decode Groq API response envelope: $e',
      );
    }

    // ── Extract model content ─────────────────────────────────────────────────
    final List<dynamic> choices = (apiJson['choices'] as List<dynamic>?) ?? [];
    if (choices.isEmpty) {
      throw const AiVisionException(
        'Groq API returned a response with no choices.',
      );
    }

    final String? rawContent =
        ((choices.first as Map<String, dynamic>)['message']
                as Map<String, dynamic>?)?['content']
            as String?;

    if (rawContent == null || rawContent.trim().isEmpty) {
      throw const AiVisionException(
        'Groq returned an empty content field in the vision response.',
      );
    }

    // ── Decode inner JSON object ──────────────────────────────────────────────
    try {
      return jsonDecode(rawContent) as Map<String, dynamic>;
    } catch (e) {
      final preview = rawContent.substring(0, rawContent.length.clamp(0, 300));
      throw AiVisionException(
        'Model response was not valid JSON.\n'
        'Preview: $preview\n'
        'Error: $e',
      );
    }
  }

  // ── 3. Domain methods ──────────────────────────────────────────────────────

  /// Extracts ordered diagnostic lab tests from a handwritten prescription.
  ///
  /// Returns a map with top-level key `detected_tests`: a list of
  /// `{test_name: String, confidence_score: 'high'|'medium'|'low'}`.
  Future<Map<String, dynamic>> analyzeLabPrescription(File imageFile) async {
    const systemPrompt =
        "You are an expert medical clerk transcribing handwritten doctor scripts. "
        "Analyze this prescription image. Isolate and extract ONLY the precise "
        "names of diagnostic laboratory tests or diagnostic profiles ordered "
        "(e.g., CBC, HbA1c, Lipid Profile, LFT, Serum Creatinine). Ignore all "
        "patient personal bio-data, clinical metadata, addresses, dates, "
        "signatures, and physical medications. If a test name is scribbled or "
        "written using an Urdu linguistic phonetic style, transcribe its clinical "
        "standard English diagnostic name. Return your response STRICTLY as a "
        "valid JSON object matching this schema blueprint: "
        "{'detected_tests': [{'test_name': 'String', 'confidence_score': 'high|medium|low'}]}";

    final File tmp = await optimizeImageForOcr(imageFile);
    try {
      return await executeGroqVisionRequest(
        processedImage: tmp,
        systemPrompt: systemPrompt,
      );
    } finally {
      // Best-effort cleanup — never throws so it doesn't shadow a real error.
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  /// Extracts medications, dosages, forms, and generic APIs from a handwritten
  /// prescription image.
  ///
  /// Returns a map with top-level key `medications`: a list of
  /// `{brand_name, generic_formula, dosage, form}`.
  Future<Map<String, dynamic>> analyzeMedicinePrescription(
    File imageFile,
  ) async {
    const systemPrompt =
        "You are an expert clinical pharmacologist analyzing handwritten "
        "prescriptions. Extract all written pharmaceutical drugs, even if "
        "scribbled in poor cursive or written using phonetic Urdu subtext. "
        "For each drug, isolate the compound name, precise dosage metric "
        "(e.g., 500mg, 20mg), and administration form (e.g., Tablet, Capsule, "
        "Syrup). You must also accurately derive and isolate the generic chemical "
        "formula name / Active Pharmaceutical Ingredient (API) for each drug. "
        "Return your response STRICTLY as a valid JSON object matching this "
        "schema blueprint: {'medications': [{'brand_name': 'String', "
        "'generic_formula': 'String', 'dosage': 'String', 'form': 'String'}]}";

    final File tmp = await optimizeImageForOcr(imageFile);
    try {
      return await executeGroqVisionRequest(
        processedImage: tmp,
        systemPrompt: systemPrompt,
      );
    } finally {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  /// Parses a printed lab report image into structured per-metric rows with
  /// flag classification and plain-language patient explanations.
  ///
  /// Returns a map with top-level key `report_analysis` containing
  /// `overall_status`, `lab_name`, `patient_friendly_summary`, and `metrics`:
  /// `{parameter, patient_value, reference_range, unit, flag, patient_explanation}`.
  Future<Map<String, dynamic>> parseLabReport(File imageFile) async {
    const systemPrompt =
        "You are a clinical diagnostics data analysis engineer. Analyze this "
        "printed medical lab test report image. Extract: (1) the lab name if "
        "visible on the letterhead (e.g. 'Chughtai Lab', 'Aga Khan', 'Dow Labs'); "
        "(2) every test parameter row — its exact patient result value, standard "
        "reference normal range, and measurement unit; (3) cross-examine each "
        "value against its reference range and flag as 'High', 'Low', or 'Normal'; "
        "(4) a plain-language patient_explanation per parameter; (5) a single "
        "concise patient_friendly_summary (1-2 sentences) describing the overall "
        "health picture in simple terms a non-medical patient can understand. "
        "Return STRICTLY a valid JSON object: "
        "{'report_analysis': {"
        "'overall_status': 'Normal|Requires Attention|Critical Alert', "
        "'lab_name': 'String or empty if not visible', "
        "'patient_friendly_summary': 'String', "
        "'metrics': [{"
        "'parameter': 'String', 'patient_value': 'String', "
        "'reference_range': 'String', 'unit': 'String', "
        "'flag': 'Normal|High|Low', 'patient_explanation': 'String'"
        "}]}}";

    final File tmp = await optimizeImageForOcr(imageFile);
    try {
      return await executeGroqVisionRequest(
        processedImage: tmp,
        systemPrompt: systemPrompt,
      );
    } finally {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _mimeTypeFor(String path) {
    final ext = path.toLowerCase().split('.').last;
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
