✅ Fitur yang Sudah Selesai (Ready) - UPDATED
1. Fondasi, Navigasi & Cloud Auth

- Sistem Auth (Supabase): Login & Register sudah terintegrasi penuh dengan database Cloud.

- Security Logic: Berhasil menerapkan Row Level Security (RLS) sehingga data antar pengguna tidak akan pernah tertukar.

- Dynamic UI Auth: Layar login yang bisa berubah mode (Login/Register) secara reaktif menggunakan GetX.

2. Core Editor & Intelligent Processing

- (Semua fitur sensor, AI Color Transfer, dan slider tetap tersedia).

- [NEW] Cloud-Sync Editor: Fungsi resumeDraft sekarang mampu mengunduh file secara asynchronous dari Cloud Storage ke memori sementara HP untuk diedit kembali.

3. Cloud Workspace Management (Pengganti Lokal)

- Migration to Supabase: Meninggalkan SharedPreferences dan beralih ke PostgreSQL (Tabel drafts).

- Supabase Storage Integration: Foto draf tidak lagi disimpan di folder HP, melainkan di-upload ke Bucket Storage Supabase (Global Access).

- Cloud Selection Mode: Fitur hapus dan ganti nama draf kini langsung melakukan update ke database pusat secara real-time.

- Auto-Cleanup Logout: Sistem pembersihan cache dan controller saat logout untuk memastikan privasi data.

4. Tab Profile (Layar Identitas)

- User Identity: Menampilkan Nama (dari metadata) dan Email pengguna yang sedang aktif secara dinamis.

- Secure Logout: Tombol logout dengan dialog konfirmasi dan proteksi pembersihan data memori (Get.delete).

🚧 Fitur yang Belum Dibuat (Misi Selanjutnya)
1. Integrasi API Lanjutan (Eksplorasi Data)

- Geoapify API: Mengganti Data Dummy di fitur Photographer Assistant agar memunculkan spot foto yang akurat sesuai lokasi GPS user.

- FreeCurrency API: Kalkulator tarif jasa fotografer di menu Profile (konversi mata uang untuk Rate Card).

2. Pengembangan Konten Tab Sampingan

- Tab Feedback: Pembuatan UI Form feedback. Rencananya bisa dikirim ke tabel feedbacks di Supabase agar kamu bisa membacanya dari dashboard.

- Profile Page Enhancement: Menambahkan statistik (misal: "Jumlah Draft Tersimpan") untuk mempercantik halaman profil.