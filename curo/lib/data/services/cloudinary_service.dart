import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryResult {
  const CloudinaryResult({required this.secureUrl, required this.publicId});
  final String secureUrl;
  final String publicId;
}

class CloudinaryService {
  CloudinaryService({required this.cloudName, required this.uploadPreset});

  final String cloudName;
  final String uploadPreset;

  static const _timeout = Duration(seconds: 60);

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

  /// Uploads a [File] to Cloudinary and returns secure URL + public_id.
  Future<CloudinaryResult> upload(File file, {String? folder}) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = uploadPreset
      ..fields['resource_type'] = 'auto'
      ..fields['folder'] = folder ?? 'curo_reports';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    return _send(request);
  }

  /// Uploads raw [bytes] to Cloudinary (for file_picker / camera bytes).
  Future<CloudinaryResult> uploadBytes(
    Uint8List bytes, {
    String? folder,
    String filename = 'report',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = uploadPreset
      ..fields['resource_type'] = 'auto'
      ..fields['folder'] = folder ?? 'curo_reports';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    return _send(request);
  }

  Future<CloudinaryResult> _send(http.MultipartRequest request) async {
    final streamed = await request.send().timeout(_timeout);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${streamed.statusCode}): $body',
      );
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return CloudinaryResult(
      secureUrl: json['secure_url'] as String,
      publicId: json['public_id'] as String,
    );
  }

  /// Dispatches a destroy request to Cloudinary's media asset endpoint.
  ///
  /// Cloudinary's `/image/destroy` endpoint requires a signed payload
  /// (API key + secret) for authorised deletion. Without a backend proxy the
  /// request will be rejected (401) and the exception is swallowed by the
  /// caller — Firestore cleanup always proceeds regardless.
  Future<void> delete(String publicId) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
      );
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'public_id': publicId, 'invalidate': true}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Non-fatal — repository always removes the Firestore record.
    }
  }
}
