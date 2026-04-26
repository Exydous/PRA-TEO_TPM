import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tugas_akhir/services/assistant_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart'; // Ditambahkan untuk widget Color di Snackbar

class AssistantController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var statusMessage = 'Klik untuk optimasi sesi fotomu'.obs;
  var nearbySpots = <Map<String, dynamic>>[].obs;
  var userLat = 0.0.obs;
  var userLon = 0.0.obs;
  var routePoints = <LatLng>[].obs;

  // Filter Radius sesuai strategi baru (5-15 KM)
  var selectedRadius = 5.0.obs; 
  final List<double> radiusOptions = [5, 10, 15];

  var selectedTimeZone = 'WIB'.obs;
  var rawSunrise = ''.obs; 
  var rawSunset = ''.obs;  

  var displaySunrise = '--:--'.obs;
  var displaySunset = '--:--'.obs;

  void updateDisplayedTime() {
    displaySunrise.value = _formatTime(rawSunrise.value);
    displaySunset.value = _formatTime(rawSunset.value);
  }

  String _formatTime(String utcTime) {
    if (utcTime.isEmpty) return '--:--';
    try {
      if (!utcTime.contains('T')) return utcTime; 
      DateTime dt = DateTime.parse(utcTime).toUtc();
      
      int offset = 7; 
      if (selectedTimeZone.value == 'WITA') offset = 8;
      if (selectedTimeZone.value == 'WIT') offset = 9;
      if (selectedTimeZone.value == 'LONDON') offset = 1; 

      dt = dt.add(Duration(hours: offset));
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '--:--';
    }
  }

  Future<void> findBestSetup() async {
    isLoading.value = true;
    statusMessage.value = 'Mencari spot dalam radius ${selectedRadius.value.toInt()} km...';

    try {
      Position pos = await _determinePosition();
      userLat.value = pos.latitude;
      userLon.value = pos.longitude;
      
      final service = AssistantService();

      // Menjalankan pencarian matahari dan spot foto dari Supabase secara bersamaan
      final results = await Future.wait<dynamic>([
        service.getSunData(pos.latitude, pos.longitude),
        supabase.rpc('get_photo_spots_within_radius', params: {
          'user_lat': pos.latitude,
          'user_lng': pos.longitude,
          'radius_km': selectedRadius.value,
        }),
      ]);

      final sunData = results[0] as Map<String, String>;
      final List<dynamic> spotsData = results[1];

      rawSunrise.value = sunData['sunrise'] ?? '';
      rawSunset.value = sunData['sunset'] ?? '';
      
      // Menyesuaikan koordinat latitude/longitude dari tabel ke format peta (lat/lon)
      nearbySpots.value = spotsData.map<Map<String, dynamic>>((e) => {
        ...e as Map<String, dynamic>,
        'lat': e['latitude'], 
        'lon': e['longitude'],
      }).toList();
      
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

  Future<void> getRouteToSpot(double destLat, double destLon) async {
    if (userLat.value == 0.0 || userLon.value == 0.0) return;
    
    // Hapus rute lama jika ada
    routePoints.clear();
    
    try {
      // API OSRM gratis. Format koordinatnya: longitude,latitude
      final String url = "http://router.project-osrm.org/route/v1/driving/${userLon.value},${userLat.value};$destLon,$destLat?geometries=geojson";
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];
        
        // [DIPERBAIKI] Ubah koordinat JSON menjadi format LatLng dengan tipe data yang sangat spesifik
        routePoints.value = coordinates.map<LatLng>((coord) {
          return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
        }).toList();
        
        Get.snackbar(
          "Rute Ditemukan", 
          "Jalur menuju spot telah digambar di peta.", 
          backgroundColor: const Color(0xFF13151D), 
          colorText: Colors.white
        );
      } else {
        Get.snackbar("Gagal", "Tidak dapat mengambil rute.");
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat rute: $e");
    }
  }
}