import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';

class TextPlayer extends StatefulWidget {
  final String text;
  final String? audioUrl;
  final String? wordTime;
  final double? width;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final Color? textColor;
  final double velocity;
  final bool italic;
  final bool centerText;
  final bool showDebugLog;

  const TextPlayer({
    super.key,
    required this.text,
    this.audioUrl,
    this.wordTime,
    this.width,
    this.fontSize = 16,
    this.lineHeight = 1.5,
    this.letterSpacing = 0.5,
    this.textColor,
    this.velocity = 1.15,
    this.italic = false,
    this.centerText = false,
    this.showDebugLog = false,
  });

  @override
  State<TextPlayer> createState() => _TextPlayerState();
}

class _TextPlayerState extends State<TextPlayer> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  List<Map<String, dynamic>> _wordTimings = [];
  int _currentWordIndex = -1;
  bool _isKaraokeEnabled = true;
  bool _hasAudio = false;
  final List<String> _debugLog = [];
  static const Color _defaultTextColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _debugLog.add('InitState llamado');
    _initializeAudio();
  }

  @override
  void didUpdateWidget(TextPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioUrl != oldWidget.audioUrl ||
        widget.text != oldWidget.text) {
      _debugLog.add('Audio URL o texto cambiado, reinicializando audio');
      _initializeAudio();
    }
  }

  void _initializeAudio() {
    _hasAudio = widget.audioUrl != null;
    if (_hasAudio) {
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      _initAudioPlayer();
    }
    if (widget.wordTime != null) {
      _processWordTimings(widget.wordTime!);
    }
  }

  void _processWordTimings(String wordTime) {
    if (!_hasAudio) {
      _isKaraokeEnabled = false;
      _debugLog.add('No hay audio disponible, karaoke deshabilitado');
      return;
    }
    try {
      List<dynamic> decodedTimings = json.decode(wordTime);

      List<Map<String, dynamic>> processedTimings = decodedTimings
          .map((timing) => timing as Map<String, dynamic>)
          .toList();

      List<String> textWords = widget.text.split(RegExp(r'\s+'));
      int textIndex = 0;
      int mismatchCount = 0;

      _debugLog.add('Procesando ${processedTimings.length} entradas de tiempo');

      for (int i = 0;
          i < processedTimings.length && textIndex < textWords.length;
          i++) {
        String timingWord = _cleanWord(processedTimings[i]['word']);
        String textWord = _cleanWord(textWords[textIndex]);

        if (timingWord == textWord) {
          processedTimings[i]['word'] = textWords[textIndex];
          textIndex++;
          mismatchCount = 0;
        } else {
          int matchIndex = _findMatchingWord(textWords, textIndex, timingWord);
          if (matchIndex != -1) {
            processedTimings[i]['word'] = textWords[matchIndex];
            textIndex = matchIndex + 1;
            mismatchCount = 0;
          } else {
            mismatchCount++;
            _debugLog.add(
                'Desajuste: palabra de tiempo "$timingWord" no encontrada cerca de la palabra de texto "${textWords[textIndex]}"');
          }
        }

        if (mismatchCount > 5) {
          _isKaraokeEnabled = false;
          _debugLog.add('Demasiados desajustes consecutivos, karaoke deshabilitado');
          return;
        }
      }

      if (textIndex < textWords.length - 5) {
        _isKaraokeEnabled = false;
        _debugLog.add(
            'Demasiadas palabras sin procesar (${textWords.length - textIndex}), karaoke deshabilitado');
      } else {
        _wordTimings = processedTimings;
        if (_wordTimings.isNotEmpty) {
          _wordTimings.last['end'] = _wordTimings.last['end'] + 2.0;
        }
        _isKaraokeEnabled = true;
        _debugLog.add('Karaoke habilitado, ${_wordTimings.length} palabras procesadas');
      }
    } catch (e) {
      print('Error al procesar los tiempos de las palabras: $e');
      _debugLog.add('Error al procesar los tiempos de las palabras: $e');
      _isKaraokeEnabled = false;
    }
  }

  String _cleanWord(String word) =>
      word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

  int _findMatchingWord(List<String> words, int startIndex, String targetWord) {
    for (int i = startIndex; i < words.length; i++) {
      if (_cleanWord(words[i]) == targetWord) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _initAudioPlayer() async {
    if (!_hasAudio) return;
    try {
      await _audioPlayer?.setUrl(widget.audioUrl!);
      await _audioPlayer?.setSpeed(widget.velocity);
      _audioPlayer?.playerStateStream.listen(_onPlayerStateChanged);
      _audioPlayer?.positionStream.listen(_updateHighlightedWord);
    } catch (e) {
      print('Error al inicializar el reproductor de audio: $e');
      _debugLog.add('Error al inicializar el reproductor de audio: $e');
      _isKaraokeEnabled = false;
    }
  }

  void _onPlayerStateChanged(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      setState(() {
        _isPlaying = false;
        _currentWordIndex = _wordTimings.length;
      });
    }
  }

  void _updateHighlightedWord(Duration position) {
    if (!_isKaraokeEnabled) return;
    int newIndex = _wordTimings.indexWhere((timing) =>
        position.inMilliseconds >= (timing['start'] * 1000) &&
        position.inMilliseconds < (timing['end'] * 1000));
    if (newIndex != _currentWordIndex) {
      setState(() => _currentWordIndex = newIndex);
    }
  }

  void _togglePlayPause() {
    if (!_hasAudio) return;
    if (_isPlaying) {
      _audioPlayer?.pause();
      setState(() => _isPlaying = false);
    } else {
      _playAudio();
    }
  }

  void _playAudio() {
    if (!_hasAudio) return;
    _audioPlayer?.seek(Duration.zero);
    _audioPlayer?.play();
    setState(() {
      _isPlaying = true;
      _currentWordIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 24),
          child: GestureDetector(
            onTap: _hasAudio ? _togglePlayPause : null,
            child: RichText(
              textAlign: widget.centerText ? TextAlign.center : TextAlign.start,
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: widget.fontSize,
                  height: widget.lineHeight,
                  letterSpacing: widget.letterSpacing,
                  color: widget.textColor ?? _defaultTextColor,
                  fontStyle: widget.italic ? FontStyle.italic : FontStyle.normal,
                ),
                children: [
                  if (_hasAudio)
                    WidgetSpan(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: widget.fontSize,
                          color: widget.textColor ?? _defaultTextColor,
                        ),
                      ),
                    ),
                  ..._buildTextSpans(),
                ],
              ),
            ),
          ),
        ),
        if (widget.showDebugLog)
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Registro de Depuración'),
                  content: SingleChildScrollView(
                    child: Text(_debugLog.join('\n')),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Mostrar Registro de Depuración'),
          ),
      ],
    );
  }

  List<TextSpan> _buildTextSpans() {
    if (!_hasAudio || !_isKaraokeEnabled || !_isPlaying || _wordTimings.isEmpty) {
      return [TextSpan(text: widget.text)];
    }

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (int i = 0; i < _wordTimings.length; i++) {
      var timing = _wordTimings[i];
      var word = timing['word'] as String;
      var startIndex = widget.text.indexOf(word, currentIndex);

      if (startIndex == -1) {
        startIndex = widget.text.toLowerCase().indexOf(word.toLowerCase(), currentIndex);
        if (startIndex != -1) {
          word = widget.text.substring(startIndex, startIndex + word.length);
        }
      }

      if (startIndex == -1) continue;

      if (startIndex > currentIndex) {
        spans.add(TextSpan(
          text: widget.text.substring(currentIndex, startIndex),
          style: TextStyle(
            color: (widget.textColor ?? _defaultTextColor).withOpacity(0.5),
          ),
        ));
      }

      spans.add(TextSpan(
        text: word,
        style: TextStyle(
          color: i <= _currentWordIndex
              ? widget.textColor ?? _defaultTextColor
              : (widget.textColor ?? _defaultTextColor).withOpacity(0.5),
        ),
      ));

      currentIndex = startIndex + word.length;
    }

    if (currentIndex < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(currentIndex),
        style: TextStyle(
          color: (widget.textColor ?? _defaultTextColor).withOpacity(0.5),
        ),
      ));
    }

    return spans;
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}