import 'package:flutter/material.dart';
import 'content_widget.dart';

class CardsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  final double spacing;
  final double runSpacing;

  const CardsWidget({
    super.key,
    required this.cards,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      separatorBuilder: (context, index) => SizedBox(height: runSpacing),
      itemBuilder: (context, index) => _buildCard(index),
    );
  }

  Widget _buildCard(int index) {
    final card = cards[index];
    final content = card['content'] as List;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: content.map<Widget>((item) => ContentWidget(
            content: item,
          )).toList(),
        ),
      ),
    );
  }
} 