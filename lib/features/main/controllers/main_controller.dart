import 'package:get/get.dart';

class MainController extends GetxController {
  // Variabel reaktif (obs) untuk menyimpan index tab yang sedang aktif
  var selectedIndex = 0.obs;

  // Fungsi untuk mengubah tab saat ikon di bawah ditekan
  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }
}