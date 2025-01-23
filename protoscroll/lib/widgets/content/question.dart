import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class QuestionWidget extends StatefulWidget {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String feedback;
  final List<Map<String, dynamic>> visualContent;
  final void Function(bool)? onAnswered;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.feedback,
    this.visualContent = const [],
    this.onAnswered,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> with SingleTickerProviderStateMixin {
  String? _selectedOption;
  final _audioPlayer = AudioPlayer();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _loadSounds();
  }

  Future<void> _loadSounds() async {
    await _audioPlayer.setAsset('assets/sounds/correct.mp3');
  }

  void _handleOptionTap(String option) async {
    if (_selectedOption != null) return;

    setState(() {
      _selectedOption = option;
    });

    bool isCorrect = option == widget.correctAnswer;
    
    if (isCorrect) {
      await _audioPlayer.setAsset('assets/sounds/correct.mp3');
    } else {
      await _audioPlayer.setAsset('assets/sounds/incorrect.mp3');
    }
    await _audioPlayer.play();

    widget.onAnswered?.call(isCorrect);
  }

  Widget _buildOptionButton(String option) {
    bool isSelected = _selectedOption == option;
    bool isCorrect = widget.correctAnswer == option;
    bool showResult = _selectedOption != null;

    Color getBackgroundColor() {
      if (!showResult) return Colors.white;
      if (isSelected && !isCorrect) return const Color(0xFFFEE2E2);
      if (isCorrect) return const Color(0xFFE8F5E9);
      return Colors.white;
    }

    Color getBorderColor() {
      if (!showResult) return Colors.grey.withOpacity(0.3);
      if (isSelected && !isCorrect) return const Color(0xFF991B3B);
      if (isCorrect) return const Color(0xFF39843D);
      return Colors.grey.withOpacity(0.3);
    }

    Color getTextColor() {
      if (!showResult) return const Color(0xFF28231A);
      if (isSelected && !isCorrect) return const Color(0xFF991B3B);
      if (isCorrect) return const Color(0xFF39843D);
      return const Color(0xFF28231A);
    }

    return GestureDetector(
      onTapDown: _selectedOption == null ? (_) => _controller.forward() : null,
      onTapUp: _selectedOption == null ? (_) => _controller.reverse() : null,
      onTapCancel: _selectedOption == null ? () => _controller.reverse() : null,
      onTap: () => _handleOptionTap(option),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: getBackgroundColor(),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: getBorderColor(),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16.0,
                    color: getTextColor(),
                  ),
                ),
              ),
              if (showResult && (isSelected || isCorrect))
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect 
                      ? const Color(0xFF39843D)
                      : const Color(0xFF991B3B),
                  size: 24.0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contenido visual previo a la pregunta
        if (widget.visualContent.isNotEmpty) ...[
          // Aquí iría la lógica para mostrar imágenes o videos según el estado
        ],
        
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            widget.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF28231A),
            ),
          ),
        ),
        
        ...widget.options.map((option) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildOptionButton(option),
        )),

        // Mostrar feedback cuando se selecciona una respuesta
        if (_selectedOption != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              widget.feedback,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF28231A),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }
} 