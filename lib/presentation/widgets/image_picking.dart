import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/repositories/image_storage.dart';
import '../../core/theme/app_colors.dart';
import 'ui.dart';

/// Asks camera or gallery, then returns the shrunk image (or `null` if cancelled).
Future<ImageFile?> pickImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(sheet, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(sheet, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  // Re-encoding keeps uploads small (well under the Worker's 5 MB limit).
  final XFile? file;
  try {
    file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 82);
  } catch (e) {
    // e.g. MissingPluginException (app needs a full restart) or no camera/gallery app.
    if (context.mounted) {
      showToast(
          context,
          source == ImageSource.camera
              ? 'Could not open the camera on this device.'
              : 'Could not open the gallery. Restart the app and try again.');
    }
    debugPrint('pickImage failed: $e');
    return null;
  }
  if (file == null) return null;
  final name = file.name.toLowerCase();
  final type = name.endsWith('.png')
      ? 'image/png'
      : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
  return ImageFile(await file.readAsBytes(), contentType: type);
}
