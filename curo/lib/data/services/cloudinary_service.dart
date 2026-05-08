import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Uploads files to Cloudinary using unsigned upload preset.
/// Free tier: 25 GB storage, 25 GB bandwidth/month — no credit card required.
///
/// Setup:
///  1. Create free account at cloudinary.com
///  2. Dashboard → Settings → Upload → Add upload preset → set to "Unsigned"
///  3. Copy cloudName, uploadPreset and paste below
class CloudinaryService {
  CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
  });

  final String cloudName;
  final String uploadPreset;

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

  /// Uploads [file] and returns the secure download URL.
  /// [folder] organises files under a path (e.g. "reports/uid123").
  Future<String> upload(File file, {String? folder}) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = uploadPreset
      ..fields['resource_type'] = 'auto'
      ..fields['folder'] = folder ?? 'curo_reports';

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${streamed.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  /// Deletes a file by its public_id (extracted from the URL).
  /// NOTE: deletion from client requires a signed request — for a course
  /// project this is left as a no-op; files are cleaned up server-side.
  Future<void> delete(String url) async {
    // No-op for unsigned preset (deletion needs signed API key).
    // In production, call a Cloud Function that signs the delete request.
  }
}
