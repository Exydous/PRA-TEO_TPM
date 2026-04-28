import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/payment_controller.dart'; 
import '../../utilities/preset_store/controllers/preset_store_controller.dart'; 

class PaymentScreen extends StatelessWidget {
  PaymentScreen({super.key});

  final PaymentController controller = Get.put(PaymentController());

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> preset = Get.arguments ?? {};
    final String presetName = preset['name'] ?? 'Premium Preset';
    final String presetAuthor = preset['author'] ?? 'Pro-Editor Official';
    final String presetImage = preset['thumbnail_url'] ?? '';

    final double basePrice = (preset['price_usd'] as num?)?.toDouble() ?? 0.0;
    final double serviceFee = basePrice * 0.1; 
    final double totalPrice = basePrice + serviceFee;

    final storeCtrl = Get.find<PresetStoreController>();

    const bgColor = Color(0xFF12141D); 
    const cardColor = Color(0xFF1E2230); 
    const primaryBlue = Color(0xFF1E3A8A); 
    const textMain = Colors.white;
    const textSecondary = Colors.white54;
    const accentYellow = Color.fromARGB(255, 0, 212, 255); 

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Get.back(),
        ),
        title: const Text('Pembayaran', style: TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KARTU PRESET ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 70, height: 90, color: Colors.white12, 
                      child: presetImage.isNotEmpty
                          ? Image.network(presetImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54))
                          : const Icon(Icons.color_lens, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(presetName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('by $presetAuthor', style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: accentYellow, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Akses Selamanya', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- RINCIAN HARGA ---
            Obx(() => storeCtrl.isCurrencyLoading.value
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white54)))
              : Column(
                  children: [
                    _buildPriceRow('Harga Preset', storeCtrl.getConvertedPrice(basePrice), textSecondary, textMain),
                    const SizedBox(height: 12),
                    _buildPriceRow('Biaya Layanan', storeCtrl.getConvertedPrice(serviceFee), textSecondary, textMain),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white12)),
                    _buildPriceRow('Total Pembayaran', storeCtrl.getConvertedPrice(totalPrice), textMain, textMain, isBold: true),
                  ],
                )
            ),
            
            const SizedBox(height: 32),

            // --- METODE PEMBAYARAN DINAMIS ---
            const Text('Pilih Metode Pembayaran', style: TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Obx(() {
              // Mengambil list terbaru sesuai mata uang
              final currentMethods = controller.currentPaymentMethods;

              return Container(
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                child: Column(
                  children: currentMethods.map((methodMap) {
                    String methodName = methodMap['name']!;
                    String methodIcon = methodMap['icon']!;
                    bool isSelected = controller.selectedMethod.value == methodName;
                    bool isLast = methodMap == currentMethods.last;
                    
                    return Column(
                      children: [
                        ListTile(
                          onTap: () => controller.selectMethod(methodName),
                          leading: Container(
                            width: 36, height: 36,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white, // Latar putih agar logo gopay/ovo jelas
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Memanggil ikon asli dari aset lokal
                            child: Image.asset(
                              methodIcon,
                              fit: BoxFit.contain,
                              // Fallback jika lupa memasukkan gambar ke folder assets
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: Colors.black45, size: 20),
                            ),
                          ),
                          title: Text(
                            methodName,
                            style: TextStyle(color: isSelected ? textMain : textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.radio_button_checked, color: Colors.blueAccent)
                              : const Icon(Icons.radio_button_unchecked, color: Colors.white24),
                        ),
                        if (!isLast) const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
      
      // --- BOTTOM BAR ---
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(color: bgColor, border: Border(top: BorderSide(color: Colors.white12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Harga', style: TextStyle(color: textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Obx(() => storeCtrl.isCurrencyLoading.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(storeCtrl.getConvertedPrice(totalPrice), style: const TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: controller.processPayment,
                icon: const Text('Bayar Sekarang', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                label: const Icon(Icons.lock_outline, color: Colors.black, size: 16),
                style: ElevatedButton.styleFrom(backgroundColor: accentYellow, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String title, String amount, Color titleColor, Color amountColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: titleColor, fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(amount, style: TextStyle(color: amountColor, fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}