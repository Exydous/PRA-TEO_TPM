import 'dart:async'; 
import 'dart:io';
import 'dart:ui' as ui; 
import 'dart:typed_data'; 
import 'package:flutter/rendering.dart'; 
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart'; // [BARU] Import Hive
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:shake_gesture/shake_gesture.dart'; 
import 'package:light/light.dart'; 
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/routes/app_routes.dart';

class EditorState {
  final double exposure;
  final double contrast;
  final double temperature;
  final double saturation;
  final double tint; 
  final bool isBlackAndWhite;

  EditorState({
    required this.exposure, required this.contrast, required this.temperature,
    required this.saturation, required this.tint, required this.isBlackAndWhite,
  });
}

enum EditorMode { crop, edit }
enum EditSubMenu { light, color }

class EditorController extends GetxController {
  final supabase = Supabase.instance.client; 
  // [BARU] Panggil Kotak Rahasia Hive
  final Box authBox = Hive.box('authBox');
  
  Rx<File?> selectedImage = Rx<File?>(null);
  var currentDraftId = ''.obs; 
  var oldImageUrl = ''.obs; 
  
  var currentMode = EditorMode.edit.obs;
  var currentSubMenu = EditSubMenu.light.obs;

  var exposure = 0.0.obs; 
  var contrast = 0.0.obs; 
  var temperature = 0.0.obs; 
  var saturation = 0.0.obs;
  var tint = 0.0.obs; 
  var isBlackAndWhite = false.obs;

  var history = <EditorState>[].obs;
  var currentIndex = (-1).obs;

  var luxValue = 0.obs;
  var isDarkRoomWarningShown = false; 
  Light? _lightSensor;
  StreamSubscription<int>? _lightSubscription;

  final ImagePicker _picker = ImagePicker();
  final GlobalKey exportKey = GlobalKey();

