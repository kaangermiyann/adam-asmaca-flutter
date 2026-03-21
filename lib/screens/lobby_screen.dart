import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_room.dart';
import '../providers/game_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/player_card.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;

  const LobbyScreen({super.key, required this.roomId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final room = provider.currentRoom;

        if (room == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Oyun başladıysa game screen'e git
        if (room.state == GameState.choosingWord ||
            room.state == GameState.playing ||
            room.state == GameState.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => GameScreen(roomId: widget.roomId),
              ),
            );
          });
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _showLeaveDialog();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Oyun Odası'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _showLeaveDialog,
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Oda kodu
                    _buildRoomCodeCard(room),
                    const SizedBox(height: 24),
                    // Oyuncular listesi
                    Expanded(child: _buildPlayersList(room, provider)),
                    const SizedBox(height: 24),
                    // Butonlar
                    _buildActionButtons(room, provider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomCodeCard(GameRoom room) {
    return Container(
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
            'Oda Kodu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                room.id,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: room.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kod kopyalandı!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                tooltip: 'Kodu Kopyala',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kodu arkadaslarinla paylas',
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
        .slideY(begin: -0.2, duration: 400.ms);
  }

  Widget _buildPlayersList(GameRoom room, GameProvider provider) {
    return Column(
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
              return PlayerCard(
                player: player,
                isHost: player.id == room.hostId,
                score: room.scores[player.id],
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(GameRoom room, GameProvider provider) {
    final isHost = provider.isHost;
    final allReady = room.players.length >= 2 &&
        room.players.where((p) => p.id != room.hostId).every((p) => p.isReady);
    final currentPlayer =
        room.players.firstWhere((p) => p.id == provider.playerId);

    return Column(
      children: [
        if (!isHost) ...[
          // Hazır ol butonu
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => provider.toggleReady(),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentPlayer.isReady
                    ? AppTheme.successColor
                    : AppTheme.primaryColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentPlayer.isReady
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 12),
                  Text(currentPlayer.isReady ? 'Hazır!' : 'Hazır Ol'),
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
              onPressed: allReady ? () => _startGame(provider) : null,
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
                        ? 'Oyunu Başlat'
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
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.2, duration: 400.ms);
  }

  Future<void> _startGame(GameProvider provider) async {
    try {
      await provider.startGame();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showLeaveDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Odadan Ayrıl'),
        content: const Text('Odadan ayrılmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await context.read<GameProvider>().leaveRoom();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }
}
