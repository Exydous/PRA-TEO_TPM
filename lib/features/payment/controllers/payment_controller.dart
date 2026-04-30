import 'package:get/get.dart';
import '../../utilities/preset_store/controllers/preset_store_controller.dart'; 
import 'package:flutter/material.dart';
import '../../../../services/notification_service.dart';
import '../../editor/controllers/editor_controller.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

class PaymentController extends GetxController {
  final storeCtrl = Get.find<PresetStoreController>();

  var selectedMethod = ''.obs;

  // Daftar pembayaran dinamis (Ikon tetap aman)
  List<Map<String, String>> get currentPaymentMethods {
    String currency = storeCtrl.selectedCurrency.value;
    
    if (currency == 'IDR') {
      return [
        {'name': 'GOPAY', 'icon': 'assets/icons/GOPAY.jpg'},
        {'name': 'OVO', 'icon': 'assets/icons/OVO.webp'},
        {'name': 'SHOPEE-PAY', 'icon': 'assets/icons/SHOPEE PAY.png'},
        {'name': 'DANA', 'icon': 'assets/icons/DANA.jpeg'},
        {'name': 'QRIS', 'icon': 'assets/icons/QRIS.jpg'},
        {'name': 'Transfer bank', 'icon': 'assets/icons/transfer_bank.png'},
      ];
    } else if (currency == 'USD') {
      return [
        {'name': 'Xsolla Pay', 'icon': 'assets/icons/XSOLLA PAY.png'},
        {'name': 'Razer Gold', 'icon': 'assets/icons/RAZER GOLD.png'},
        {'name': 'Paypall', 'icon': 'assets/icons/PAYPALL.jpg'},
        {'name': 'Google Pay', 'icon': 'assets/icons/GOOGLE PAY.png'},
        {'name': 'Apple Pay', 'icon': 'assets/icons/APPLE PAY.png'},
      ];
    } else { // EUR
      return [
        {'name': 'Google Pay', 'icon': 'assets/icons/GOOGLE PAY.png'},
        {'name': 'Apple Pay', 'icon': 'assets/icons/APPLE PAY.png'},
        {'name': 'Paypall', 'icon': 'assets/icons/PAYPALL.jpg'},
        {'name': 'Klarna.', 'icon': 'assets/icons/KLARNA..webp'},
      ];
    }
  }

  @override
  void onInit() {
    super.onInit();
    _setDefaultMethod();
    
    ever(storeCtrl.selectedCurrency, (_) {
      _setDefaultMethod();
    });
  }

  void _setDefaultMethod() {
    if (currentPaymentMethods.isNotEmpty) {
      selectedMethod.value = currentPaymentMethods[0]['name']!;
    }
  }

  void selectMethod(String method) {
    selectedMethod.value = method;
  }

  // --- [DIUBAH] LOGIKA UTAMA PEMBAYARAN ---
  // --- [DIUBAH] MENGGUNAKAN OPTIMISTIC UI UPDATE ---
  Future<void> processPayment() async {
    final Map<String, dynamic> preset = Get.arguments ?? {};
    if (preset.isEmpty) return;

    // 1. PANGGIL CONTROLLER MEMORI
    final EditorController editorController = Get.put(EditorController(), permanent: true);
    final String currentEmail = Hive.box('authBox').get('currentUser', defaultValue: '');

    // 2. PAKSA MUNCUL DI LAYAR DULUAN (OPTIMISTIC UPDATE)
    // Ini menjamin preset PASTI MUNCUL di Profile & Editor tanpa peduli error database
    if (currentEmail.isNotEmpty) {
      // 3. Masukkan ke memori lokal detik ini juga agar LANGSUNG TAMPIL
      bool isAlreadyOwned = editorController.ownedPresets.any((p) => p['id'] == preset['id']);
      if (!isAlreadyOwned) {
        editorController.ownedPresets.add(preset);
        editorController.ownedPresets.refresh(); // Paksa UI (Profile/Editor) untuk update
      }

      // 4. Kirim ke Supabase di belakang layar (tanpa mengubah struktur tabelmu)
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('user_presets').insert({
          'user_id': currentEmail,
          'preset_id': preset['id']?.toString() ?? preset['name'],
          // purchased_at akan otomatis terisi oleh default value Supabase
        });
      } catch (e) {
        debugPrint("Sinkronisasi cloud gagal, tapi data aman di memori HP: $e");
      }
    }

    // 3. TUTUP HALAMAN PAYMENT SEKARANG JUGA
    Get.back();

    // 4. MUNCULKAN NOTIFIKASI SUKSES
    // Future.delayed(const Duration(milliseconds: 300), () {
    //   Get.snackbar(
    //     'Pembayaran Berhasil 🎉',
    //     'Preset ${preset['name'] ?? ''} ditambahkan ke koleksimu!',
    //     snackPosition: SnackPosition.TOP,
    //     backgroundColor: const Color(0xFF1E3A8A),
    //     colorText: Colors.white,
    //   );
    // });

    NotificationService.showNotification(
      id: preset['id']?.hashCode ?? 1, 
      title: 'Pembayaran Berhasil! 🎉',
      body: 'Preset ${preset['name'] ?? ''} telah ditambahkan.',
    );

  }
}