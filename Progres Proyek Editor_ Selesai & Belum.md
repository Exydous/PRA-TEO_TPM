✅ Fitur yang Sudah Selesai (Ready)
1. Fondasi & Navigasi
Sistem Auth: Layar Login sudah terintegrasi.
Bottom Navigation: Navigasi utama antara Galeri, Utilities, Feedback, dan Profile.
Image Picker: Fungsi mengambil foto dari galeri HP ke dalam aplikasi.
2. Core Editor (Layar Utama Edit)
UI Editor Profesional: Mode layar penuh dengan latar belakang hitam ala Lightroom.
Live Preview: Foto langsung merespons perubahan slider melalui Color Matrix.
Alat Crop & Rotasi: Integrasi image_cropper dengan berbagai pilihan rasio dan fungsi putar.
Menu Light & Color: Slider Exposure, Contrast, Temperature, Saturation, dan tombol Black & White.
3. Utilities: Mini-Game "Color Match"
Gameplay & Logika: Fase memori 5 detik, tebakan berbasis HSL (lebih intuitif).
UI Presisi: Custom slider dan tombol submit dengan ikon bullseye yang posisinya aman dari batas bawah layar.
Sistem Skor: Kalkulasi akurasi per ronde (4 ronde) dan layar Final Score.
4. Utilities: Photographer Assistant (LBS & API) ✨ (Tambahan Baru)
Location-Based Services (LBS): Berhasil mengambil koordinat GPS langsung dari perangkat menggunakan geolocator beserta konfigurasi permission lokasi di iOS (Info.plist).
Web Service/API 1 (Sunrise-Sunset): Terhubung dengan API untuk menghitung waktu Golden Hour secara real-time berdasarkan titik GPS pengguna.
Sistem Anti-Gagal (Fallback): Kodingan Spot Finder sudah disiapkan dan diuji menggunakan Data Dummy, memastikan aplikasi tetap berjalan sempurna saat dipresentasikan meskipun tanpa API Key.

🚧 Fitur yang Belum Dibuat (Misi Selanjutnya)
1. Sensor Goyang (Shake to Reset) — Syarat Wajib TPM
Implementasi package sensors_plus.
Logika mendeteksi guncangan HP di layar Editor untuk mereset semua slider kembali ke nol.
2. Integrasi API Lanjutan (Opsional untuk Nilai Plus) ✨ (Tambahan Baru)
Geoapify API: Mengganti Data Dummy di fitur Photographer Assistant agar memunculkan spot foto yang 100% akurat.
Gemini AI API: Membuat fitur AI Caption & Hashtag Generator berbasis foto.
FreeCurrency API: Membuat kalkulator tarif (Rate Card) di menu Profile.
3. Simpan Foto (Save to Gallery)
Menghubungkan tombol centang (✔️) untuk merender hasil akhir dan menyimpannya secara permanen ke galeri HP.
4. Konten Tab Tambahan
Pengembangan UI/Fungsi sederhana untuk tab Feedback dan Profile. 

