import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class TDKService {
  static const String _baseUrl = 'https://sozluk.gov.tr/gts';

  // Yaygın Türkçe kelimeler listesi (TDK API'den alınacak)
  static final List<String> _commonWords = [
    'kitap', 'kalem', 'masa', 'sandalye', 'pencere',
    'kapı', 'araba', 'telefon', 'bilgisayar', 'televizyon',
    'buzdolabı', 'çamaşır', 'mutfak', 'banyo', 'yatak',
    'salon', 'bahçe', 'çiçek', 'ağaç', 'kuş',
    'kedi', 'köpek', 'balık', 'at', 'inek',
    'tavuk', 'yumurta', 'süt', 'ekmek', 'peynir',
    'domates', 'biber', 'soğan', 'patates', 'havuç',
    'elma', 'armut', 'portakal', 'muz', 'üzüm',
    'okul', 'öğretmen', 'öğrenci', 'sınıf', 'tahta',
    'defter', 'silgi', 'cetvel', 'çanta', 'ayakkabı',
    'gömlek', 'pantolon', 'etek', 'ceket', 'şapka',
    'güneş', 'ay', 'yıldız', 'bulut', 'yağmur',
    'kar', 'rüzgar', 'deniz', 'göl', 'nehir',
    'dağ', 'orman', 'çöl', 'ada', 'köprü',
    'hastane', 'doktor', 'hemşire', 'ilaç', 'eczane',
    'market', 'kasap', 'manav', 'fırın', 'pastane',
    'restoran', 'kafe', 'otel', 'havalimanı', 'otogar',
    'tren', 'otobüs', 'uçak', 'gemi', 'bisiklet',
    'futbol', 'basketbol', 'voleybol', 'tenis', 'yüzme',
    'müzik', 'resim', 'sinema', 'tiyatro', 'konser',
  ];

  /// TDK'dan kelime doğrulama
  static Future<bool> validateWord(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?ara=${Uri.encodeComponent(word)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // TDK API'de kelime bulunursa liste döner
        return data is List && data.isNotEmpty;
      }
      return false;
    } catch (e) {
      // API hatası durumunda yerel listeden kontrol
      return _commonWords.contains(word.toLowerCase());
    }
  }

  /// TDK'dan kelime anlamı al
  static Future<String?> getWordMeaning(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?ara=${Uri.encodeComponent(word)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final meanings = data[0]['anlamlarListe'] as List?;
          if (meanings != null && meanings.isNotEmpty) {
            return meanings[0]['anlam'] as String?;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Rastgele kelime öner
  static Future<List<String>> getSuggestedWords({int count = 5}) async {
    final random = Random();
    final suggestions = <String>[];
    final shuffled = List<String>.from(_commonWords)..shuffle(random);

    for (int i = 0; i < count && i < shuffled.length; i++) {
      suggestions.add(shuffled[i]);
    }

    return suggestions;
  }

  /// Kelime zorluk seviyesi (harf sayısına göre)
  static String getWordDifficulty(String word) {
    if (word.length <= 4) return 'Kolay';
    if (word.length <= 7) return 'Orta';
    return 'Zor';
  }
}
