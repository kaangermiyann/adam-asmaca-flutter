import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/network_game_room.dart';
import '../providers/network_game_provider.dart';
import '../services/tdk_service.dart';
import '../utils/app_theme.dart';
import '../widgets/hangman_figure.dart';
import '../widgets/keyboard_widget.dart';
import 'home_screen.dart';

class NetworkGameScreen extends StatelessWidget {
  const NetworkGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NetworkGameProvider(),
      child: const _NetworkGameContent(),
    );
  }
}

class _NetworkGameContent extends StatelessWidget {
  const _NetworkGameContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkGameProvider>(
      builder: (context, provider, _) {
        // Bağlantı durumuna göre ekran göster
        if (provider.currentRoom == null) {
          return const _ConnectionScreen();
        }

        final room = provider.currentRoom!;

        switch (room.state) {
          case NetworkGameState.waiting:
            return _LobbyScreen(room: room, provider: provider);
          case NetworkGameState.choosingWord:
            if (provider.isWordChooser) {
              return _WordSelectionScreen(room: room, provider: provider);
            }
            return _WaitingForWordScreen(room: room, provider: provider);
          case NetworkGameState.playing:
            return _PlayingScreen(room: room, provider: provider);
          case NetworkGameState.finished:
            return _RoundEndScreen(room: room, provider: provider);
          case NetworkGameState.gameOver:
            return _GameOverScreen(room: room, provider: provider);
        }
      },
    );
  }
}

// ==================== CONNECTION SCREEN ====================
class _ConnectionScreen extends StatefulWidget {
  const _ConnectionScreen();

  @override
  State<_ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<_ConnectionScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isCreating = true;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NetworkGameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokal Ag Oyunu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Icon(Icons.wifi, size: 50, color: Colors.white),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                'Lokal Ag Oyunu',
                style: Theme.of(context).textTheme.headlineMedium,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Ayni WiFi agindaki cihazlarla oyna',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 32),

              // Tab seçimi
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isCreating = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isCreating ? AppTheme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Oda Olustur',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isCreating ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isCreating = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !_isCreating ? AppTheme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Odaya Katil',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: !_isCreating ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 32),

              // İsim girişi
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Oyuncu ismin',
                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),
              const SizedBox(height: 16),

              // Adres girişi (sadece katılma modunda)
              if (!_isCreating) ...[
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Sunucu adresi (örn: 192.168.1.50:8080)',
                    prefixIcon: Icon(Icons.link, color: AppTheme.textMuted),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.url,
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms),
                const SizedBox(height: 16),
              ],

              // Hata mesajı
              if (provider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Buton
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: provider.isConnecting
                      ? null
                      : () async {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lutfen isim girin')),
                            );
                            return;
                          }

                          if (_isCreating) {
                            await provider.createRoom(name);
                          } else {
                            final address = _addressController.text.trim();
                            if (address.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lutfen sunucu adresi girin')),
                              );
                              return;
                            }
                            await provider.joinRoom(address, name);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                  child: provider.isConnecting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isCreating ? Icons.add : Icons.login),
                            const SizedBox(width: 12),
                            Text(_isCreating ? 'Oda Olustur' : 'Odaya Katil'),
                          ],
                        ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // Bilgi kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.accentColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Nasil Calisir?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('1', 'Bir cihaz "Oda Olustur" ile sunucu olur'),
                    _buildInfoItem('2', 'Diger cihazlar IP adresiyle baglanir'),
                    _buildInfoItem('3', 'Ayni WiFi aginda olmalisiniz'),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== LOBBY SCREEN ====================
class _LobbyScreen extends StatelessWidget {
  final NetworkGameRoom room;
  final NetworkGameProvider provider;

  const _LobbyScreen({required this.room, required this.provider});

