✅ Fitur yang Sudah Selesai (Ready) - UPDATED
1. Fondasi, Navigasi & Cloud Auth

- Sistem Auth (Supabase): Login & Register sudah terintegrasi penuh dengan database Cloud.

- [NEW] Advanced Security: Menerapkan enkripsi ganda. Password divalidasi dengan RegEx (Kombinasi Kapital, Angka, Karakter Spesial) lalu di-hash menggunakan algoritma SHA-256 dari sisi aplikasi sebelum dikirim dan dienkripsi ulang dengan bcrypt oleh Supabase.

- Security Logic: Berhasil menerapkan Row Level Security (RLS) sehingga data antar pengguna tidak akan pernah tertukar.

- Dynamic UI Auth: Layar login yang bisa berubah mode (Login/Register) secara reaktif menggunakan GetX.

2. Core Editor & Intelligent Processing

- Sensor & Hardware: Deteksi cahaya ruangan (Lux Sensor) dan Shake to Reset berfungsi normal.

- Cloud-Sync Editor: Fungsi resumeDraft mampu mengunduh file secara asynchronous dari Cloud Storage ke memori sementara HP untuk diedit kembali.

- My Presets Integration: Terhubung langsung dengan database kepemilikan. Pengguna bisa memunculkan Bottom Sheet berisi daftar preset miliknya dan mengaplikasikan efek Data-Driven (angka adjustment ditarik langsung dari Cloud) dengan sekali klik.

- [NEW] AI Color Transfer: Logika inti pengolahan Histogram RGB dan Luma untuk mengambil referensi warna dari foto/film lain sudah dieksekusi dan terhubung dengan EditorScreen.

3. Cloud Workspace Management

- Migration to Supabase: Meninggalkan penyimpanan lokal dan beralih ke PostgreSQL (Tabel drafts).

- Supabase Storage Integration: Foto draf di-upload ke Bucket Storage Supabase (Global Access).

- Cloud Selection Mode: Fitur hapus dan ganti nama draf langsung melakukan update ke database pusat secara real-time.

- Auto-Cleanup Logout: Sistem pembersihan cache dan controller saat logout untuk memastikan privasi data.

4. Tab Profile (Layar Identitas & Kepemilikan)

- User Identity: Menampilkan Nama dan Email pengguna yang sedang aktif secara dinamis.

- Secure Logout: Tombol logout dengan perlindungan pembersihan data memori.

- Koleksi Preset (Ownership): Halaman profil kini menampilkan Grid View berisi daftar preset premium yang telah berhasil dibeli oleh user.

5. Dynamic Preset Store & Monetization

- Katalog Cloud (Data-Driven): Daftar preset, gambar thumbnail, harga dasar, dan pengaturan efek (exposure, contrast, dll) ditarik langsung dari Supabase.

- Real-time Currency: Harga preset otomatis dikonversi secara real-time menggunakan FreeCurrency API sesuai mata uang yang dipilih pengguna (IDR, USD, EUR).

- Sistem Transaksi & Relasi (RLS): Pembelian dicatat di tabel relasi user_presets. UI sangat reaktif—tombol "Beli" akan otomatis berubah menjadi "Owned" (Milikmu) sesaat setelah transaksi berhasil.

6. [NEW] Photographer Assistant (Location & Time Optimizer)

- Dynamic Sun Data & Timezone: Terintegrasi dengan API Sunrise-Sunset yang dilengkapi kalkulator zona waktu dinamis (WIB, WITA, WIT, LONDON) secara real-time.

- Geoapify Smart Radar: Memindai spot foto, taman, dan tempat bersejarah di sekitar user secara presisi tanpa error data kosong/zombie.

- Interactive Maps: Menampilkan peta OpenStreetMap (OSM) bertema Dark Mode interaktif menggunakan flutter_map dengan pin lokasi dan navigasi otomatis ke Google Maps.

🚧 Fitur yang Belum Dibuat (Misi Final)
1. Rate Card Calculator (Tab Profile)

- Membuat UI Kalkulator tarif jasa fotografer yang menggunakan layanan Currency API (yang sudah ada) agar fotografer bisa menghitung dan menunjukkan tarif jasanya dalam berbagai mata uang (IDR, USD, EUR).

2. Tab Feedback (Ekstra)

- Pembuatan UI Form feedback yang akan menembak data masukan/saran dari user langsung ke tabel feedbacks di Supabase.