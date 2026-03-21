import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/tdk_service.dart';
import '../utils/app_theme.dart';

class WordSelectionScreen extends StatefulWidget {
  const WordSelectionScreen({super.key});

  @override
  State<WordSelectionScreen> createState() => _WordSelectionScreenState();
}

class _WordSelectionScreenState extends State<WordSelectionScreen> {
  final _wordController = TextEditingController();
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isValidating = false;
  String? _errorMessage;
  String? _wordMeaning;

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
    setState(() => _isLoading = true);
    try {
      _suggestions = await TDKService.getSuggestedWords(count: 6);
    } catch (e) {
      // Hata durumunda varsayılan kelimeler
      _suggestions = ['kitap', 'bilgisayar', 'telefon', 'pencere', 'masa', 'kalem'];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _validateAndSetWord(String word) async {
    if (word.length < 3) {
      setState(() {
        _errorMessage = 'Kelime en az 3 harf olmali';
        _wordMeaning = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _wordMeaning = null;
    });

    try {
      final isValid = await TDKService.validateWord(word);
      if (!isValid) {
        setState(() {
          _errorMessage = 'Bu kelime TDK sozlugunde bulunamadi';
          _isValidating = false;
        });
        return;
      }

      // Kelime anlamını al
      final meaning = await TDKService.getWordMeaning(word);
      setState(() {
        _wordMeaning = meaning;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _submitWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      setState(() {
        _errorMessage = 'Lutfen bir kelime giriniz';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<GameProvider>();
      await provider.setWord(word);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildWordInput(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorMessage(),
              ],
              if (_wordMeaning != null) ...[
                const SizedBox(height: 12),
                _buildWordMeaning(),
              ],
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 40),
              _buildSuggestions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.edit_note,
            size: 40,
            color: Colors.white,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),
        const SizedBox(height: 24),
        Text(
          'Kelime Sec',
          style: Theme.of(context).textTheme.displayMedium,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideX(begin: -0.2, duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          'Diger oyuncularin tahmin etmesi icin bir kelime sec. TDK sozlugundeki kelimeler gecerlidir.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
              ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildWordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _wordController,
          decoration: InputDecoration(
            hintText: 'Kelimeyi yaz...',
            prefixIcon: const Icon(Icons.abc, color: AppTheme.textMuted),
            suffixIcon: _isValidating
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            if (value.length >= 3) {
              _validateAndSetWord(value);
            } else {
              setState(() {
                _errorMessage = null;
                _wordMeaning = null;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Zorluk: ${TDKService.getWordDifficulty(_wordController.text)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .slideY(begin: 0.2, duration: 400.ms);
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().shake(duration: 300.ms);
  }

  Widget _buildWordMeaning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Gecerli kelime',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_wordMeaning != null) ...[
            const SizedBox(height: 8),
            Text(
              _wordMeaning!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || _wordController.text.length < 3
            ? null
            : _submitWord,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check),
                  SizedBox(width: 12),
                  Text('Kelimeyi Onayla'),
                ],
              ),
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.2, duration: 400.ms);
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final word = entry.value;
            return _buildSuggestionChip(word, index);
          }).toList(),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 400.ms);
  }

  Widget _buildSuggestionChip(String word, int index) {
    return InkWell(
      onTap: () {
        _wordController.text = word.toUpperCase();
        _validateAndSetWord(word);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getDifficultyColor(word),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                TDKService.getWordDifficulty(word),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 800 + (index * 100)))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms);
  }

  Color _getDifficultyColor(String word) {
    final difficulty = TDKService.getWordDifficulty(word);
    switch (difficulty) {
      case 'Kolay':
        return AppTheme.successColor;
      case 'Orta':
        return AppTheme.warningColor;
      case 'Zor':
        return AppTheme.errorColor;
      default:
        return AppTheme.textMuted;
    }
  }
}
