import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/api_config.dart';

class AppIconWidget extends StatelessWidget {
  final String iconUrl;
  final String localAsset;
  final String? token;
  final double size;
  final BoxFit fit;
  final IconData? fallbackIcon;
  final Color? fallbackColor;

  const AppIconWidget({
    super.key,
    required this.iconUrl,
    this.localAsset = 'assets/img/about-moi-logo.png',
    this.token,
    this.size = 44,
    this.fit = BoxFit.contain,
    this.fallbackIcon,
    this.fallbackColor,
  });

  /// Safely extracts the raw icon candidate from an app Map or dynamic object.
  static String extractRawIcon(dynamic data) {
    if (data == null) return '';
    if (data is String) return data.trim();
    if (data is! Map) return '';

    final candidate = data['iconUrl'] ??
        data['icon_url'] ??
        data['iconURL'] ??
        data['icon'] ??
        data['iconPath'] ??
        data['icon_path'] ??
        data['appIcon'] ??
        data['app_icon'] ??
        data['imageUrl'] ??
        data['image_url'] ??
        data['image'] ??
        data['tileIcon'] ??
        data['tile_icon'] ??
        data['logo'] ??
        data['logoUrl'] ??
        data['logo_url'] ??
        data['avatar'] ??
        data['file'] ??
        data['filePath'] ??
        data['filepath'];

    if (candidate == null) return '';
    if (candidate is String) return candidate.trim();
    if (candidate is Map) {
      final inner = candidate['url'] ??
          candidate['path'] ??
          candidate['filePath'] ??
          candidate['filepath'] ??
          candidate['file'] ??
          candidate['iconUrl'] ??
          candidate['name'];
      return inner?.toString().trim() ?? '';
    }
    return candidate.toString().trim();
  }

  /// Formats and resolves any icon URL (relative backend upload, external URL, or local asset).
  static String formatIconUrl(dynamic raw, [String? explicitToken]) {
    if (raw == null) return '';
    if (raw is Map) {
      final inner = raw['url'] ??
          raw['path'] ??
          raw['filePath'] ??
          raw['filepath'] ??
          raw['iconUrl'] ??
          raw['file'] ??
          raw['name'];
      raw = inner?.toString().trim() ?? '';
    }

    String url = raw.toString().trim();
    url = url.replaceAll('\\', '/');

    if (url.isEmpty ||
        url.toLowerCase() == 'null' ||
        url.toLowerCase() == 'undefined' ||
        url == 'assets/img/about-moi-logo.png' ||
        url == '/assets/img/about-moi-logo.png') {
      return '';
    }

    String existingToken = '';
    if (url.contains('?token=')) {
      final parts = url.split('?token=');
      url = parts.first;
      if (parts.length > 1) {
        existingToken = parts[1].split('&').first;
      }
    }

    if (url == 'assets/img/about-moi-logo.png' ||
        url == '/assets/img/about-moi-logo.png') {
      return '';
    }

    // 1. Local asset strings
    final lower = url.toLowerCase();
    if (lower.startsWith('assets/') ||
        lower.startsWith('asset/') ||
        lower.startsWith('/assets/') ||
        lower.startsWith('/asset/') ||
        lower.startsWith('images/') ||
        lower.startsWith('/images/')) {
      return url;
    }

    // 2. Check if this is an internal gateway or uploaded static icon from backend
    final bool isInternalGateway = url.contains('core-gateway') ||
        url.contains('127.0.0.1:8080') ||
        url.contains('localhost:8080');

    final bool isUpload = isInternalGateway ||
        url.contains('/uploads/') ||
        url.contains('uploads/') ||
        url.contains('portal-app-icons') ||
        url.contains('/api/mobile/portals/uploads/');

    // If it is a purely external URL (not our upload server/gateway), return as-is
    if (!isUpload && (url.startsWith('http://') || url.startsWith('https://'))) {
      return url;
    }

    // 3. Resolve backend upload path
    // Examples:
    // - "portal-app-icons/anpr-xxx.png"
    // - "/uploads/portal-app-icons/anpr-xxx.png"
    // - "http://core-gateway:8080/uploads/portal-app-icons/anpr-xxx.png"
    String relativePath = url;

    if (relativePath.contains('portal-app-icons/')) {
      relativePath = 'portal-app-icons/${relativePath.split('portal-app-icons/').last}';
    } else if (relativePath.contains('/api/mobile/portals/uploads/')) {
      relativePath = relativePath.split('/api/mobile/portals/uploads/').last;
    } else if (relativePath.contains('/uploads/')) {
      relativePath = relativePath.split('/uploads/').last;
    } else if (relativePath.startsWith('uploads/')) {
      relativePath = relativePath.substring('uploads/'.length);
    } else if (isInternalGateway) {
      final uri = Uri.tryParse(relativePath);
      if (uri != null && uri.path.isNotEmpty) {
        relativePath = uri.path;
      }
    }

    if (relativePath.startsWith('api/v1/uploads/')) {
      relativePath = relativePath.substring('api/v1/uploads/'.length);
    } else if (relativePath.startsWith('api/v1/')) {
      relativePath = relativePath.substring('api/v1/'.length);
    }

    while (relativePath.startsWith('/')) {
      relativePath = relativePath.substring(1);
    }

    // Resolve authentication token
    String? tokenToUse = explicitToken?.trim();
    if (tokenToUse == null || tokenToUse.isEmpty) {
      if (existingToken.isNotEmpty) {
        tokenToUse = existingToken;
      } else {
        try {
          final box = GetStorage();
          tokenToUse = (box.read('access_token') ?? box.read('token'))?.toString().trim();
        } catch (_) {}
      }
    }
    if (tokenToUse != null && tokenToUse.toLowerCase().startsWith('bearer ')) {
      tokenToUse = tokenToUse.substring(7).trim();
    }
    if (tokenToUse == 'null' ||
        tokenToUse == 'undefined' ||
        tokenToUse == 'mock_dev_token') {
      tokenToUse = null;
    }

    final String tokenQuery = (tokenToUse != null && tokenToUse.isNotEmpty)
        ? '?token=$tokenToUse'
        : '';

    return '${ApiConfig.baseUrl}/api/mobile/portals/uploads/$relativePath$tokenQuery';
  }

