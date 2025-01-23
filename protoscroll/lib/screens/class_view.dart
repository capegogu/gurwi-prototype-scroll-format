import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/class_controller.dart';
import '../widgets/content/content_widget.dart';
import '../widgets/shared/progress_bar.dart';
import '../services/preferences_service.dart';
import '../widgets/shared/continue_button.dart';
import '../widgets/shared/custom_app_bar.dart';
import '../widgets/content/question.dart';

class ClassView extends StatelessWidget {
  final String classId;
  final String initialLanguage;

  const ClassView({
    super.key,
    required this.classId,
    required this.initialLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PreferencesService>(
      future: PreferencesService.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A14),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF7C325)),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A14),
            body: Center(
              child: Text(
                'Error inicializando preferencias',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return ChangeNotifierProvider(
          create: (_) => ClassController(
            classId,
            preferences: snapshot.data!,
            initialLanguage: initialLanguage,
          ),
          child: const _ClassViewContent(),
        );
      },
    );
  }
}

class _ClassViewContent extends StatefulWidget {
  const _ClassViewContent();

  @override
  _ClassViewContentState createState() => _ClassViewContentState();
}

class _ClassViewContentState extends State<_ClassViewContent> {
  final ScrollController _scrollController = ScrollController();
  final List<List<dynamic>> _displayedPages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPage();
    });
  }

  void _loadInitialPage() {
    final controller = context.read<ClassController>();
    if (!controller.isLoading) {
      final initialContent = controller.getPageContent(1);
      if (initialContent != null) {
        setState(() {
          _displayedPages.add(initialContent);
        });
        controller.changePage(1);
      }
    }
  }

  void _addNextPage(ClassController controller) {
    final nextPageIndex = _displayedPages.length + 1;
    final nextPageContent = controller.getPageContent(nextPageIndex);
    
    if (nextPageContent != null) {
      setState(() {
        _displayedPages.add(nextPageContent);
      });
      controller.changePage(nextPageIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClassController>();

    if (controller.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A14),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF7C325)),
          ),
        ),
      );
    }

    if (controller.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A14),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFF7C325),
              ),
              const SizedBox(height: 16),
              Text(
                controller.error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7C325),
                ),
                onPressed: controller.retryLoading,
                child: const Text('Reintentar',
                    style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    if (_displayedPages.isEmpty && !controller.isLoading) {
      _loadInitialPage();
    }

    if (_displayedPages.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A14),
        appBar: const CustomAppBar(),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ..._displayedPages.map((pageContent) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: pageContent.map((content) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ContentWidget(
                                    content: content,
                                    language: controller.currentLanguage,
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                          if (!controller.isQuestionPage)
                            ContinueButton(
                              onComplete: controller.isLastPage 
                                ? () => _showCompletionDialog(context)
                                : () => _addNextPage(controller),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      backgroundColor: Color(0xFF0A0A14),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF7C325)),
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C28),
        title: const Text(
          '¡Felicitaciones!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Has completado esta clase.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context); // Vuelve a la pantalla anterior
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}