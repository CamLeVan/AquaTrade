import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Component hiển thị hình ảnh thông minh:
/// Hỗ trợ mượt mà HTTP/HTTPS (Cloudinary), Base64 (Data URI), Asset local,
/// và tự động fallback icon thủy sản khi ảnh lỗi hoặc URL rỗng (tránh vỡ UI đỏ).
class AppSmartImage extends StatelessWidget {
  const AppSmartImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final url = _resolveUrl(imageUrl);
    final asset = assetPath?.trim();

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        try {
          final commaIndex = url.indexOf(',');
          if (commaIndex != -1) {
            final base64Str = url.substring(commaIndex + 1);
            final bytes = base64Decode(base64Str);
            return Image.memory(
              Uint8List.fromList(bytes),
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => _buildPlaceholder(),
            );
          }
        } catch (_) {
          return _buildPlaceholder();
        }
      }

      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      }

      if (url.startsWith('assets/')) {
        return Image.asset(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      }
    }

    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  String? _resolveUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.contains('via.placeholder.com')) return null;
    return trimmed;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;

    return Image.network(
      'https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?w=800&auto=format&fit=crop&q=80',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: AppColors.imagePlaceholder,
        child: SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: Icon(
              Icons.set_meal,
              size: 32,
              color: AppColors.primary30,
            ),
          ),
        ),
      ),
    );
  }
}
