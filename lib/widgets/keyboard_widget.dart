import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class KeyboardWidget extends StatelessWidget {
  final List<String> guessedLetters;
  final String? currentWord;
  final bool enabled;
  final Function(String) onLetterPressed;

  const KeyboardWidget({
    super.key,
    required this.guessedLetters,
    required this.currentWord,
    required this.enabled,
    required this.onLetterPressed,
  });

  static const List<List<String>> _turkishKeyboard = [
    ['E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'Ğ', 'Ü'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ş', 'İ'],
    ['Z', 'C', 'V', 'B', 'N', 'M', 'Ö', 'Ç'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _turkishKeyboard.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.asMap().entries.map((letterEntry) {
                final letterIndex = letterEntry.key;
                final letter = letterEntry.value;
                return _buildKey(letter, rowIndex, letterIndex);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String letter, int rowIndex, int letterIndex) {
    final isGuessed = guessedLetters.contains(letter);
    final isCorrect = currentWord?.toUpperCase().contains(letter) ?? false;

    Color backgroundColor;
    Color textColor;

    if (isGuessed) {
      if (isCorrect) {
        backgroundColor = AppTheme.successColor;
        textColor = Colors.white;
      } else {
        backgroundColor = AppTheme.errorColor.withValues(alpha: 0.3);
        textColor = AppTheme.textMuted;
      }
    } else {
      backgroundColor = AppTheme.cardColor;
      textColor = AppTheme.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled && !isGuessed ? () => onLetterPressed(letter) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 44,
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: (rowIndex * 100) + (letterIndex * 30)))
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 200.ms);
  }
}
