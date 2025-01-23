import 'package:flutter/material.dart';
import '../../controllers/class_controller.dart';
import 'package:provider/provider.dart';

class ContinueButton extends StatelessWidget {
  final VoidCallback? onComplete;

  const ContinueButton({
    super.key,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClassController>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF7C325),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onComplete,
        child: Text(
          controller.isLastPage ? 'Finalizar' : 'Continuar',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 