import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum GameState { menu, leaderboard, memorize, guess, result, finalScore }

class ColorMatchController extends GetxController {
  final supabase = Supabase.instance.client;
  
  var currentState = GameState.menu.obs;
  
  // --- USERNAME ---
  var gameUsername = ''.obs;
  
  // --- CLOUD LEADERBOARD DATA ---
  var globalLeaderboard = <Map<String, dynamic>>[].obs;
  var isLoadingLeaderboard = false.obs;

  // Variabel Game
  var round = 1.obs;
  var totalScore = 0.0.obs;
  var lastAccuracy = 0.0.obs;
  var countdown = 5.obs;
  Timer? _timer;

  // Warna Target (Acak)
  var targetHue = 0.0.obs;
  var targetSat = 0.0.obs;
  var targetLight = 0.0.obs;

  // Warna Tebakan User
  var userHue = 180.0.obs;
  var userSat = 50.0.obs;
  var userLight = 50.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDefaultUsername();
    fetchLeaderboard(); // Ambil data top player saat aplikasi dibuka
  }

  // --- LOGIKA CLOUD (SUPABASE) ---

  // Ambil nama dari profil akun
  void _loadDefaultUsername() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      gameUsername.value = user.userMetadata?['display_name'] ?? 'Player';
    } else {
      gameUsername.value = 'Guest';
    }
  }

  // Ambil TOP 10 dari Tabel 'color_match_scores'
  Future<void> fetchLeaderboard() async {
    try {
      isLoadingLeaderboard.value = true;
      final data = await supabase
          .from('color_match_scores')
          .select('username, accuracy_score')
          .order('accuracy_score', ascending: false)
          .limit(10);
      
      globalLeaderboard.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Gagal mengambil leaderboard: $e");
    } finally {
      isLoadingLeaderboard.value = false;
    }
  }

  // Kirim Skor Akhir ke Supabase
  Future<void> submitFinalScoreToCloud() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    double finalAvg = totalScore.value / 4;

    try {
      await supabase.from('color_match_scores').insert({
        'user_id': user.id,
        'username': gameUsername.value,
        'accuracy_score': finalAvg,
      });
      fetchLeaderboard(); // Refresh data setelah berhasil simpan
    } catch (e) {
      debugPrint("Gagal kirim skor: $e");
    }
  }

  // --- LOGIKA GAME ---

  void updateGameUsername(String newName) {
    if (newName.trim().isNotEmpty) {
      gameUsername.value = newName.trim();
    }
  }

  void startSoloGame() {
    round.value = 1;
    totalScore.value = 0.0;
    _generateNewTarget();
    _startMemorizePhase();
  }

  void _generateNewTarget() {
    final random = Random();
    targetHue.value = random.nextDouble() * 360;
    targetSat.value = (random.nextDouble() * 60) + 40; 
    targetLight.value = (random.nextDouble() * 60) + 20; 
    
    userHue.value = 180.0;
    userSat.value = 50.0;
    userLight.value = 50.0;
  }

  void _startMemorizePhase() {
    currentState.value = GameState.memorize;
    countdown.value = 5;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 1) {
        countdown.value--;
      } else {
        timer.cancel();
        currentState.value = GameState.guess; 
      }
    });
  }

  void submitGuess() {
    double diffH = (targetHue.value - userHue.value).abs() / 360;
    double diffS = (targetSat.value - userSat.value).abs() / 100;
    double diffL = (targetLight.value - userLight.value).abs() / 100;
    
    double avgDiff = (diffH + diffS + diffL) / 3;
    lastAccuracy.value = (1.0 - avgDiff) * 100;
    totalScore.value += lastAccuracy.value;
    
    currentState.value = GameState.result;
  }

  void nextRound() {
    if (round.value < 4) {
      round.value++;
      _generateNewTarget();
      _startMemorizePhase();
    } else {
      currentState.value = GameState.finalScore;
      submitFinalScoreToCloud(); // OTOMATIS SIMPAN KE CLOUD SAAT GAME SELESAI
    }
  }

  void backToMenu() {
    _timer?.cancel();
    currentState.value = GameState.menu;
    _loadDefaultUsername();
    fetchLeaderboard(); // Pastikan data terbaru muncul saat kembali
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}