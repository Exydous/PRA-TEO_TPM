import 'dart:async'; 
import 'dart:io';
import 'dart:ui' as ui; 
import 'dart:typed_data'; 
import 'dart:convert'; 
import 'package:flutter/rendering.dart'; 
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:shake_gesture/shake_gesture.dart'; 
import '../../../core/routes/app_routes.dart';
import 'package:light/light.dart'; 
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 

class EditorState {
  final double exposure;
  final double contrast;
  final double temperature;
  final double saturation;
  final bool isBlackAndWhite;

  EditorState({
    required this.exposure,
    required this.contrast,
    required this.temperature,
    required this.saturation,
    required this.isBlackAndWhite,
  });
}

enum EditorMode { crop, edit }
enum EditSubMenu { light, color }

class EditorController extends GetxController {
  Rx<File?> selectedImage = Rx<File?>(null);
  
  var currentMode = EditorMode.edit.obs;
  var currentSubMenu = EditSubMenu.light.obs;

  var exposure = 0.0.obs; 
  var contrast = 0.0.obs; 
  var temperature = 0.0.obs; 
  var saturation = 0.0.obs; 
  var isBlackAndWhite = false.obs;

  var history = <EditorState>[].obs;
  var currentIndex = (-1).obs;

  var luxValue = 0.obs;
  var isDarkRoomWarningShown = false; 
  Light? _lightSensor;
  StreamSubscription<int>? _lightSubscription;

  final ImagePicker _picker = ImagePicker();
  
  final GlobalKey exportKey = GlobalKey();

  @override
  void onInit() {
    super.onInit();
    ShakeGesture.registerCallback(onShake: _onShakeDetected);
    _initLightSensor(); 
  }

  @override
  void onClose() {
    ShakeGesture.unregisterCallback(onShake: _onShakeDetected);
    _lightSubscription?.cancel(); 
    super.onClose();
  }

  void _initLightSensor() {
    _lightSensor = Light();
    try {
      _lightSubscription = _lightSensor?.lightSensorStream.listen((int lux) {
        luxValue.value = lux;
        if (lux < 15 && !isDarkRoomWarningShown) {
          isDarkRoomWarningShown = true; 
          Get.snackbar(
            '💡 Ruangan Terlalu Gelap',
            'Warna & kontras foto mungkin terlihat berbeda saat dicetak atau dilihat di siang hari.',
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.blueGrey.shade900,
            colorText: Colors.white,
            icon: const Icon(Icons.nightlight_round, color: Colors.amber),
            margin: const EdgeInsets.all(12),
          );
        } else if (lux > 50 && isDarkRoomWarningShown) {
          isDarkRoomWarningShown = false; 
        }
      }, onError: (e) {
        debugPrint("Sensor Cahaya tidak didukung.");
      });
    } catch (e) {
      debugPrint("Gagal menginisialisasi sensor cahaya: $e");
    }
  }

  void _onShakeDetected() {
    resetEffects(fromSensor: true);
  }

  void resetEffects({bool fromSensor = false}) {
    exposure.value = 0.0;
    contrast.value = 0.0;
    temperature.value = 0.0;
    saturation.value = 0.0;
    isBlackAndWhite.value = false;
    saveState(); 

    String message = fromSensor ? 'Guncangan terdeteksi! Efek direset.' : 'Efek berhasil direset.';
    Get.snackbar('Reset', message, duration: const Duration(seconds: 2), snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87, colorText: Colors.white);
  }

  void saveState() {
    if (currentIndex.value < history.length - 1) {
      history.removeRange(currentIndex.value + 1, history.length);
    }
    history.add(EditorState(
      exposure: exposure.value,
      contrast: contrast.value,
      temperature: temperature.value,
      saturation: saturation.value,
      isBlackAndWhite: isBlackAndWhite.value,
    ));
    currentIndex.value = history.length - 1;
  }

  void _applyState(EditorState state) {
    exposure.value = state.exposure;
    contrast.value = state.contrast;
    temperature.value = state.temperature;
    saturation.value = state.saturation;
    isBlackAndWhite.value = state.isBlackAndWhite;
  }

