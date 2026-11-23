import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';
import '../../domain/repositories/image_storage.dart';

/// Base URL of the upload Worker (see `worker/`). Set with
/// `--dart-define=UPLOAD_URL=https://ntiza-uploads.<account>.workers.dev`.
const uploadBaseUrl = String.fromEnvironment('UPLOAD_URL');

/// Stores images in Cloudflare R2 through the upload Worker, which checks the
/// caller's Firebase ID token. No R2 credentials live in the app.
class R2ImageStorage implements ImageStorage {
  R2ImageStorage(this._auth, {http.Client? client, String baseUrl = uploadBaseUrl})
      : _http = client ?? http.Client(),
        _baseUrl = baseUrl;

  final FirebaseAuth _auth;
  final http.Client _http;
  final String _baseUrl;

  @override
  Future<String> upload(ImageFile image, {required String kind}) async {
    if (_baseUrl.isEmpty) {
      throw const AppException('Photo upload is not configured (missing UPLOAD_URL).');
    }
    String? token;
    try {
      token = await _auth.currentUser?.getIdToken();
    } catch (_) {
      // Stale session (e.g. the emulator was reset): the user must sign in again.
      throw const AppException('Your session expired. Please log out and log in again.');
    }
    if (token == null) throw const AppException('Please log in again.');
    try {
      final res = await _http
          .put(
            Uri.parse('$_baseUrl/upload').replace(queryParameters: {'kind': kind}),
            headers: {'authorization': 'Bearer $token', 'content-type': image.contentType},
            body: image.bytes,
          )
          .timeout(const Duration(seconds: 60));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['url'] is String) return body['url'] as String;
      throw AppException((body['error'] as String?) ?? 'Photo upload failed. Please try again.');
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('Could not upload the photo. Check your connection.');
    }
  }
}
