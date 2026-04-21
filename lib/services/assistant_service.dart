import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_keys.dart'; 

class AssistantService {
  
  // --- 1. FUNGSI API SUNRISE-SUNSET (DIUPDATE UNTUK ZONA WAKTU) ---
  Future<Map<String, String>> getSunData(double lat, double lng) async {
    try {
      final res = await http.get(Uri.parse('https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&formatted=0'));
      if (res.statusCode == 200) {
        var data = json.decode(res.body)['results'];
        return {
          // Mengirim waktu mentah (UTC) ke Controller dan mencegah error format dynamic
          'sunrise': data['sunrise'].toString(), 
          'sunset': data['sunset'].toString(),   
        };
      }
      return {'sunrise': '', 'sunset': ''};
    } catch (e) {
      print("❌ ERROR API SUNRISE: $e"); 
      return {'sunrise': '', 'sunset': ''};
    }
  }

  // --- 2. FUNGSI API GEOAPIFY (Pengganti Google Places) ---
  Future<List<Map<String, dynamic>>> getNearbyPhotographySpots(double lat, double lon) async {
    // Menggunakan kategori Induk (Top-Level) agar dijamin 100% aman
    const String categories = "tourism,natural,leisure";
    const int radiusMeter = 20000; // Radius besar 20 KM
    
    // 1. CEK API KEY SEBELUM JALAN
    final String apiKey = ApiKeys.geoapifyKey;
    if (apiKey.isEmpty) {
      print("🚨 ERROR: API Key Geoapify KOSONG! Pastikan .env sudah terbaca.");
      return [];
    }

    final String url = 
        "https://api.geoapify.com/v2/places?categories=$categories&filter=circle:$lon,$lat,$radiusMeter&bias=proximity:$lon,$lat&limit=15&apiKey=$apiKey";

    // 2. CETAK URL KE CONSOLE UNTUK DICEK
    print("🌍 MENGHUBUNGI GEOAPIFY: $url");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> features = data['features'];
        
        // 3. Olah data mentah dari API
        var rawSpots = features.map((f) {
          final props = f['properties'];
          
          String safeCategory = 'Umum';
          if (props['categories'] != null && props['categories'].isNotEmpty) {
            safeCategory = props['categories'][0].toString().split('.').last;
          }

          return {
            'name': props['name'] ?? props['street'], // Dibiarkan null jika kosong
            'category': safeCategory,
            'address': props['formatted'] ?? 'Alamat tidak tersedia',
            'distance': props['distance'] ?? 0, 
            'lat': props['lat'],
            'lon': props['lon'],
          };
        }).toList();

        // 4. FILTER EKSTRA KETAT: Buang semua data yang namanya null
        var cleanSpots = rawSpots.where((spot) => spot['name'] != null).toList();
        
        print("✅ SUKSES! Ditemukan ${cleanSpots.length} spot foto bernama.");
        
        return cleanSpots;
        
      } else {
        print("❌ GAGAL! Status Code: ${response.statusCode}");
        print("❌ Alasan: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ ERROR KONEKSI: $e");
      return [];
    }
  }
}