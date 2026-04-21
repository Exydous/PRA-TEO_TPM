import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tugas_akhir/services/assistant_service.dart';

class AssistantController extends GetxController {
  var isLoading = false.obs;
  var statusMessage = 'Klik untuk optimasi sesi fotomu'.obs;
  var nearbySpots = <Map<String, dynamic>>[].obs;
  var userLat = 0.0.obs;
  var userLon = 0.0.obs;

  var selectedTimeZone = 'WIB'.obs;
  var rawSunrise = ''.obs; 
  var rawSunset = ''.obs;  

  // Kita gunakan .obs murni (bukan getter) agar UI dijamin 100% ter-refresh!
  var displaySunrise = '--:--'.obs;
  var displaySunset = '--:--'.obs;

  // Fungsi khusus untuk menghitung ulang waktu saat zona waktu diganti
  void updateDisplayedTime() {
    displaySunrise.value = _formatTime(rawSunrise.value);
    displaySunset.value = _formatTime(rawSunset.value);
  }

  String _formatTime(String utcTime) {
    if (utcTime.isEmpty) return '--:--';
    
    try {
      print("INFO API: Waktu asli dari server -> $utcTime"); // Cek isi aslinya
      
      // Deteksi jika API mengembalikan format AM/PM biasa tanpa huruf 'T'
      if (!utcTime.contains('T')) {
        return utcTime; // Langsung tampilkan saja apa adanya
      }

      DateTime dt = DateTime.parse(utcTime).toUtc();
      
      int offset = 7; 
      if (selectedTimeZone.value == 'WITA') offset = 8;
      if (selectedTimeZone.value == 'WIT') offset = 9;
      if (selectedTimeZone.value == 'LONDON') offset = 1; 

      dt = dt.add(Duration(hours: offset));
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      print("❌ ERROR PARSING WAKTU: $e");
      return '--:--';
    }
  }

  Future<void> findBestSetup() async {
    isLoading.value = true;
    statusMessage.value = 'Melacak lokasi & mencari spot terbaik...';

    try {
      Position pos = await _determinePosition();
      userLat.value = pos.latitude;
      userLon.value = pos.longitude;
      
      final service = AssistantService();

      final results = await Future.wait([
        service.getSunData(pos.latitude, pos.longitude),
        service.getNearbyPhotographySpots(pos.latitude, pos.longitude),
      ]);

      final sunData = results[0] as Map<String, String>;
      final spotsData = results[1] as List<Map<String, dynamic>>;

      rawSunrise.value = sunData['sunrise'] ?? '';
      rawSunset.value = sunData['sunset'] ?? '';
      nearbySpots.value = spotsData;
      
      // Panggil fungsi ini agar UI layar langsung diupdate!
      updateDisplayedTime();

      statusMessage.value = 'Rencana memotret siap di lokasimu!';
    } catch (e) {
      statusMessage.value = 'Gagal memuat asisten: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS tidak aktif');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Izin GPS ditolak');
    }
    return await Geolocator.getCurrentPosition();
  }
}