  void undo() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      _applyState(history[currentIndex.value]);
    } else {
      Get.snackbar('Batas', 'Sudah di titik awal editan', duration: const Duration(seconds: 1), snackPosition: SnackPosition.TOP);
    }
  }

  void redo() {
    if (currentIndex.value < history.length - 1) {
      currentIndex.value++;
      _applyState(history[currentIndex.value]);
    } else {
      Get.snackbar('Batas', 'Sudah di editan terbaru', duration: const Duration(seconds: 1), snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> openCropTool() async {
    if (selectedImage.value == null) return;
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: selectedImage.value!.path,
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop & Rotate', toolbarColor: Colors.black, toolbarWidgetColor: Colors.white, backgroundColor: const Color(0xFF1A1A1A), activeControlsWidgetColor: const Color(0xFF4FC3F7), initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: false, hideBottomControls: false),
          IOSUiSettings(title: 'Crop & Rotate', aspectRatioLockEnabled: false, resetButtonHidden: false),
        ],
      );
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
        Get.snackbar('📸 Berhasil!', 'Foto berhasil disimpan ke Galeri HP.', backgroundColor: Colors.green, colorText: Colors.white);
        await removeSpecificDraft(selectedImage.value!.path);
      } else {
        Get.snackbar('❌ Gagal', 'Gagal menyimpan foto.', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.back();
      debugPrint("Error save image: $e");
    }
  }

  // --- DIMODIFIKASI: Menerima parameter nama draft ---
  Future<void> saveToWorkspace(String draftName) async {
    if (selectedImage.value == null) return;
    
    Map<String, dynamic> newDraft = {
      'imagePath': selectedImage.value!.path,
      'fileName': draftName, // Menggunakan nama dari Pop-Up atau Default
      'exposure': exposure.value,
      'contrast': contrast.value,
      'temperature': temperature.value,
      'saturation': saturation.value,
      'isBlackAndWhite': isBlackAndWhite.value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final prefs = await SharedPreferences.getInstance();
    String? existingDraftsStr = prefs.getString('editor_drafts_list');
    
    List<dynamic> draftsList = existingDraftsStr != null ? jsonDecode(existingDraftsStr) : [];
    
    draftsList.removeWhere((draft) => draft['imagePath'] == selectedImage.value!.path);
    draftsList.insert(0, newDraft);

    await prefs.setString('editor_drafts_list', jsonEncode(draftsList));
  }

  Future<void> removeSpecificDraft(String path) async {
    final prefs = await SharedPreferences.getInstance();
    String? existingDraftsStr = prefs.getString('editor_drafts_list');
    
    if (existingDraftsStr != null) {
      List<dynamic> draftsList = jsonDecode(existingDraftsStr);
      draftsList.removeWhere((draft) => draft['imagePath'] == path);
      await prefs.setString('editor_drafts_list', jsonEncode(draftsList));
    }
    
    if (Get.isRegistered<DraftController>()) {
      Get.find<DraftController>().loadDrafts(); 
    }
  }

  // --- DITAMBAHKAN: Format nama file default (Tanggal & Jam) ---
  String _getDefaultDraftName() {
    final now = DateTime.now();
    // Format: Edit_11-04-2026_16:07
    String day = now.day.toString().padLeft(2, '0');
    String month = now.month.toString().padLeft(2, '0');
    String year = now.year.toString();
    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    
    return "Edit_${day}-${month}-${year}_$hour:$minute";
  }

  // --- DITAMBAHKAN: Proses akhir menyimpan & keluar ---
  void _processSavingDraft(String customName) {
    String finalName = customName;
    if (finalName.isEmpty) {
      finalName = _getDefaultDraftName(); // Pakai nama default jika kosong
    }

    saveToWorkspace(finalName).then((_) {
      resetAllSettings();
      selectedImage.value = null;

      // Panggil Pos Satpam untuk refresh UI
      if (Get.isRegistered<DraftController>()) {
        Get.find<DraftController>().loadDrafts();
      }

      Get.back(); // Tutup layar Editor
      Get.snackbar(
        '💾 Disimpan', 
        'Draft "$finalName" tersimpan di Workspace.', 
        backgroundColor: Colors.blueGrey.shade900, 
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    });
  }

  // --- DIMODIFIKASI: Menampilkan Pop-Up Input Nama ---
  void cancelEditing() {
    TextEditingController nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
        title: const Text('Simpan ke Workspace?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beri nama draft ini agar mudah dicari. Kosongkan untuk menggunakan tanggal otomatis.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nama Draft (Opsional)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Tombol Hapus/Buang jika benar-benar tidak mau simpan
          TextButton(
            onPressed: () {
              Get.back(); // Tutup pop-up
              resetAllSettings();
              selectedImage.value = null;
              Get.back(); // Tutup editor
            },
            child: const Text('Jangan Simpan', style: TextStyle(color: Colors.redAccent)),
          ),
          // Tombol Simpan
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back(); // Tutup pop-up dulu
              _processSavingDraft(nameController.text.trim());
            },
            child: const Text('Simpan Draft', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      barrierDismissible: false, // Memaksa user untuk memilih tombol
    );
  }

  void resetAllSettings() {
    currentMode.value = EditorMode.edit;
    currentSubMenu.value = EditSubMenu.light;
    
    exposure.value = 0.0; 
    contrast.value = 0.0; 
    temperature.value = 0.0;
    saturation.value = 0.0; 
    isBlackAndWhite.value = false;

    history.clear(); 
    saveState(); 
  }

  List<double> get combinedColorMatrix {
    double b = exposure.value; 
    double c = 1.0 + (contrast.value / 250.0); 
    double contrastOffset = 128.0 * (1.0 - c); 

    double baseSat = isBlackAndWhite.value ? -100.0 : saturation.value;
    double s = 1.0 + (baseSat / 100.0);
    
    double tempAdjust = temperature.value / 250.0; 
    
    double rAdjust = tempAdjust;
    double bAdjust = -tempAdjust;
    double gAdjust = tempAdjust * 0.3; 

    const double lumR = 0.2126;
    const double lumG = 0.7152;
    const double lumB = 0.0722;

    double sr = (1 - s) * lumR;
    double sg = (1 - s) * lumG;
    double sb = (1 - s) * lumB;

    return [
      c * (sr + s + rAdjust), c * sg, c * sb, 0, b + contrastOffset, 
      c * sr, c * (sg + s + gAdjust), c * sb, 0, b + contrastOffset, 
      c * sr, c * sg, c * (sb + s + bAdjust), 0, b + contrastOffset, 
      0, 0, 0, 1, 0,                                                 
    ];
  }

  Future<void> resumeDraft(Map<String, dynamic> data) async {
    selectedImage.value = File(data['imagePath']);
    exposure.value = data['exposure'];
    contrast.value = data['contrast'];
    temperature.value = data['temperature'];
    saturation.value = data['saturation'];
    isBlackAndWhite.value = data['isBlackAndWhite'];
    
    Get.toNamed(AppRoutes.EDITOR); 
  }
}

class DraftController extends GetxController {
  var savedDrafts = <Map<String, dynamic>>[].obs;
  
  // Variabel untuk fitur seleksi
  var isSelectionMode = false.obs;
  var selectedPaths = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDrafts();
  }

  Future<void> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final draftString = prefs.getString('editor_drafts_list');
    
    if (draftString != null) {
      List<dynamic> decodedList = jsonDecode(draftString);
      List<Map<String, dynamic>> validDrafts = [];

      for (var data in decodedList) {
        if (File(data['imagePath']).existsSync()) {
          validDrafts.add(Map<String, dynamic>.from(data));
        }
      }
      savedDrafts.value = validDrafts;
    } else {
      savedDrafts.clear();
    }
  }

  // --- LOGIKA MODE SELEKSI ---
  
  // DIMODIFIKASI: Mempermudah startSelection
  void startSelection(String path) {
    toggleSelection(path); // Panggil toggleSelection yang baru
  }

  // DIMODIFIKASI: Menambahkan logika auto-start/auto-stop selection mode
  void toggleSelection(String path) {
    if (selectedPaths.contains(path)) {
      selectedPaths.remove(path);
      // Jika semua centang dilepas, matikan mode seleksi otomatis
      if (selectedPaths.isEmpty) {
        isSelectionMode.value = false;
      }
    } else {
      selectedPaths.add(path);
      // Jika centang pertama kali dibuat, hidupkan mode seleksi otomatis
      if (!isSelectionMode.value) {
        isSelectionMode.value = true;
      }
    }
  }

  void cancelSelection() {
    isSelectionMode.value = false;
    selectedPaths.clear();
  }

  // --- LOGIKA HAPUS DRAFT ---
  void deleteSelectedDrafts() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
        title: const Text('Hapus Draft?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus ${selectedPaths.length} draft yang dipilih? File asli di galerimu tidak akan terhapus.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Get.back(); // Tutup dialog
              final prefs = await SharedPreferences.getInstance();
              String? existing = prefs.getString('editor_drafts_list');
              if (existing != null) {
                List<dynamic> drafts = jsonDecode(existing);
                // Hapus semua draft yang dicentang
                drafts.removeWhere((d) => selectedPaths.contains(d['imagePath']));
                await prefs.setString('editor_drafts_list', jsonEncode(drafts));
              }
              cancelSelection();
              loadDrafts(); // Refresh UI
              Get.snackbar('🗑️ Terhapus', 'Draft berhasil dihapus.', backgroundColor: Colors.blueGrey.shade900, colorText: Colors.white, snackPosition: SnackPosition.TOP);
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  // --- LOGIKA GANTI NAMA DRAFT ---
  void showRenameDialog() {
    if (selectedPaths.length != 1) return; // Hanya bisa ganti nama 1 per 1
    String targetPath = selectedPaths.first;
    
    // Cari nama lamanya
    String oldName = "";
    for (var d in savedDrafts) {
      if (d['imagePath'] == targetPath) oldName = d['fileName'];
    }

    TextEditingController nameCtrl = TextEditingController(text: oldName);

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
        title: const Text('Ganti Nama Draft', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true, fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.orangeAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Get.back(); // Tutup dialog
              final prefs = await SharedPreferences.getInstance();
              String? existing = prefs.getString('editor_drafts_list');
              if (existing != null) {
                List<dynamic> drafts = jsonDecode(existing);
                for (var d in drafts) {
                  if (d['imagePath'] == targetPath) {
                    d['fileName'] = nameCtrl.text.trim().isEmpty ? "Tanpa Nama" : nameCtrl.text.trim();
                    break;
                  }
                }
                await prefs.setString('editor_drafts_list', jsonEncode(drafts));
              }
              cancelSelection();
              loadDrafts(); // Refresh UI
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }
}