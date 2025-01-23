// lib/widgets/content/content_widget.dart

import 'package:flutter/material.dart';
import 'text_player.dart';
import 'custom_media.dart';
import 'flip_card.dart';
import 'carousel.dart';
import 'question.dart';
import 'graph.dart';
import 'cards.dart';
import 'webview.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../../controllers/class_controller.dart';

class ContentWidget extends StatelessWidget {
  final Map<String, dynamic> content;
  final VoidCallback? onNext;
  final String? language;

  const ContentWidget({
    super.key,
    required this.content,
    this.onNext,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    // Observar los cambios del ClassController
    final controller = context.watch<ClassController>();
    final currentLanguage = controller.currentLanguage;

    // Agregar una key única al widget raíz para forzar la reconstrucción
    return KeyedSubtree(
      key: ValueKey('content_${currentLanguage}_${content['type']}'),
      child: _buildContent(context, currentLanguage),
    );
  }

  Widget _buildContent(BuildContext context, String currentLanguage) {
    switch (content['type']) {
      case 'text':
        // Si el texto tiene audio o popups, usa TextPlayer
        if (content['audio'] != null || content['popups'] != null) {
          return TextPlayer(
            key: ValueKey('text_player_${currentLanguage}_${content['data']}'),
            text: content['data'] as String,
            audioUrl: content['audio'] as String?,
            wordTime: content['wordTime'] as String?,
            fontSize: 16,
            lineHeight: 1.5,
            letterSpacing: 0.5,
            textColor: Theme.of(context).textTheme.bodyMedium?.color,
            showDebugLog: false, // Temporal para debug
          );
        } 
        // Para texto simple
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Html(
            key: ValueKey('html_${currentLanguage}_${content['data']}'),
            data: content['data'] is String ? content['data'] : content['data']['data'],
            style: {
              "body": Style(
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.5),
                letterSpacing: 0.5,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              "span": Style(
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.5),
                letterSpacing: 0.5,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            },
          ),
        );

      case 'image':
      case 'video':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            child: CustomMediaWidget(
              media: content['data']['url'],
              mediaError: content['data']['urlError'],
              borderRadius: 8,
              width: MediaQuery.of(context).size.width - 32,
              height: content['data']['height']?.toDouble(),
              enableFullscreen: true,
              backgroundColor: const Color(0xFFE0E0E0),
              shimmerColor: Colors.white,
            ),
          ),
        );

      case 'flipcard':
        final data = content['data'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FlipCardWidget(
            front: data['front'].map<Widget>((content) => ContentWidget(
              content: content,
              language: language,
            )).toList(),
            back: data['back'].map<Widget>((content) => ContentWidget(
              content: content,
              language: language,
            )).toList(),
          ),
        );

      case 'carousel':
        final items = content['data']['items'] as List;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CarouselWidget(
            items: items.map<Widget>((item) => ContentWidget(
              content: item,
              language: language,
            )).toList(),
            height: content['data']['height']?.toDouble(),
          ),
        );

      case 'question':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: QuestionWidget(
            question: content['data']['question'] as String,
            options: List<String>.from(content['data']['options']),
            correctAnswer: content['data']['correctAnswer'] as String,
            feedback: content['data']['feedback'] as String,
            visualContent: content['data']['visualContent'] != null 
                ? List<Map<String, dynamic>>.from(content['data']['visualContent'])
                : [],
            onAnswered: onNext != null ? (_) => onNext!() : null,
          ),
        );

      case 'graph':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GraphWidget(
            type: content['data']['type'],
            title: content['data']['title'],
            data: content['data'],
          ),
        );

      case 'cards':
        final cards = content['data']['cards'] as List;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CardsWidget(
            cards: List<Map<String, dynamic>>.from(cards),
          ),
        );

      case 'webview':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: WebView(
            url: content['data']['url'] as String,
            width: content['data']['width']?.toDouble(),
            height: content['data']['height']?.toDouble(),
            currentLanguage: language ?? 'es',
          ),
        );

      case 'metadata':
        // Metadata no se renderiza visualmente
        return const SizedBox.shrink();

      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Tipo de contenido no soportado: ${content['type']}',
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        );
    }
  }
}