import 'package:flutter/material.dart';
import '../../controllers/class_controller.dart';
import 'package:provider/provider.dart';
import 'progress_bar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClassController>();
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            height: kToolbarHeight,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: const Color(0xFFEEEEEE),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: CustomProgressBar(
                progressValue: controller.progressValue,
                isLight: false,
                height: 8,
                width: double.infinity,
              ),
              titleSpacing: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, color: Color(0xFFEEEEEE)),
                  offset: const Offset(0, 40),
                  color: const Color(0xFF1C1C28),
                  onSelected: (_) {},
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Idioma de la clase',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...controller.availableLanguages.map((lang) => 
                              InkWell(
                                onTap: () async {
                                  Navigator.pop(context);
                                  await controller.changeLanguage(lang);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.language, 
                                        color: Color(0xFFF7C325),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getLanguageName(lang),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: controller.currentLanguage == lang 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (controller.currentLanguage == lang)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(Icons.check, 
                                            color: Color(0xFFF7C325),
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white24),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _showClassInfo(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, 
                                      color: Color(0xFFF7C325),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Información de la clase',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }

  void _showClassInfo(BuildContext context) {
    final controller = context.read<ClassController>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C28),
        title: const Text(
          'Información de la clase',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.courseTitle,
              style: const TextStyle(
                color: Color(0xFFF7C325),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.classTitle,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFFF7C325)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'Inglés';
      case 'pt':
        return 'Portugués';
      default:
        return code.toUpperCase();
    }
  }
} 
