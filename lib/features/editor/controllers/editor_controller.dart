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
  final double tint; // <--- FITUR BARU: TINT
  final bool isBlackAndWhite;

  EditorState({
    required this.exposure,
    required this.contrast,
    required this.temperature,
    required this.saturation,
    required this.tint, // <--- FITUR BARU: TINT
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
  var tint = 0.0.obs; // <--- FITUR BARU: TINT
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
    tint.value = 0.0; // <--- FITUR BARU: TINT
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
      tint: tint.value, // <--- FITUR BARU: TINT
      isBlackAndWhite: isBlackAndWhite.value,
    ));
    currentIndex.value = history.length - 1;
  }

  void _applyState(EditorState state) {
    exposure.value = state.exposure;
    contrast.value = state.contrast;
    temperature.value = state.temperature;
    saturation.value = state.saturation;
    tint.value = state.tint; // <--- FITUR BARU: TINT
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

  Future<void> saveToWorkspace(String draftName) async {
    if (selectedImage.value == null) return;
    
    Map<String, dynamic> newDraft = {
      'imagePath': selectedImage.value!.path,
      'fileName': draftName, 
      'exposure': exposure.value,
      'contrast': contrast.value,
      'temperature': temperature.value,
      'saturation': saturation.value,
      'tint': tint.value, // <--- FITUR BARU: TINT
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

  String _getDefaultDraftName() {
    final now = DateTime.now();
    String day = now.day.toString().padLeft(2, '0');
    String month = now.month.toString().padLeft(2, '0');
    String year = now.year.toString();
    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    
    return "Edit_${day}-${month}-${year}_$hour:$minute";
  }

  void _processSavingDraft(String customName) {
    String finalName = customName;
    if (finalName.isEmpty) {
      finalName = _getDefaultDraftName(); 
    }

    saveToWorkspace(finalName).then((_) {
      resetAllSettings();
      selectedImage.value = null;

      if (Get.isRegistered<DraftController>()) {
        Get.find<DraftController>().loadDrafts();
      }

      Get.back(); 
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
          TextButton(
            onPressed: () {
              Get.back(); 
              resetAllSettings();
              selectedImage.value = null;
              Get.back(); 
            },
            child: const Text('Jangan Simpan', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back(); 
              _processSavingDraft(nameController.text.trim());
            },
            child: const Text('Simpan Draft', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      barrierDismissible: false, 
    );
  }

  void resetAllSettings() {
    currentMode.value = EditorMode.edit;
    currentSubMenu.value = EditSubMenu.light;
    
    exposure.value = 0.0; 
    contrast.value = 0.0; 
    temperature.value = 0.0;
    saturation.value = 0.0; 
    tint.value = 0.0; // <--- FITUR BARU: TINT
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
    
    // --- PENYESUAIAN MATEMATIS UNTUK TEMP & TINT ---
    double tempAdjust = temperature.value / 250.0; 
    double tintAdjust = tint.value / 250.0; // Plus = Magenta, Minus = Hijau
    
    // Jika tint positif (magenta), kita tambah Merah & Biru, dan kurangi Hijau
    double rAdjust = tempAdjust + tintAdjust;
    double bAdjust = -tempAdjust + tintAdjust;
    double gAdjust = (tempAdjust * 0.3) - tintAdjust; 

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
    // Fallback ke 0.0 jika membuka draft lama yang belum punya slider Tint
    tint.value = data['tint'] ?? 0.0; 
    isBlackAndWhite.value = data['isBlackAndWhite'];
    
    Get.toNamed(AppRoutes.EDITOR); 
  }
}

class DraftController extends GetxController {
  var savedDrafts = <Map<String, dynamic>>[].obs;
  
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
  
  void startSelection(String path) {
    toggleSelection(path); 
  }

  void toggleSelection(String path) {
    if (selectedPaths.contains(path)) {
      selectedPaths.remove(path);
      if (selectedPaths.isEmpty) {
        isSelectionMode.value = false;
      }
    } else {
      selectedPaths.add(path);
      if (!isSelectionMode.value) {
        isSelectionMode.value = true;
      }
    }
  }

  void cancelSelection() {
    isSelectionMode.value = false;
    selectedPaths.clear();
  }

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
              Get.back(); 
              final prefs = await SharedPreferences.getInstance();
              String? existing = prefs.getString('editor_drafts_list');
              if (existing != null) {
                List<dynamic> drafts = jsonDecode(existing);
                drafts.removeWhere((d) => selectedPaths.contains(d['imagePath']));
                await prefs.setString('editor_drafts_list', jsonEncode(drafts));
              }
              cancelSelection();
              loadDrafts(); 
              Get.snackbar('🗑️ Terhapus', 'Draft berhasil dihapus.', backgroundColor: Colors.blueGrey.shade900, colorText: Colors.white, snackPosition: SnackPosition.TOP);
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  void showRenameDialog() {
    if (selectedPaths.length != 1) return; 
    String targetPath = selectedPaths.first;
    
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
              Get.back(); 
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
              loadDrafts(); 
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }
}