  @override
  Widget build(BuildContext context) {
    final allReady = room.players.length >= 2 &&
        room.players.where((p) => !p.isHost).every((p) => p.isReady);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _showLeaveDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Oyun Odasi'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showLeaveDialog(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Sunucu adresi
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Sunucu Adresi',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.serverAddress ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: provider.serverAddress ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Adres kopyalandi!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu adresi diger oyuncularla paylas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, duration: 400.ms),

                const SizedBox(height: 24),

                // Oyuncular listesi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, color: AppTheme.textSecondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Oyuncular (${room.players.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: room.players.length,
                          itemBuilder: (context, index) {
                            final player = room.players[index];
                            return _NetworkPlayerCard(
                              player: player,
                              score: room.scores[player.id],
                              index: index,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Butonlar
                if (!provider.isHost) ...[
                  // Hazır ol butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => provider.toggleReady(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: room.players
                                .firstWhere((p) => p.id == provider.playerId)
                                .isReady
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            room.players.firstWhere((p) => p.id == provider.playerId).isReady
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            room.players.firstWhere((p) => p.id == provider.playerId).isReady
                                ? 'Hazir!'
                                : 'Hazir Ol',
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Ev sahibi için oyunu başlat butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: allReady ? () => provider.startGame() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        disabledBackgroundColor: AppTheme.cardColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow),
                          const SizedBox(width: 12),
                          Text(
                            allReady
                                ? 'Oyunu Baslat'
                                : room.players.length < 2
                                    ? 'En az 2 oyuncu gerekli'
                                    : 'Oyuncular bekleniyor...',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLeaveDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Odadan Ayril'),
        content: const Text('Odadan ayrilmak istediginize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Ayril'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      provider.leaveRoom();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}

class _NetworkPlayerCard extends StatelessWidget {
  final NetworkPlayer player;
  final int? score;
  final int index;

  const _NetworkPlayerCard({
    required this.player,
    required this.score,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: player.isHost
            ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: player.isHost ? AppTheme.primaryGradient : null,
              color: player.isHost ? null : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: player.isHost ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // İsim ve durum
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EV SAHIBI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      player.isReady ? Icons.check_circle : Icons.access_time,
                      size: 14,
                      color: player.isReady ? AppTheme.successColor : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      player.isReady ? 'Hazir' : 'Bekleniyor',
                      style: TextStyle(
                        fontSize: 12,
                        color: player.isReady ? AppTheme.successColor : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Skor
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
        .slideX(begin: -0.1, duration: 400.ms);
  }
}

// ==================== WORD SELECTION SCREEN ====================
class _WordSelectionScreen extends StatefulWidget {
  final NetworkGameRoom room;
  final NetworkGameProvider provider;

  const _WordSelectionScreen({required this.room, required this.provider});

  @override
  State<_WordSelectionScreen> createState() => _WordSelectionScreenState();
}

class _WordSelectionScreenState extends State<_WordSelectionScreen> {
  final _wordController = TextEditingController();
  List<String> _suggestions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    _suggestions = await TDKService.getSuggestedWords(count: 8);
    setState(() {});
  }

  void _submitWord() {
    final word = _wordController.text.trim();
    if (word.length < 3) {
      setState(() => _errorMessage = 'Kelime en az 3 harf olmali');
      return;
    }

    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ]+$').hasMatch(word)) {
      setState(() => _errorMessage = 'Sadece harf kullanin');
      return;
    }

    widget.provider.setWord(word);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Tur bilgisi
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tur ${widget.room.currentRound}/${widget.room.totalRounds}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Bilgi
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.edit, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kelime Sec',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Diger oyuncular tahmin edecek',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Kelime girişi
              TextFormField(
                controller: _wordController,
                decoration: const InputDecoration(
                  hintText: 'Kelimeyi yaz...',
                  prefixIcon: Icon(Icons.edit, color: AppTheme.textMuted),
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              // Onayla butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitWord,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check),
                      SizedBox(width: 12),
                      Text('Kelimeyi Onayla'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Öneriler
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Onerilen Kelimeler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _loadSuggestions,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Yenile'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _suggestions.map((word) {
                  return InkWell(
                    onTap: () {
                      _wordController.text = word.toUpperCase();
                      setState(() => _errorMessage = null);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        word.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== WAITING FOR WORD SCREEN ====================
class _WaitingForWordScreen extends StatelessWidget {
  final NetworkGameRoom room;
  final NetworkGameProvider provider;

  const _WaitingForWordScreen({required this.room, required this.provider});

  @override
  Widget build(BuildContext context) {
    final chooser = room.getWordChooserPlayer();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Icon(Icons.hourglass_empty, size: 60, color: AppTheme.warningColor),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 2000.ms),
              const SizedBox(height: 32),
              Text(
                'Kelime Bekleniyor',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '${chooser?.name ?? "?"} kelime seciyor...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PLAYING SCREEN ====================
class _PlayingScreen extends StatelessWidget {
  final NetworkGameRoom room;
  final NetworkGameProvider provider;

  const _PlayingScreen({required this.room, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isChooser = provider.isWordChooser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Rol bilgisi
                    Text(
                      isChooser ? 'Kelimeyi sen sectir' : 'Kelimeyi tahmin et',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    // Adam asmaca
                    HangmanFigure(
                      wrongGuesses: room.wrongGuesses,
                      maxWrongGuesses: room.maxWrongGuesses,
                    ),
                    const SizedBox(height: 24),
                    // Kelime
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isChooser ? (room.currentWord ?? '') : room.getMaskedWord(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Yanlış harfler
                    if (room.wrongGuesses > 0) _buildWrongLetters(),
                  ],
                ),
              ),
            ),
            // Klavye (sadece tahmin edenler için)
            if (!isChooser)
              Padding(
                padding: const EdgeInsets.all(8),
                child: KeyboardWidget(
                  guessedLetters: room.guessedLetters,
                  currentWord: room.currentWord,
                  enabled: true,
                  onLetterPressed: (letter) => provider.guessLetter(letter),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: provider.remainingSeconds < 30
                  ? AppTheme.errorColor.withValues(alpha: 0.2)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: provider.remainingSeconds < 30
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.formatTime(provider.remainingSeconds),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: provider.remainingSeconds < 30
                        ? AppTheme.errorColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Kalpler
          Row(
            children: List.generate(room.maxWrongGuesses, (index) {
              final isLost = index < room.wrongGuesses;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isLost ? Icons.favorite : Icons.favorite_border,
                  size: 24,
                  color: isLost ? AppTheme.errorColor : AppTheme.textMuted,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWrongLetters() {
    final wrongLetters = room.guessedLetters.where((letter) {
      return !(room.currentWord?.toUpperCase().contains(letter) ?? false);
    }).toList();

    return Column(
      children: [
        const Text(
          'Yanlis Harfler',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: wrongLetters.map((letter) {
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ==================== ROUND END SCREEN ====================
class _RoundEndScreen extends StatelessWidget {
  final NetworkGameRoom room;
  final NetworkGameProvider provider;

  const _RoundEndScreen({required this.room, required this.provider});

  @override
  Widget build(BuildContext context) {
    final guesserWon = room.isWordGuessed();
    final chooser = room.getWordChooserPlayer();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sonuç ikonu
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: guesserWon
                      ? const LinearGradient(colors: [AppTheme.successColor, Color(0xFF059669)])
                      : const LinearGradient(colors: [AppTheme.errorColor, Color(0xFFDC2626)]),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Icon(
                    guesserWon ? Icons.celebration : Icons.sentiment_dissatisfied,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                guesserWon ? 'Kelime Bulundu!' : 'Adam Asildi!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: guesserWon ? AppTheme.successColor : AppTheme.errorColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                guesserWon
                    ? 'Tahmin edenler kazandi!'
                    : '${chooser?.name ?? "Kelime secen"} kazandi!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              // Kelime
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Kelime',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.currentWord ?? '',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Skor tablosu
              _buildScoreBoard(),
              const SizedBox(height: 32),
              // Sonraki tur butonu (sadece host için)
              if (provider.isHost)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => provider.newRound(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: Text(
                      room.currentRound < room.totalRounds ? 'Sonraki Tur' : 'Sonuclari Gor',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                )
              else
                const Text(
                  'Ev sahibi sonraki turu baslatacak...',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Skor Tablosu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...room.players.map((player) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: player.isHost
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: player.isHost ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${room.scores[player.id] ?? 0}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==================== GAME OVER SCREEN ====================
class _GameOverScreen extends StatelessWidget {
  final NetworkGameRoom room;
  final NetworkGameProvider provider;

  const _GameOverScreen({required this.room, required this.provider});

  @override
  Widget build(BuildContext context) {
    // En yüksek skorlu oyuncuyu bul
    String? winnerId;
    int highestScore = -1;
    bool isDraw = false;

    room.scores.forEach((id, score) {
      if (score > highestScore) {
        highestScore = score;
        winnerId = id;
        isDraw = false;
      } else if (score == highestScore) {
        isDraw = true;
      }
    });

    final winner = room.players.cast<NetworkPlayer?>().firstWhere(
          (p) => p?.id == winnerId,
          orElse: () => null,
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kupa
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events, size: 60, color: Colors.white),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                'Oyun Bitti!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              Text(
                isDraw ? 'Berabere!' : '${winner?.name ?? "?"} Kazandi!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.warningColor,
                    ),
              ),
              const SizedBox(height: 32),
              // Final skorlar
              _buildFinalScores(),
              const SizedBox(height: 48),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        provider.leaveRoom();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                      child: const Text('Ana Menu'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (provider.isHost)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => provider.newRound(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.replay),
                            SizedBox(width: 8),
                            Text('Tekrar Oyna'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalScores() {
    // Skorlara göre sırala
    final sortedPlayers = List<NetworkPlayer>.from(room.players);
    sortedPlayers.sort((a, b) => (room.scores[b.id] ?? 0).compareTo(room.scores[a.id] ?? 0));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ...sortedPlayers.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final score = room.scores[player.id] ?? 0;
            final isFirst = index == 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // Sıra
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isFirst ? AppTheme.warningColor : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isFirst
                          ? const Icon(Icons.star, color: Colors.white, size: 18)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isFirst ? 18 : 16,
                        color: isFirst ? AppTheme.warningColor : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: isFirst ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: isFirst ? AppTheme.warningColor : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
