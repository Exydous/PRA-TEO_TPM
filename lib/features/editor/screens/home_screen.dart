import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EditorController editorCtrl = Get.put(EditorController());
    final DraftController draftCtrl = Get.put(DraftController());

    return Scaffold(
      backgroundColor: Colors.black,
      
      // --- APP BAR DINAMIS ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => AppBar(
          backgroundColor: draftCtrl.isSelectionMode.value ? const Color(0xFF1A1A1A) : Colors.black,
          elevation: 0,
          title: Text(
            draftCtrl.isSelectionMode.value 
                ? '${draftCtrl.selectedIds.length} Dipilih'
                : 'Gallery & Workspace', 
            style: const TextStyle(color: Colors.white)
          ),
          leading: draftCtrl.isSelectionMode.value
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: draftCtrl.cancelSelection,
                )
              : null,
          actions: draftCtrl.isSelectionMode.value
              ? [
                  if (draftCtrl.selectedIds.length == 1)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      tooltip: 'Change Name',
                      onPressed: draftCtrl.showRenameDialog,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Delete Draft',
                    onPressed: draftCtrl.deleteSelectedDrafts,
                  ),
                  const SizedBox(width: 8),
                ]
              : [],
        )),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOMBOL BIKIN BARU
            InkWell(
              onTap: () {
                if (draftCtrl.isSelectionMode.value) draftCtrl.cancelSelection();
                editorCtrl.pickImageAndOpenEditor();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.add_photo_alternate, size: 48, color: Colors.blueAccent),
                    SizedBox(height: 12),
                    Text('Edit Photos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 2. AREA WORKSPACE & SEARCH BAR
            Obx(() {
              // Sembunyikan bagian bawah ini jika memang belum pernah punya draft sama sekali
              if (draftCtrl.savedDrafts.isEmpty) {
                return const SizedBox.shrink(); 
              }

              // Tarik data yang sudah difilter (Pencarian Lokal)
              final draftsToDisplay = draftCtrl.filteredDrafts;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FITUR BARU: SEARCH BAR ---
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search draft...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      draftCtrl.updateSearch(value); // Memicu filter di Controller
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text('Last Workspace', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Jika hasil pencarian kosong (tidak ada yang cocok)
                  if (draftsToDisplay.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32.0),
                        child: Text("Draft not found", style: TextStyle(color: Colors.white38, fontSize: 16)),
                      ),
                    )
                  else
                    // Menampilkan list berdasarkan 'draftsToDisplay' (bukan savedDrafts lagi)
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(), 
                      shrinkWrap: true, 
                      itemCount: draftsToDisplay.length,
                      itemBuilder: (context, index) {
                        final draft = draftsToDisplay[index];
                        
                        return Obx(() {
                          final isSelected = draftCtrl.selectedIds.contains(draft['id']);
                          final isSelectionMode = draftCtrl.isSelectionMode.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orangeAccent.withOpacity(0.1) : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.orangeAccent : Colors.orangeAccent.withOpacity(0.5),
                                width: isSelected ? 2 : 1, 
                              ),
                            ),
                            child: Stack(
                              children: [
                                // LAYER 1: KARTU UTAMA
                                InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onLongPress: () {
                                    if (!isSelectionMode) {
                                      draftCtrl.startSelection(draft['id']);
                                    }
                                  },
                                  onTap: () {
                                    if (isSelectionMode) {
                                      draftCtrl.toggleSelection(draft['id']);
                                    } else {
                                      editorCtrl.resumeDraft(draft);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)), 
                                        child: Image.network(
                                          draft['image_url'],
                                          width: 100, 
                                          height: 120,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              width: 100, height: 120, color: Colors.grey[900], 
                                              child: const Center(child: CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 2))
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 100, height: 120, color: Colors.grey[900], 
                                            child: const Icon(Icons.broken_image, color: Colors.white54)
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                draft['draft_name'] ?? 'No Name',
                                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                maxLines: 2, 
                                                overflow: TextOverflow.ellipsis, 
                                              ),
                                              const SizedBox(height: 6),
                                              Text('Exposure: ${(draft['exposure'] ?? 0).toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                              Text('Saturation: ${(draft['saturation'] ?? 0).toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(right: 16.0),
                                        child: Icon(Icons.chevron_right, color: Colors.orangeAccent),
                                      ),
                                    ],
                                  ),
                                ),

                                // LAYER 2: KOTAK CENTANG
                                if (isSelectionMode)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: IgnorePointer(
                                      child: isSelected
                                          ? const Icon(Icons.check_box, color: Colors.orangeAccent, size: 28)
                                          : const Icon(Icons.check_box_outline_blank, color: Colors.white54, size: 28),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }); 
                      },
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}