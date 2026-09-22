import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/core/api/api_client.dart';

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
    if (data is String) {
      final s = data.trim();
      if (s.isNotEmpty &&
          s.toLowerCase() != 'null' &&
          s.toLowerCase() != 'undefined' &&
          s != 'assets/img/about-moi-logo.png' &&
          s != '/assets/img/about-moi-logo.png') {
        return s;
      }
      return '';
    }
    if (data is! Map) return '';

    const candidateKeys = [
      'iconUrl',
      'icon_url',
      'iconURL',
      'icon',
      'icons',
      'iconPath',
      'icon_path',
      'appIcon',
      'app_icon',
      'portalAppIcon',
      'portal_app_icon',
      'portalAppIcons',
      'portal_app_icons',
      'imageUrl',
      'image_url',
      'image',
      'images',
      'tileIcon',
      'tile_icon',
      'logo',
      'logos',
      'logoUrl',
      'logo_url',
      'appLogo',
      'app_logo',
      'avatar',
      'avatarUrl',
      'avatar_url',
      'thumbnail',
      'thumbnailUrl',
      'thumbnail_url',
      'picture',
      'pictureUrl',
      'picture_url',
      'badge',
      'badgeUrl',
      'badge_url',
      'file',
      'files',
      'filePath',
      'filepath',
      'fileUrl',
      'file_url',
      'media',
      'mediaUrl',
      'media_url',
      'downloadUrl',
      'download_url',
      'attachment',
      'attachments',
      'link',
      'src',
      'url',
      'path',
    ];

    for (final key in candidateKeys) {
      final val = data[key];
      if (val == null) continue;
      if (val is String) {
        final s = val.trim();
        if (s.isNotEmpty &&
            s.toLowerCase() != 'null' &&
            s.toLowerCase() != 'undefined' &&
            s != 'assets/img/about-moi-logo.png' &&
            s != '/assets/img/about-moi-logo.png') {
          return s;
        }
      } else if (val is Map) {
        final innerRes = extractRawIcon(val);
        if (innerRes.isNotEmpty) return innerRes;
      } else if (val is List && val.isNotEmpty) {
        for (final item in val) {
          final res = extractRawIcon(item);
          if (res.isNotEmpty) return res;
        }
      }
    }

    // Check nested objects
    for (final subKey in [
      'app',
      'portalApp',
      'portal_app',
      'tile',
      'target',
      'application',
      'service',
      'item',
      'raw',
      'data',
      'attributes',
      'properties',
      'metadata',
    ]) {
      final sub = data[subKey];
      if (sub is Map) {
        final res = extractRawIcon(sub);
        if (res.isNotEmpty) return res;
      }
    }

    return '';
  }

  /// Extracts the canonical relative asset path (e.g. "portal-app-icons/xxx.png")
  static String extractRelativePath(dynamic raw) {
    if (raw == null) return '';
    if (raw is Map) {
      final inner = raw['url'] ??
          raw['path'] ??
          raw['filePath'] ??
          raw['filepath'] ??
          raw['iconUrl'] ??
          raw['icon_url'] ??
          raw['fileUrl'] ??
          raw['downloadUrl'] ??
          raw['file'] ??
          raw['name'];
      raw = inner?.toString().trim() ?? '';
    }

    String url = raw.toString().trim().replaceAll('\\', '/');
    if (url.contains('?token=')) {
      url = url.split('?token=').first;
    }
    if (url.isEmpty ||
        url.toLowerCase() == 'null' ||
        url.toLowerCase() == 'undefined' ||
        url == 'assets/img/about-moi-logo.png' ||
        url == '/assets/img/about-moi-logo.png') {
      return '';
    }

    // Ignore local assets
    final lower = url.toLowerCase();
    if (lower.startsWith('assets/') ||
        lower.startsWith('/assets/') ||
        lower.startsWith('images/') ||
        lower.startsWith('/images/')) {
      return '';
    }

    // If it is a completely external domain that has nothing to do with our uploads, return empty
    final bool isInternal = url.contains('core-gateway') ||
        url.contains('127.0.0.1:8080') ||
        url.contains('localhost:8080') ||
        url.contains('172.30.192.253') ||
        url.contains('172.30.192.127') ||
        url.contains('172.30.1.128') ||
        url.contains('/uploads/') ||
        url.contains('uploads/') ||
        url.contains('portal-app-icons') ||
        url.contains('/api/mobile/portals/uploads/');

    if (!isInternal && (url.startsWith('http://') || url.startsWith('https://'))) {
      return '';
    }

    String relative = url;
    if (relative.contains('portal-app-icons/')) {
      relative = 'portal-app-icons/${relative.split('portal-app-icons/').last}';
    } else if (relative.contains('/api/mobile/portals/uploads/')) {
      relative = relative.split('/api/mobile/portals/uploads/').last;
    } else if (relative.contains('/uploads/')) {
      relative = relative.split('/uploads/').last;
    } else if (relative.startsWith('uploads/')) {
      relative = relative.substring('uploads/'.length);
    } else if (isInternal) {
      final uri = Uri.tryParse(relative);
      if (uri != null && uri.path.isNotEmpty) {
        relative = uri.path;
      }
    }

    while (relative.startsWith('api/v1/uploads/')) {
      relative = relative.substring('api/v1/uploads/'.length);
    }
    while (relative.startsWith('api/v1/')) {
      relative = relative.substring('api/v1/'.length);
    }
    while (relative.startsWith('uploads/')) {
      relative = relative.substring('uploads/'.length);
    }
    while (relative.startsWith('/')) {
      relative = relative.substring(1);
    }

    if (!relative.contains('/') &&
        (relative.endsWith('.png') ||
            relative.endsWith('.jpg') ||
            relative.endsWith('.jpeg') ||
            relative.endsWith('.svg') ||
            relative.endsWith('.webp'))) {
      relative = 'portal-app-icons/$relative';
    }

    return relative;
  }

  /// Formats and resolves any icon URL (relative backend upload, external URL, or local asset).
  ///
  /// Automatically appends the user's active access token query parameter (`?token=...`)
  /// so that image loaders and network widgets pass authentication through the BFF gateway.
  static String formatIconUrl(dynamic raw, [String? explicitToken]) {
    if (raw == null) return '';
    if (raw is Map) {
      final inner = raw['url'] ??
          raw['path'] ??
          raw['filePath'] ??
          raw['filepath'] ??
          raw['iconUrl'] ??
          raw['icon_url'] ??
          raw['fileUrl'] ??
          raw['downloadUrl'] ??
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

    // 1. Local asset strings
    final lower = url.toLowerCase();
    if (lower.startsWith('assets/') ||
        lower.startsWith('/assets/') ||
        lower.startsWith('images/') ||
        lower.startsWith('/images/')) {
      return url;
    }

    // 2. Extract relative upload path
    final relativePath = extractRelativePath(url);
    if (relativePath.isEmpty) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      return url;
    }

    // Resolve authentication token
    String? tokenToUse;
    if (explicitToken != null && explicitToken.trim().isNotEmpty) {
      tokenToUse = explicitToken.trim();
    }
    if (tokenToUse == null || tokenToUse.isEmpty) {
      if (ApiClient.currentToken != null && ApiClient.currentToken!.isNotEmpty) {
        tokenToUse = ApiClient.currentToken;
      }
    }
    if (tokenToUse == null || tokenToUse.isEmpty) {
      try {
        final box = GetStorage();
        final stored = (box.read('access_token') ?? box.read('token'))?.toString().trim();
        if (stored != null && stored.isNotEmpty) {
          tokenToUse = stored;
        }
      } catch (_) {}
    }
    if (tokenToUse == null || tokenToUse.isEmpty) {
      if (existingToken.isNotEmpty) {
        tokenToUse = existingToken;
      }
    }
    if (tokenToUse != null && tokenToUse.toLowerCase().startsWith('bearer ')) {
      tokenToUse = tokenToUse.substring(7).trim();
    }
    if (tokenToUse == 'null' ||
        tokenToUse == 'undefined' ||
        tokenToUse == 'mock_dev_token' ||
        tokenToUse == 'mock_admin_token') {
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
      final cleanLower = cleanLocal.toLowerCase();
      final bool isActualLocal = cleanLower.startsWith('assets/') ||
          cleanLower.startsWith('/assets/') ||
          cleanLower.startsWith('images/') ||
          cleanLower.startsWith('/images/');

      // If a specific, valid local asset is specified (other than the default MOI seal and not a web URL)
      if (isActualLocal &&
          cleanLocal != 'assets/img/about-moi-logo.png' &&
          cleanLocal != '/assets/img/about-moi-logo.png') {
        String resolvedLocal = cleanLocal.startsWith('/') ? cleanLocal.substring(1) : cleanLocal;
        if (!resolvedLocal.startsWith('assets/')) {
          resolvedLocal = 'assets/$resolvedLocal';
        }

        if (resolvedLocal.toLowerCase().endsWith('.svg')) {
          return SvgPicture.asset(
            resolvedLocal,
            width: size,
            height: size,
            fit: fit,
          );
        }

        return Image.asset(
          resolvedLocal,
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
        : (ApiClient.currentToken ??
            GetStorage().read('access_token') ??
            GetStorage().read('token'))
            ?.toString();

    String? cleanToken = rawToken?.trim();
    if (cleanToken != null && cleanToken.toLowerCase().startsWith('bearer ')) {
      cleanToken = cleanToken.substring(7).trim();
    }
    if (cleanToken == 'null' ||
        cleanToken == 'undefined' ||
        cleanToken?.isEmpty == true ||
        cleanToken == 'mock_dev_token' ||
        cleanToken == 'mock_admin_token') {
      cleanToken = null;
    }

    final String? cpSession = GetStorage().read('CP_SESSION')?.toString();

    final bool isOwnServer = cleanUrl.contains(ApiConfig.bffHost) ||
        cleanUrl.startsWith(ApiConfig.baseUrl) ||
        cleanUrl.contains('interior.gov.kh') ||
        cleanUrl.contains('172.30.192.253') ||
        cleanUrl.contains('172.30.192.127') ||
        cleanUrl.contains('172.30.1.128');

    // On Web, do not send custom auth headers because custom headers trigger an OPTIONS
    // CORS preflight that the backend rejects with 405 Method Not Allowed.
    // The ?token= query parameter is already attached to cleanUrl for authentication.
    final Map<String, String>? authHeaders = (kIsWeb || !isOwnServer || cleanToken == null)
        ? null
        : {
            'Authorization': 'Bearer $cleanToken',
            if (cpSession != null && cpSession.isNotEmpty) 'Cookie': 'CP_SESSION=$cpSession',
          };

    final String relPath = extractRelativePath(iconUrl);

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
          headers: null,
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (ctx, err, stack) {
            debugPrint("AppIconWidget web failed to load raster image ($cleanUrl): $err");
            return fallbackWidget();
          },
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return fallbackWidget();
          },
        );
      }

      final bool shouldUseDirectGateway = !kIsWeb &&
          ApiConfig.useUat &&
          cleanToken != null &&
          relPath.isNotEmpty &&
          !cleanUrl.contains('172.30.192.253');

      final String primaryImageUrl = shouldUseDirectGateway
          ? 'http://172.30.192.253:8080/api/v1/uploads/$relPath'
          : cleanUrl;

      final Map<String, String>? primaryHeaders = shouldUseDirectGateway
          ? {
              'Authorization': 'Bearer $cleanToken',
              if (cpSession != null && cpSession.isNotEmpty) 'Cookie': 'CP_SESSION=$cpSession',
            }
          : authHeaders;

      return CachedNetworkImage(
        imageUrl: primaryImageUrl,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.high,
        httpHeaders: primaryHeaders,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => fallbackWidget(),
        errorWidget: (context, url, error) {
          debugPrint("AppIconWidget failed to load raster image ($primaryImageUrl): $error");
          // Fallback to the alternative URL if primary failed
          final fallbackImageUrl = shouldUseDirectGateway ? cleanUrl : (relPath.isNotEmpty ? 'http://172.30.192.253:8080/api/v1/uploads/$relPath' : '');
          if (!kIsWeb && cleanToken != null && fallbackImageUrl.isNotEmpty && fallbackImageUrl != primaryImageUrl) {
            return CachedNetworkImage(
              imageUrl: fallbackImageUrl,
              width: size,
              height: size,
              fit: fit,
              filterQuality: FilterQuality.high,
              httpHeaders: {
                'Authorization': 'Bearer $cleanToken',
                if (cpSession != null && cpSession.isNotEmpty) 'Cookie': 'CP_SESSION=$cpSession',
              },
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (ctx, u) => fallbackWidget(),
              errorWidget: (ctx, errUrl, err) {
                debugPrint("AppIconWidget secondary fallback also failed ($fallbackImageUrl): $err");
                return fallbackWidget();
              },
            );
          }
          return fallbackWidget();
        },
      );
    }

    return fallbackWidget();
  }
}
