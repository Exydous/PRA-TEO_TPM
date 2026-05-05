import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../editor/controllers/editor_controller.dart';
import '../../../services/color_transfer_service.dart';

class ColorTransferController extends GetxController {
  var isProcessing = false.obs;
  final ImagePicker _picker = ImagePicker(); // Input Referensi

  Future<void> pickReferenceAndTransfer() async {
    try {
      // 1. Buka galeri untuk memilih foto referensi (Scene Film)
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return; // User batal memilih
      
      isProcessing.value = true;
      File referenceFile = File(pickedFile.path);

      // 2. Proses analisis matematis warnanya
      final styleData = await ColorTransferService.extractColorStyle(referenceFile); // mengirim ke mesin AI untuk analisis warna

      if (styleData != null && Get.isRegistered<EditorController>()) {
        final editorCtrl = Get.find<EditorController>();
        
        // 3. Terapkan nilai ke slider secara instan dari mesin AI
        editorCtrl.exposure.value = styleData['exposure']!;
        editorCtrl.contrast.value = styleData['contrast']!;
        editorCtrl.temperature.value = styleData['temperature']!;
        editorCtrl.tint.value = styleData['tint']!;
        editorCtrl.saturation.value = styleData['saturation']!;
        
        editorCtrl.saveState(); // Simpan riwayat undo

        Get.snackbar(
          '🎨 Transfer Sukses!', 
          'Gaya warna berhasil disalin dari gambar referensi.',
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        '❌ Gagal', 
        'Tidak dapat membaca warna gambar referensi.',
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }
}