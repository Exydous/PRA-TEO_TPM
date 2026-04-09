import 'dart:convert';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class AssistantController extends GetxController {
  var isLoading = false.obs;
  var statusMessage = 'Klik untuk optimasi sesi fotomu'.obs;

  // Data Golden Hour
  var sunrise = '--:--'.obs;
  var sunset = '--:--'.obs;

  // Data Spot Foto (API Google Places)
  var nearbySpots = <dynamic>[].obs;
  
  // PENTING: Ganti dengan API Key Google Maps kamu agar Spot Finder aktif
  final String googleApiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  Future<void> findBestSetup() async {
    isLoading.value = true;
    statusMessage.value = 'Melacak lokasi & mencari spot terbaik...';

    try {
      // 1. Cek Izin & Ambil Lokasi (LBS)
      Position pos = await _determinePosition();
      
      // 2. Jalankan dua API secara paralel
      await Future.wait([
        _fetchSunData(pos.latitude, pos.longitude),
        _fetchNearbyPlaces(pos.latitude, pos.longitude),
      ]);

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

  Future<void> _fetchSunData(double lat, double lng) async {
    final res = await http.get(Uri.parse('https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&formatted=0'));
    if (res.statusCode == 200) {
      var data = json.decode(res.body)['results'];
      sunrise.value = _formatToLocal(data['sunrise']);
      sunset.value = _formatToLocal(data['sunset']);
    }
  }

  Future<void> _fetchNearbyPlaces(double lat, double lng) async {
    // Mencari taman (park) dan tempat wisata (tourist_attraction) radius 3km
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=3000&type=park&key=$googleApiKey';
    
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      var data = json.decode(res.body);
      nearbySpots.value = data['results']; 
    }
  }

  String _formatToLocal(String utcTime) {
    DateTime dt = DateTime.parse(utcTime).toLocal();
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}