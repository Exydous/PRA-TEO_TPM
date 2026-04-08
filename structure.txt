lib/
│
├── core/                   # (Pusat Pengaturan Aplikasi)
│   ├── constants/          # Warna (app_colors.dart), teks, ukuran baku
│   ├── utils/              # Fungsi bantuan (misal: format tanggal, kalkulasi)
│   ├── theme/              # Tema global aplikasi (Light/Dark mode)
│   └── routes/             # Pendaftaran rute GetX
│       ├── app_pages.dart  # Daftar GetPage()
│       └── app_routes.dart # Konstanta nama rute (misal: static const EDITOR = '/editor')
│
├── features/               # (Fitur Utama Aplikasi - Dipecah per Modul)
│   │
│   ├── auth/               # ✅ [SELESAI] Modul Login/Register
│   │   ├── bindings/       
│   │   ├── controllers/    
│   │   └── screens/        
│   │
│   ├── main/               # ✅ [SELESAI] Kerangka Tab Bawah (Bottom Nav Bar)
│   │   ├── bindings/       
│   │   ├── controllers/    # MainController (mengatur perpindahan tab 0-3)
│   │   └── screens/        # MainScreen (menampung Scaffold dan BottomNavigationBar)
│   │
│   ├── gallery/            # ✅ [SELESAI] Tab 1: Galeri & Pilih Foto
│   │   ├── controllers/    # Logika ImagePicker untuk memilih foto
│   │   └── screens/        # Tampilan grid foto atau tombol "Pilih Foto"
│   │
│   ├── utilities/          # ✅ [SELESAI] Tab 2: Alat Tambahan & Mini Game
│   │   ├── screens/        # utilities_screen.dart (Daftar menu Card)
│   │   └── color_match/    # Sub-fitur Game Tebak Warna
│   │       ├── controllers/ # color_match_controller.dart (Logika HSL & Timer)
│   │       └── screens/     # color_match_screen.dart (UI Game)
│   │
│   ├── feedback/           # 🚧 [AKAN DIBUAT] Tab 3: Masukan/Saran
│   │   ├── controllers/    # Mengatur form input teks
│   │   └── screens/        # Layar untuk dosen/user memberi nilai/kesan
│   │
│   ├── profile/            # 🚧 [AKAN DIBUAT] Tab 4: Profil User
│   │   ├── controllers/    
│   │   └── screens/        # Info biodata pembuat aplikasi (Syarat TPM)
│   │
│   └── editor/             # 🚧 [FOKUS UTAMA] Ruang Kerja Pengeditan
│       ├── bindings/       
│       ├── controllers/    # editor_controller.dart (Slider warna, matriks, SENSOR GOYANG, SAVE)
│       └── screens/        # editor_screen.dart (UI Fullscreen hitam, tombol Crop/Edit)
│
├── shared/                 # (Komponen UI yang Bisa Dipakai Ulang)
│   └── widgets/            # Custom Button, Custom Dialog, dll.
│
└── main.dart               # Titik awal (Entry Point) & inisialisasi GetX/Env