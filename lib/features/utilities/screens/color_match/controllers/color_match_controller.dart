import 'dart:async';
import 'dart:math';
// import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum GameState { menu, leaderboard, memorize, guess, result, finalScore }

class ColorMatchController extends GetxController {
  var currentState = GameState.menu.obs;
  
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

  // Data Dummy Leaderboard
  final leaderboardData = [
    {'name': 'Alex (Pro Editor)', 'score': '94.5%'},
    {'name': 'Siti Designer', 'score': '88.2%'},
    {'name': 'Budi Colorist', 'score': '75.0%'},
  ];

  // --- LOGIKA GAME ---
  void startSoloGame() {
    round.value = 1;
    totalScore.value = 0.0;
    _generateNewTarget();
    _startMemorizePhase();
  }

  void _generateNewTarget() {
    final random = Random();
    targetHue.value = random.nextDouble() * 360;
    targetSat.value = (random.nextDouble() * 60) + 40; // 40-100% agar warna tidak terlalu abu-abu
    targetLight.value = (random.nextDouble() * 60) + 20; // 20-80% agar tidak hitam/putih pekat
    
    // Reset slider user ke tengah
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
        currentState.value = GameState.guess; // Waktu habis, pindah ke layar tebak
      }
    });
  }

  void submitGuess() {
    // Hitung akurasi HSL sederhana
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
    }
  }

  void backToMenu() {
    _timer?.cancel();
    currentState.value = GameState.menu;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}