import 'dart:typed_data';

/// An image chosen by the user, ready to upload.
class ImageFile {
  const ImageFile(this.bytes, {this.contentType = 'image/jpeg'});
  final Uint8List bytes;

  /// `image/jpeg`, `image/png` or `image/webp`.
  final String contentType;
}

/// Where uploaded pictures live. Implemented with Cloudflare R2 in the data layer.
abstract class ImageStorage {
  /// Uploads [image] and returns its public URL. [kind] is `equipment` or `avatar`.
  Future<String> upload(ImageFile image, {required String kind});
}
