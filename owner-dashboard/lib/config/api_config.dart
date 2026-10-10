import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => validateBaseUrl(
        _configuredBaseUrl,
        isRelease: kReleaseMode,
      );

  @visibleForTesting
  static String validateBaseUrl(
    String value, {
    required bool isRelease,
  }) {
    final configuredUrl = value.trim();
    if (configuredUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is required. Supply it with --dart-define=API_BASE_URL=<url>.',
      );
    }

    final uri = Uri.tryParse(configuredUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'API_BASE_URL must be an absolute HTTP or HTTPS URL without credentials, query, or fragment.',
      );
    }

    final isLoopback = _isLoopbackHost(uri.host);
    if (isRelease && (uri.scheme != 'https' || isLoopback)) {
      throw StateError(
        'Release builds require a deployed HTTPS API_BASE_URL; loopback and HTTP URLs are not allowed.',
      );
    }

    final normalizedPath = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    return uri.replace(path: normalizedPath).toString();
  }

  static bool _isLoopbackHost(String host) {
    var normalizedHost = host.toLowerCase();
    if (normalizedHost.startsWith('[') && normalizedHost.endsWith(']')) {
      normalizedHost = normalizedHost.substring(1, normalizedHost.length - 1);
    }
    final zoneIndex = normalizedHost.indexOf('%');
    if (zoneIndex >= 0) {
      normalizedHost = normalizedHost.substring(0, zoneIndex);
    }
    normalizedHost = normalizedHost.replaceFirst(RegExp(r'\.+$'), '');

    if (normalizedHost == 'localhost' ||
        normalizedHost.endsWith('.localhost')) {
      return true;
    }

    final ipv4 = _parseIpv4(normalizedHost);
    if (ipv4 != null && ipv4[0] == 127) {
      return true;
    }

    final ipv6 = _parseIpv6(normalizedHost);
    if (ipv6 == null) {
      return false;
    }

    final isIpv6Loopback =
        ipv6.take(7).every((part) => part == 0) && ipv6[7] == 1;
    final isIpv4Mapped =
        ipv6.take(5).every((part) => part == 0) && ipv6[5] == 0xffff;
    final mappedIpv4Loopback = isIpv4Mapped && (ipv6[6] >> 8) == 127;
    return isIpv6Loopback || mappedIpv4Loopback;
  }

  static List<int>? _parseIpv4(String address) {
    final octets = address.split('.');
    if (octets.length != 4) {
      return null;
    }

    final parsed = <int>[];
    for (final octet in octets) {
      if (!RegExp(r'^\d{1,3}$').hasMatch(octet)) {
        return null;
      }
      final value = int.tryParse(octet);
      if (value == null || value > 255) {
        return null;
      }
      parsed.add(value);
    }
    return parsed;
  }

  static List<int>? _parseIpv6(String address) {
    if (!address.contains(':')) {
      return null;
    }

    var normalizedAddress = address;
    if (normalizedAddress.contains('.')) {
      final lastColon = normalizedAddress.lastIndexOf(':');
      if (lastColon < 0) {
        return null;
      }
      final ipv4 = _parseIpv4(normalizedAddress.substring(lastColon + 1));
      if (ipv4 == null) {
        return null;
      }
      final firstWord = (ipv4[0] << 8) | ipv4[1];
      final secondWord = (ipv4[2] << 8) | ipv4[3];
      normalizedAddress = '${normalizedAddress.substring(0, lastColon + 1)}'
          '${firstWord.toRadixString(16)}:${secondWord.toRadixString(16)}';
    }

    final compressionIndex = normalizedAddress.indexOf('::');
    if (compressionIndex >= 0 &&
        compressionIndex != normalizedAddress.lastIndexOf('::')) {
      return null;
    }

    List<int>? parseGroups(String side) {
      if (side.isEmpty) {
        return <int>[];
      }
      final groups = <int>[];
      for (final group in side.split(':')) {
        if (!RegExp(r'^[0-9a-f]{1,4}$').hasMatch(group)) {
          return null;
        }
        final value = int.tryParse(group, radix: 16);
        if (value == null) {
          return null;
        }
        groups.add(value);
      }
      return groups;
    }

    if (compressionIndex < 0) {
      final groups = parseGroups(normalizedAddress);
      return groups != null && groups.length == 8 ? groups : null;
    }

    final left = parseGroups(normalizedAddress.substring(0, compressionIndex));
    final right = parseGroups(normalizedAddress.substring(compressionIndex + 2));
    if (left == null || right == null || left.length + right.length >= 8) {
      return null;
    }
    return <int>[
      ...left,
      ...List<int>.filled(8 - left.length - right.length, 0),
      ...right,
    ];
  }

  static void validate() {
    baseUrl;
  }
}