  var ownedPresets = <Map<String, dynamic>>[].obs;
  var isPresetsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ShakeGesture.registerCallback(onShake: _onShakeDetected);
    _initLightSensor(); 
    loadOwnedPresets(); 
  }

  @override
  void onClose() {
    ShakeGesture.unregisterCallback(onShake: _onShakeDetected);
    _lightSubscription?.cancel(); 
    super.onClose();
  }

  // --- MENGAMBIL PRESET DARI SUPABASE MENGGUNAKAN HIVE ---
  Future<void> loadOwnedPresets() async {
    // Ambil email dari Hive
    String currentEmail = Hive.box('authBox').get('currentUser', defaultValue: '');
    if (currentEmail.isEmpty) return;

    try {
      isPresetsLoading.value = true;
      // Filter menggunakan Email, bukan user.id lama
      final response = await supabase
          .from('user_presets')
          .select('presets (*)') 
          .eq('user_id', currentEmail)
          .order('purchased_at', ascending: false);

      ownedPresets.value = List<Map<String, dynamic>>.from(
        response.map((e) => e['presets'])
      );
    } catch (e) {
      debugPrint("Gagal memuat koleksi preset: $e");
    } finally {
      isPresetsLoading.value = false;
    }
  }

  void applyPreset(Map<String, dynamic> preset) {
    String name = preset['name'] ?? 'Preset';
    exposure.value = (preset['exposure'] as num?)?.toDouble() ?? 0.0;
    contrast.value = (preset['contrast'] as num?)?.toDouble() ?? 0.0;
    temperature.value = (preset['temperature'] as num?)?.toDouble() ?? 0.0;
    saturation.value = (preset['saturation'] as num?)?.toDouble() ?? 0.0;
    tint.value = (preset['tint'] as num?)?.toDouble() ?? 0.0;
    isBlackAndWhite.value = preset['is_black_and_white'] ?? false;
    
    saveState(); 
    
    Get.snackbar(
      '✨ Preset Aktif', 
      'Menerapkan gaya $name', 
      snackPosition: SnackPosition.TOP, 
      backgroundColor: Colors.black87, 
      colorText: Colors.white, 
      duration: const Duration(seconds: 2)
    );
  }

  void _initLightSensor() {
    _lightSensor = Light();
    try {
      _lightSubscription = _lightSensor?.lightSensorStream.listen((int lux) {
        luxValue.value = lux;
        if (lux < 15 && !isDarkRoomWarningShown) {
          isDarkRoomWarningShown = true; 
          Get.snackbar('💡 Ruangan Terlalu Gelap', 'Warna foto mungkin terlihat berbeda di siang hari.', duration: const Duration(seconds: 4), backgroundColor: Colors.blueGrey.shade900, colorText: Colors.white, snackPosition: SnackPosition.TOP);
        } else if (lux > 50 && isDarkRoomWarningShown) {
          isDarkRoomWarningShown = false; 
        }
      });
    } catch (e) {
      debugPrint("Sensor Cahaya error: $e");
    }
  }

  void _onShakeDetected() => resetEffects(fromSensor: true);

  void resetEffects({bool fromSensor = false}) {
    exposure.value = 0.0; contrast.value = 0.0; temperature.value = 0.0;
    saturation.value = 0.0; tint.value = 0.0; isBlackAndWhite.value = false;
    saveState(); 
    String msg = fromSensor ? 'Guncangan terdeteksi! Efek direset.' : 'Efek berhasil direset.';
    Get.snackbar('Reset', msg, duration: const Duration(seconds: 2), snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87, colorText: Colors.white);
  }

  void saveState() {
    if (currentIndex.value < history.length - 1) {
      history.removeRange(currentIndex.value + 1, history.length);
    }
    history.add(EditorState(exposure: exposure.value, contrast: contrast.value, temperature: temperature.value, saturation: saturation.value, tint: tint.value, isBlackAndWhite: isBlackAndWhite.value));
    currentIndex.value = history.length - 1;
  }

  void _applyState(EditorState state) {
    exposure.value = state.exposure; contrast.value = state.contrast; temperature.value = state.temperature;
    saturation.value = state.saturation; tint.value = state.tint; isBlackAndWhite.value = state.isBlackAndWhite;
  }

  void undo() {
    if (currentIndex.value > 0) {
      currentIndex.value--; _applyState(history[currentIndex.value]);
    }
  }

  void redo() {
    if (currentIndex.value < history.length - 1) {
      currentIndex.value++; _applyState(history[currentIndex.value]);
    }
  }

  Future<void> openCropTool() async {
    if (selectedImage.value == null) return;
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(sourcePath: selectedImage.value!.path);
      if (croppedFile != null) selectedImage.value = File(croppedFile.path);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memotong gambar: $e');
    }
  }

  Future<void> pickImageAndOpenEditor() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImage.value = File(image.path);
        currentDraftId.value = ''; 
        oldImageUrl.value = '';
        resetAllSettings(); 
        Get.toNamed(AppRoutes.EDITOR); 
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuka galeri: $e');
    }
  }

  Future<void> saveToGallery() async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      RenderRepaintBoundary boundary = exportKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(pngBytes, quality: 100, name: "PRA_TEO_${DateTime.now().millisecondsSinceEpoch}");
      Get.back(); 

      if (result['isSuccess']) {
        Get.snackbar('📸 Berhasil!', 'Foto berhasil disimpan ke Galeri.', backgroundColor: Colors.green, colorText: Colors.white);
        
        if (currentDraftId.value.isNotEmpty) {
          await supabase.from('drafts').delete().eq('id', currentDraftId.value);
          if (Get.isRegistered<DraftController>()) Get.find<DraftController>().loadDrafts();
        }
      }
    } catch (e) {
      Get.back();
      debugPrint("Error save image: $e");
    }
  }

  // --- [DIUBAH] MENYIMPAN DRAFT MENGGUNAKAN EMAIL LOKAL ---
  Future<void> saveToCloud(String draftName) async {
    if (selectedImage.value == null) return;
    
    // Ambil email dari Hive
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    if (currentEmail.isEmpty) throw Exception("User belum login");

    // Nama file sekarang menggunakan email agar unik
    String safeEmail = currentEmail.replaceAll('@', '_').replaceAll('.', '_');
    String fileName = '${safeEmail}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    await supabase.storage.from('draft_images').upload(fileName, selectedImage.value!);
    String newImageUrl = supabase.storage.from('draft_images').getPublicUrl(fileName);

    Map<String, dynamic> draftData = {
      'user_id': currentEmail, // Simpan email ke kolom user_id
      'draft_name': draftName,
      'image_url': newImageUrl,
      'exposure': exposure.value,
      'contrast': contrast.value,
      'temperature': temperature.value,
      'saturation': saturation.value,
      'tint': tint.value,
      'is_black_and_white': isBlackAndWhite.value,
    };

    if (currentDraftId.value.isNotEmpty) {
      await supabase.from('drafts').update(draftData).eq('id', currentDraftId.value);
      if (oldImageUrl.value.isNotEmpty) {
        String oldFileName = oldImageUrl.value.split('/').last;
        await supabase.storage.from('draft_images').remove([oldFileName]);
      }
    } else {
      await supabase.from('drafts').insert(draftData);
    }
  }

  void _processSavingDraft(String customName) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    String finalName = customName.isEmpty ? "Edit_${DateTime.now().day}-${DateTime.now().month}_${DateTime.now().hour}:${DateTime.now().minute}" : customName;

    try {
      await saveToCloud(finalName);
      resetAllSettings();
      selectedImage.value = null;
      currentDraftId.value = '';

      if (Get.isRegistered<DraftController>()) Get.find<DraftController>().loadDrafts();
      
      Get.back(); 
      Get.back(); 
      Get.back();
      
      Get.snackbar('💾 Disimpan', 'Draft "$finalName" tersimpan aman di Cloud.', backgroundColor: Colors.blueGrey.shade900, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.back(); 
      Get.snackbar('❌ Gagal', 'Gagal menyimpan draft: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void cancelEditing() {
    TextEditingController nameController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simpan ke Cloud?', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Nama Draft', hintStyle: TextStyle(color: Colors.white38), filled: true, fillColor: Colors.black),
        ),
        actions: [
          TextButton(onPressed: () { Get.back(); resetAllSettings(); selectedImage.value = null; Get.back(); }, child: const Text('Buang', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(onPressed: () { _processSavingDraft(nameController.text.trim()); }, child: const Text('Simpan')),
        ],
      )
    );
  }

  void resetAllSettings() {
    currentMode.value = EditorMode.edit; currentSubMenu.value = EditSubMenu.light;
    exposure.value = 0.0; contrast.value = 0.0; temperature.value = 0.0;
    saturation.value = 0.0; tint.value = 0.0; isBlackAndWhite.value = false;
    history.clear(); saveState(); 
  }

  List<double> get combinedColorMatrix {
    double b = exposure.value; double c = 1.0 + (contrast.value / 250.0); double contrastOffset = 128.0 * (1.0 - c); 
    double baseSat = isBlackAndWhite.value ? -100.0 : saturation.value; double s = 1.0 + (baseSat / 100.0);
    double tempAdjust = temperature.value / 250.0; double tintAdjust = tint.value / 250.0; 
    double rAdjust = tempAdjust + tintAdjust; double bAdjust = -tempAdjust + tintAdjust; double gAdjust = (tempAdjust * 0.3) - tintAdjust; 
    const double lumR = 0.2126; const double lumG = 0.7152; const double lumB = 0.0722;
    double sr = (1 - s) * lumR; double sg = (1 - s) * lumG; double sb = (1 - s) * lumB;
    return [
      c * (sr + s + rAdjust), c * sg, c * sb, 0, b + contrastOffset, 
      c * sr, c * (sg + s + gAdjust), c * sb, 0, b + contrastOffset, 
      c * sr, c * sg, c * (sb + s + bAdjust), 0, b + contrastOffset, 
      0, 0, 0, 1, 0,                                                 
    ];
  }

  Future<void> resumeDraft(Map<String, dynamic> data) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      String fileName = data['image_url'].split('/').last;
      final Uint8List fileBytes = await supabase.storage.from('draft_images').download(fileName);
      final tempDir = await getTemporaryDirectory();
      File tempFile = File('${tempDir.path}/temp_draft_${data['id']}.jpg');
      await tempFile.writeAsBytes(fileBytes);

      selectedImage.value = tempFile;
      currentDraftId.value = data['id']; 
      oldImageUrl.value = data['image_url'];

      exposure.value = data['exposure'].toDouble();
      contrast.value = data['contrast'].toDouble();
      temperature.value = data['temperature'].toDouble();
      saturation.value = data['saturation'].toDouble();
      tint.value = (data['tint'] ?? 0.0).toDouble(); 
      isBlackAndWhite.value = data['is_black_and_white'];
      
      Get.back(); 
      Get.toNamed(AppRoutes.EDITOR); 
    } catch (e) {
      Get.back(); 
      Get.snackbar('Error', 'Gagal mengunduh draft dari cloud: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}

// ==========================================
// DRAFT CONTROLLER
// ==========================================
class DraftController extends GetxController {
  final supabase = Supabase.instance.client;
  // [BARU] Panggil Hive juga di sini
  final Box authBox = Hive.box('authBox');
  
  var savedDrafts = <Map<String, dynamic>>[].obs;
  
  var isSelectionMode = false.obs;
  var selectedIds = <String>[].obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDrafts();
  }

  List<Map<String, dynamic>> get filteredDrafts {
    if (searchQuery.value.isEmpty) {
      return savedDrafts; // Tampilkan semua jika kotak pencarian kosong
    }
    // Saring berdasarkan nama draft (mengabaikan huruf besar/kecil)
    return savedDrafts.where((draft) {
      String name = (draft['draft_name'] ?? '').toString().toLowerCase();
      String query = searchQuery.value.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  // --- [DIUBAH] MEMUAT DRAFT SESUAI EMAIL LOKAL ---
  Future<void> loadDrafts() async {
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    if (currentEmail.isEmpty) return;

    try {
      final response = await supabase
          .from('drafts')
          .select()
          .eq('user_id', currentEmail) // [PENTING] Filter agar tidak mengambil data orang lain
          .order('created_at', ascending: false);
      
      savedDrafts.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Gagal mengambil draft: $e");
    }
  }
  
  void startSelection(String id) => toggleSelection(id); 

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      if (selectedIds.isEmpty) isSelectionMode.value = false;
    } else {
      selectedIds.add(id);
      if (!isSelectionMode.value) isSelectionMode.value = true;
    }
  }

  void cancelSelection() {
    isSelectionMode.value = false;
    selectedIds.clear();
  }

  void deleteSelectedDrafts() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Draft?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus ${selectedIds.length} draft yang dipilih dari Cloud?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Get.back(); 
              Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
              
              try {
                for (String id in selectedIds) {
                  await supabase.from('drafts').delete().eq('id', id);
                }
                cancelSelection();
                await loadDrafts(); 
                Get.back(); 
                Get.snackbar('🗑️ Terhapus', 'Draft berhasil dihapus dari Cloud.', backgroundColor: Colors.blueGrey.shade900, colorText: Colors.white);
              } catch (e) {
                Get.back();
                Get.snackbar('Error', 'Gagal menghapus draft: $e', backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  void showRenameDialog() {
    if (selectedIds.length != 1) return; 
    String targetId = selectedIds.first;
    
    String oldName = savedDrafts.firstWhere((d) => d['id'] == targetId)['draft_name'];
    TextEditingController nameCtrl = TextEditingController(text: oldName);

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ganti Nama Draft', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(filled: true, fillColor: Colors.black),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Get.back(); 
              String newName = nameCtrl.text.trim().isEmpty ? "Tanpa Nama" : nameCtrl.text.trim();
              
              await supabase.from('drafts').update({'draft_name': newName}).eq('id', targetId);
              
              cancelSelection();
              loadDrafts(); 
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

void updateSearch(String query) {
    searchQuery.value = query;
  }

}