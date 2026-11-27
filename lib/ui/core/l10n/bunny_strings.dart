import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BunnyLanguageOption {
  const BunnyLanguageOption({
    required this.code,
    required this.nativeName,
    required this.englishKey,
    this.isRtl = false,
  });

  final String code;
  final String nativeName;
  final String englishKey;
  final bool isRtl;
}

class BunnyStrings {
  BunnyStrings._();

  static const List<BunnyLanguageOption> supportedLanguages = [
    BunnyLanguageOption(
      code: 'en',
      nativeName: 'English',
      englishKey: 'English',
    ),
    BunnyLanguageOption(
      code: 'ar',
      nativeName: 'العربية',
      englishKey: 'Arabic',
      isRtl: true,
    ),
    BunnyLanguageOption(
      code: 'es',
      nativeName: 'Español',
      englishKey: 'Spanish',
    ),
    BunnyLanguageOption(
      code: 'fr',
      nativeName: 'Français',
      englishKey: 'French',
    ),
    BunnyLanguageOption(
      code: 'id',
      nativeName: 'Bahasa Indonesia',
      englishKey: 'Indonesian',
    ),
    BunnyLanguageOption(
      code: 'ms',
      nativeName: 'Bahasa Melayu',
      englishKey: 'Malaysian / Malay',
    ),
    BunnyLanguageOption(
      code: 'pt',
      nativeName: 'Português',
      englishKey: 'Portuguese',
    ),
    BunnyLanguageOption(
      code: 'vi',
      nativeName: 'Tiếng Việt',
      englishKey: 'Vietnamese',
    ),
  ];

  static final Map<String, Map<String, String>> _cache = {};
  static String _currentCode = 'en';

  static String get currentCode => _currentCode;
  static bool get isRtl => _currentCode == 'ar';
  static Locale get currentLocale => Locale(_currentCode);

  static Future<void> load(String languageCode) async {
    final code = supportedLanguages.any((l) => l.code == languageCode)
        ? languageCode
        : 'en';
    if (!_cache.containsKey('en')) {
      await _loadFile('en');
    }
    if (!_cache.containsKey(code)) {
      await _loadFile(code);
    }
    _currentCode = code;
  }

  static Future<void> _loadFile(String code) async {
    try {
      final raw = await rootBundle.loadString('assets/l10n/$code.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache[code] = decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _cache[code] = {};
    }
  }

  /// Resolves an Apple Localizable.strings key and substitutes %@ / %lld args.
  static String t(String key, [List<Object> args = const []]) {
    final map = _cache[_currentCode];
    final fallback = _cache['en'];
    String value = map?[key] ?? fallback?[key] ?? key;

    if (args.isNotEmpty) {
      int index = 0;
      value = value.replaceAllMapped(
        RegExp(r'(%@|%lld|%d|%\d+\$@|%\d+\$lld)'),
        (m) {
          final token = m.group(0)!;
          final posMatch = RegExp(r'%(\d+)\$').firstMatch(token);
          if (posMatch != null) {
            final pos = int.parse(posMatch.group(1)!) - 1;
            if (pos >= 0 && pos < args.length) return args[pos].toString();
          }
          if (index < args.length) {
            return args[index++].toString();
          }
          return token;
        },
      );
    }
    return value.replaceAll('%%', '%');
  }
}
