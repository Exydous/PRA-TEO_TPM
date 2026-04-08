import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

// Light dan Color
enum EditorMode { crop, edit }
enum EditSubMenu { light, color }

class EditorController extends GetxController {
  Rx<File?> selectedImage = Rx<File?>(null);
  
  var currentMode = EditorMode.edit.obs;
  var currentSubMenu = EditSubMenu.light.obs;

  // stats slider
  var exposure = 0.0.obs; 
  var contrast = 0.0.obs; 
  
  var temperature = 5000.0.obs; 
  var saturation = 0.0.obs; 
  var isBlackAndWhite = false.obs;

  final ImagePicker _picker = ImagePicker();

  Future<void> openCropTool() async {
    if (selectedImage.value == null) return;

    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: selectedImage.value!.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop & Rotate',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF1A1A1A),
            activeControlsWidgetColor: const Color(0xFF4FC3F7), 
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'Crop & Rotate',
            aspectRatioLockEnabled: false,
            resetButtonHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        selectedImage.value = File(croppedFile.path);
      }
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

  void cancelEditing() {
    selectedImage.value = null;
    Get.back();
  }

  void resetAllSettings() {
    currentMode.value = EditorMode.edit;
    currentSubMenu.value = EditSubMenu.light;
    
    exposure.value = 0.0;
    contrast.value = 0.0;
    temperature.value = 5000.0;
    saturation.value = 0.0;
    isBlackAndWhite.value = false;
  }

  // --- MATRIKS WARNA INTI ---
  List<double> get combinedColorMatrix {
    double b = exposure.value; 
    double c = 1.0 + (contrast.value / 100.0);
    
    double baseSat = isBlackAndWhite.value ? -100.0 : saturation.value;
    double s = 1.0 + (baseSat / 100.0);
    
    double temp = (temperature.value - 5000) / 50.0; 

    const double lumR = 0.2126;
    const double lumG = 0.7152;
    const double lumB = 0.0722;

    double sr = (1 - s) * lumR;
    double sg = (1 - s) * lumG;
    double sb = (1 - s) * lumB;

    return [
      c * (sr + s) + (temp * 0.01), c * sg, c * sb - (temp * 0.01), 0, b, // Red
      c * sr, c * (sg + s), c * sb, 0, b,                               // Green
      c * sr - (temp * 0.01), c * sg, c * (sb + s) + (temp * 0.01), 0, b, // Blue
      0, 0, 0, 1, 0,                                                    // Alpha
    ];
  }
}