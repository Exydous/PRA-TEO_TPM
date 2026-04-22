import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart'; // [BARU] Import Hive
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tugas_akhir/features/editor/controllers/editor_controller.dart';
import '../../../../services/currency_service.dart'; 

class PresetStoreController extends GetxController {
  final supabase = Supabase.instance.client;
  final CurrencyService _currencyService = CurrencyService();
  // [BARU] Panggil Kotak Rahasia Hive
  final Box authBox = Hive.box('authBox');
  
  var presets = <Map<String, dynamic>>[].obs;
  
  var isLoading = true.obs;
  var isCurrencyLoading = false.obs;

  var selectedCurrency = 'IDR'.obs;
  final List<String> availableCurrencies = ['IDR', 'USD', 'EUR'];
  
  var exchangeRate = 15500.0.obs; 

  @override
  void onInit() {
    super.onInit();
    fetchPresets(); 
    updateCurrency('IDR'); 
  }

  Future<void> fetchPresets() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('presets')
          .select()
          .order('created_at', ascending: false);
      
      presets.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Fetching Presets: $e");
      Get.snackbar(
        "Kesalahan Jaringan", 
        "Gagal memuat preset. Pastikan internetmu stabil.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCurrency(String currencyCode) async {
    isCurrencyLoading.value = true;
    selectedCurrency.value = currencyCode;
    
    if (currencyCode == 'USD') {
      exchangeRate.value = 1.0;
    } else {
      exchangeRate.value = await _currencyService.getExchangeRate(currencyCode);
    }
    
    isCurrencyLoading.value = false;
  }

  String getConvertedPrice(double basePriceUsd) {
    double convertedPrice = basePriceUsd * exchangeRate.value;
    
    if (selectedCurrency.value == 'IDR') {
      return "Rp ${convertedPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
    } else if (selectedCurrency.value == 'EUR') {
      return "€${convertedPrice.toStringAsFixed(2)}";
    }
    return "\$${convertedPrice.toStringAsFixed(2)}";
  }

  // --- [DIUBAH] PEMBELIAN MENGGUNAKAN HIVE LOKAL ---
  Future<void> buyPreset(Map<String, dynamic> preset) async {
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    
    if (currentEmail.isEmpty) {
      Get.snackbar(
        'Gagal', 
        'Kamu harus login terlebih dahulu.',
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white
      );
      return;
    }

    try {
      // 1. Catat pembelian ke tabel user_presets menggunakan Email
      await supabase.from('user_presets').insert({
        'user_id': currentEmail, 
        'preset_id': preset['id'],
      });

      // 2. Berikan notifikasi sukses
      Get.snackbar(
        '🛒 Berhasil!',
        'Preset "${preset['name']}" telah ditambahkan ke koleksimu.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // 3. SECARA INSTAN tambahkan ke memori EditorController agar UI langsung berubah
      if (Get.isRegistered<EditorController>()) {
        Get.find<EditorController>().ownedPresets.insert(0, preset);
      }

    } catch (e) {
      Get.snackbar(
        'Database Error',
        'Gagal menyimpan: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}