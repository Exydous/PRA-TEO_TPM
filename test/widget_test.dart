// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pastikan import ini sesuai dengan nama project-mu di pubspec.yaml
import 'package:tugas_akhir/main.dart'; 

void main() {
  testWidgets('Aplikasi Pro-Editor berjalan dan merender layar Login', (WidgetTester tester) async {
    // 1. Build aplikasi kita dan panggil frame pertama.
    // Ganti MyApp() menjadi ProEditorApp()
    await tester.pumpWidget(const ProEditorApp(isLoggedIn: false));

    // 2. Karena kita menggunakan GetX untuk navigasi awal, 
    // kita butuh pumpAndSettle agar animasi transisi/loading halaman selesai.
    await tester.pumpAndSettle();

    // 3. Verifikasi apakah aplikasi berhasil membuka LoginScreen.
    // Di LoginScreen kita tadi, ada teks 'Pro-Editor' di AppBar.
    expect(find.text('Pro-Editor'), findsWidgets);
    
    // Atau kita bisa mencari teks dummy yang kita buat tadi
    expect(find.text('Halaman Login Belum Dibuat'), findsOneWidget);
  });
}