  @override
  Widget build(BuildContext context) {
    Widget fallbackWidget() {
      if (fallbackIcon != null) {
        return Icon(
          fallbackIcon,
          size: size * 0.6,
          color: fallbackColor ?? const Color(0xFF1D4ED8),
        );
      }

      final cleanLocal = localAsset.trim();
      // If a specific, valid local asset is specified (other than the default MOI seal and not a web URL)
      if (cleanLocal.isNotEmpty &&
          !cleanLocal.startsWith('http://') &&
          !cleanLocal.startsWith('https://') &&
          cleanLocal != 'assets/img/about-moi-logo.png' &&
          cleanLocal != '/assets/img/about-moi-logo.png') {
        if (cleanLocal.toLowerCase().endsWith('.svg')) {
          return SvgPicture.asset(
            cleanLocal,
            width: size,
            height: size,
            fit: fit,
          );
        }

        return Image.asset(
          cleanLocal,
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (ctx, err, stack) => Icon(
            Icons.grid_view_rounded,
            size: size * 0.6,
            color: fallbackColor ?? const Color(0xFF1D4ED8),
          ),
        );
      }

      // Default clean app grid icon
      return Icon(
        Icons.grid_view_rounded,
        size: size * 0.6,
        color: fallbackColor ?? const Color(0xFF1D4ED8),
      );
    }

    final cleanUrl = formatIconUrl(iconUrl, token);
    if (cleanUrl.isEmpty) {
      return fallbackWidget();
    }

    // Fall back to stored session token if not explicitly passed
    final rawToken = (token != null && token!.trim().isNotEmpty)
        ? token!.trim()
        : (GetStorage().read('token') ?? GetStorage().read('access_token'))?.toString();

    String? cleanToken = rawToken?.trim();
    if (cleanToken != null && cleanToken.toLowerCase().startsWith('bearer ')) {
      cleanToken = cleanToken.substring(7).trim();
    }
    if (cleanToken == 'null' ||
        cleanToken == 'undefined' ||
        cleanToken?.isEmpty == true ||
        cleanToken == 'mock_dev_token') {
      cleanToken = null;
    }

    final String? cpSession = GetStorage().read('CP_SESSION')?.toString();

    final bool isOwnServer = cleanUrl.contains(ApiConfig.bffHost) ||
        cleanUrl.startsWith(ApiConfig.baseUrl) ||
        cleanUrl.contains('interior.gov.kh');

    final Map<String, String>? authHeaders = (isOwnServer && (cleanToken != null || cpSession != null))
        ? {
            if (cleanToken != null) 'Authorization': 'Bearer $cleanToken',
            'Cookie': 'CP_SESSION=${cpSession ?? cleanToken}',
          }
        : null;

    // 1. Local Asset String
    final cleanLower = cleanUrl.toLowerCase();
    final bool isLocal = cleanLower.startsWith('assets/') ||
        cleanLower.startsWith('asset/') ||
        cleanLower.startsWith('/assets/') ||
        cleanLower.startsWith('/asset/') ||
        cleanLower.startsWith('images/') ||
        cleanLower.startsWith('/images/');

    if (isLocal) {
      String resolvedAsset = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
      if (!resolvedAsset.startsWith('assets/')) {
        resolvedAsset = 'assets/$resolvedAsset';
      }

      if (resolvedAsset.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          resolvedAsset,
          width: size,
          height: size,
          fit: fit,
          placeholderBuilder: (_) => fallbackWidget(),
        );
      }
      return Image.asset(
        resolvedAsset,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (ctx, err, stack) => fallbackWidget(),
      );
    }

    // 2. SVG Network URL
    if (cleanUrl.toLowerCase().contains('.svg')) {
      return SvgPicture.network(
        cleanUrl,
        width: size,
        height: size,
        fit: fit,
        headers: authHeaders,
        placeholderBuilder: (_) => fallbackWidget(),
      );
    }

    // 3. Raster Network Image (PNG / JPEG / WebP / etc.)
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      if (kIsWeb) {
        return Image.network(
          cleanUrl,
          headers: authHeaders,
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (ctx, err, stack) => fallbackWidget(),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return fallbackWidget();
          },
        );
      }

      return CachedNetworkImage(
        imageUrl: cleanUrl,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.high,
        httpHeaders: authHeaders,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => fallbackWidget(),
        errorWidget: (context, url, error) {
          debugPrint("AppIconWidget failed to load raster image ($cleanUrl): $error");
          return fallbackWidget();
        },
      );
    }

    return fallbackWidget();
  }
}
