import 'dart:io';
import 'package:image/image.dart' as img;

class ColorTransferService {
  // Fungsi ringan untuk mengekstrak "DNA Warna" dari gambar referensi
  static Future<Map<String, double>?> extractColorStyle(File referenceImage) async {
    try {
      final bytes = await referenceImage.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) return null;

      // OPTIMASI: Resize ke 50x50 agar proses komputasi histogram sangat ringan
      img.Image resized = img.copyResize(originalImage, width: 50, height: 50);

      double totalR = 0, totalG = 0, totalB = 0;
      double totalLuma = 0;
      int pixelCount = resized.width * resized.height;

      // Mengekstrak nilai RGB dan Luminance setiap pixel
      for (var p in resized) {
        totalR += p.r;
        totalG += p.g;
        totalB += p.b;
        // Rumus persepsi cahaya mata manusia
        totalLuma += (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      }

      // Menghitung rata-rata keseluruhan
      double avgR = totalR / pixelCount;
      double avgG = totalG / pixelCount;
      double avgB = totalB / pixelCount;
      double avgLuma = totalLuma / pixelCount;

      // --- MENGUBAH STATISTIK MENJADI NILAI SLIDER ---
      
      // 1. Exposure: Bandingkan Luma referensi dengan titik tengah (127)
      double exposureObj = ((avgLuma - 127) / 127) * 60; 

      // 2. Temperature: Cari selisih dominasi Merah vs Biru
      double tempObj = ((avgR - avgB) / 255) * 80;

      // --- FITUR BARU: 3. Tint (Sumbu Hijau-Magenta) ---
      // Magenta adalah gabungan Merah+Biru. Jika Merah+Biru jauh lebih tinggi dari Hijau, berarti itu Magenta/Pink!
      double avgMagenta = (avgR + avgB) / 2;
      // Jika hasil ini positif = Magenta. Jika negatif = Hijau.
      double tintObj = ((avgMagenta - avgG) / 255) * 80;

      // 3. Saturation: Hitung deviasi/variansi warna. 
      // Jika R,G,B nilainya mirip, berarti warnanya pudar/monokrom (Saturasi minus).
      double colorVariance = ((avgR - avgLuma).abs() + (avgG - avgLuma).abs() + (avgB - avgLuma).abs()) / 3;
      double satObj = ((colorVariance - 20) / 30) * 80;

      // 4. Contrast: Film look biasanya punya kontras agak tinggi jika luma-nya rendah
      double contrastObj = avgLuma < 100 ? 20.0 : 5.0;

      return {
        'exposure': exposureObj.clamp(-100.0, 100.0),
        'contrast': contrastObj.clamp(-100.0, 100.0),
        'temperature': tempObj.clamp(-100.0, 100.0),
        'tint': tintObj.clamp(-100.0, 100.0),
        'saturation': satObj.clamp(-100.0, 100.0),
      };
    } catch (e) {
      return null;
    }
  }
}