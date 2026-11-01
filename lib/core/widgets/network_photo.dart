import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fills its parent with a network photo; shows a mint placeholder while
/// loading or if the image is missing/fails.
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({super.key, required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.mint,
      child: Center(
        child: Icon(Icons.agriculture_outlined, color: AppColors.green, size: 32),
      ),
    );
    final u = url;
    if (u == null || u.isEmpty) return placeholder;

    return Image.network(
      u,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
