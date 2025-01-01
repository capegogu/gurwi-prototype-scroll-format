// lib/models/class_content.dart
import 'dart:convert';

// Modelo principal que representa una clase completa
class ClassContent {
  final String courseTitle;
  final String classTitle;
  final int classNumber;
  final List<Page> pages;
  final List<String> availableLanguages;
  final String path;
  final bool isFree;
  final String? unitId;
  final String? formationId;
  final Map<String, String> titles; // Títulos en diferentes idiomas

  ClassContent({
    required this.courseTitle,
    required this.classTitle,
    required this.classNumber,
    required this.pages,
    required this.availableLanguages,
    required this.path,
    required this.isFree,
    this.unitId,
    this.formationId,
    required this.titles,
  });

  // Crear desde respuesta de Supabase
  static Future<ClassContent?> fromSupabase(Map<String, dynamic> supabaseData, String language) async {
    try {
      // Extraer idiomas disponibles
      final languages = List<String>.from(supabaseData['languages'] ?? ['es']);
      
      // Extraer títulos en diferentes idiomas
      final titles = {
        'es': supabaseData['title_es'] ?? '',
        'en': supabaseData['title_en'] ?? '',
        'pt': supabaseData['title_pt'] ?? '',
      };

      // Obtener el contenido del idioma seleccionado
      final contentKey = 'content_$language';
      final content = supabaseData[contentKey];
      
      if (content == null) {
        throw Exception('No hay contenido disponible para el idioma $language');
      }

      // Parsear el contenido JSON
      final jsonContent = content as Map<String, dynamic>;
      
      return ClassContent(
        courseTitle: jsonContent['course_title'] ?? '',
        classTitle: titles[language] ?? titles['es'] ?? '', // Fallback a español
        classNumber: jsonContent['class_number'] ?? 0,
        pages: (jsonContent['pages'] as List<dynamic>?)
            ?.map((page) => Page.fromJson(page))
            .toList() ?? [],
        availableLanguages: languages,
        path: supabaseData['path'] ?? '',
        isFree: supabaseData['is_free'] ?? false,
        unitId: supabaseData['unit_id'],
        formationId: supabaseData['formation_id'],
        titles: titles as Map<String, String>,
      );
    } catch (e) {
      print('Error parsing ClassContent: $e');
      return null;
    }
  }

  // Obtener título en un idioma específico
  String getTitleInLanguage(String language) {
    return titles[language] ?? titles['es'] ?? classTitle;
  }

  // Verificar si un idioma está disponible
  bool isLanguageAvailable(String language) {
    return availableLanguages.contains(language);
  }

  // Convertir a JSON para almacenamiento local
  Map<String, dynamic> toJson() {
    return {
      'course_title': courseTitle,
      'class_title': classTitle,
      'class_number': classNumber,
      'pages': pages.map((page) => page.toJson()).toList(),
      'available_languages': availableLanguages,
      'path': path,
      'is_free': isFree,
      'unit_id': unitId,
      'formation_id': formationId,
      'titles': titles,
    };
  }
}

// Agregar método toJson a Page
extension PageJson on Page {
  Map<String, dynamic> toJson() {
    return {
      'page_number': pageNumber,
      'content': content.map((c) => c.toJson()).toList(),
    };
  }
}

// Agregar método toJson a Content
extension ContentJson on Content {
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }
}

// Modelo para cada página
class Page {
  final int pageNumber;
  final List<Content> content;

  Page({
    required this.pageNumber,
    required this.content,
  });

  factory Page.fromJson(Map<String, dynamic> json) {
    return Page(
      pageNumber: json['page_number'] ?? 0,
      content: (json['content'] as List<dynamic>?)
          ?.map((content) => Content.fromJson(content))
          .toList() ?? [],
    );
  }
}

// Modelo base para cualquier tipo de contenido
class Content {
  final String type;
  final dynamic data;

  Content({
    required this.type,
    required this.data,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    dynamic contentData = json['data'];

    switch (type) {
      case 'text':
        return TextContent.fromJson(json);
      case 'image':
        return ImageContent.fromJson(json);
      case 'video':
        return VideoContent.fromJson(json);
      case 'flipcard':
        return FlipCardContent.fromJson(json);
      case 'carousel':
        return CarouselContent.fromJson(json);
      case 'question':
        return QuestionContent.fromJson(json);
      case 'metadata':
        return MetadataContent.fromJson(json);
      case 'graph':
        return GraphContent.fromJson(json);
      case 'cards':
        return CardsContent.fromJson(json);
      case 'webview':
        return WebViewContent.fromJson(json);
      default:
        return Content(type: type, data: contentData);
    }
  }
}

// Modelo para contenido de texto
class TextContent extends Content {
  final String text;
  final String? audio;
  final List<WordTime>? wordTime;
  final List<Popup>? popups;

  TextContent({
    required this.text,
    this.audio,
    this.wordTime,
    this.popups,
  }) : super(type: 'text', data: text);

  factory TextContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return TextContent(
      text: data is String ? data : data['data'] ?? '',
      audio: data is Map ? data['audio'] : null,
      wordTime: data is Map && data['wordTime'] != null
          ? (jsonDecode(data['wordTime']) as List)
              .map((w) => WordTime.fromJson(w))
              .toList()
          : null,
      popups: data is Map && data['popups'] != null
          ? (data['popups'] as List)
              .map((p) => Popup.fromJson(p))
              .toList()
          : null,
    );
  }
}

// Modelo para tiempos de palabras en el audio
class WordTime {
  final String word;
  final double start;
  final double end;

  WordTime({
    required this.word,
    required this.start,
    required this.end,
  });

  factory WordTime.fromJson(Map<String, dynamic> json) {
    return WordTime(
      word: json['word'] ?? '',
      start: (json['start'] ?? 0).toDouble(),
      end: (json['end'] ?? 0).toDouble(),
    );
  }
}

// Modelo para popups en el texto
class Popup {
  final String phrase;
  final List<PopupContent> content;

  Popup({
    required this.phrase,
    required this.content,
  });

  factory Popup.fromJson(Map<String, dynamic> json) {
    return Popup(
      phrase: json['phrase'] ?? '',
      content: (json['popup_data'] as List<dynamic>?)
          ?.map((data) => PopupContent.fromJson(data))
          .toList() ?? [],
    );
  }
}

// Modelo para contenido de popups
class PopupContent {
  final String type;
  final Map<String, dynamic> data;

  PopupContent({
    required this.type,
    required this.data,
  });

  factory PopupContent.fromJson(Map<String, dynamic> json) {
    return PopupContent(
      type: json['type'] ?? '',
      data: json['data'] ?? {},
    );
  }
}

// Modelo para contenido de imagen
class ImageContent extends Content {
  final String url;
  final String? urlDark;
  final String? urlError;
  final String dimensions;
  final double width;
  final double height;
  final String? blurhash;
  final String? caption;

  ImageContent({
    required this.url,
    this.urlDark,
    this.urlError,
    required this.dimensions,
    required this.width,
    required this.height,
    this.blurhash,
    this.caption,
  }) : super(type: 'image', data: {
          'url': url,
          'dimensions': dimensions,
          'width': width,
          'height': height,
        });

  factory ImageContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ImageContent(
      url: data['url'] ?? '',
      urlDark: data['urlDark'],
      urlError: data['urlError'],
      dimensions: data['dimensions'] ?? 'square',
      width: (data['width'] ?? 100).toDouble(),
      height: (data['height'] ?? 100).toDouble(),
      blurhash: data['blurhash'],
      caption: data['caption'],
    );
  }
}

// Los demás modelos específicos seguirían el mismo patrón...
// VideoContent, FlipCardContent, CarouselContent, etc.

// Modelo para preguntas
class QuestionContent extends Content {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? feedback;
  final List<QuestionVisualContent>? visualContent;

  QuestionContent({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.feedback,
    this.visualContent,
  }) : super(type: 'question', data: {
          'question': question,
          'options': options,
        });

  factory QuestionContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return QuestionContent(
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
      feedback: data['feedback'],
      visualContent: data['visualContent'] != null
          ? (data['visualContent'] as List)
              .map((v) => QuestionVisualContent.fromJson(v))
              .toList()
          : null,
    );
  }
}

// Modelo para contenido visual de preguntas
class QuestionVisualContent {
  final String type;
  final Map<String, dynamic> data;
  final String? position;
  final String? state;

  QuestionVisualContent({
    required this.type,
    required this.data,
    this.position,
    this.state,
  });

  factory QuestionVisualContent.fromJson(Map<String, dynamic> json) {
    return QuestionVisualContent(
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      position: json['position'],
      state: json['state'],
    );
  }
}



// Modelo para contenido de video 
class VideoContent extends Content {
  final String url;
  final String? urlDark;
  final String? urlError;
  final String dimensions;
  final double width;
  final double height;
  final String? blurhash;
  final String? caption;
  final String? playbackMode;

  VideoContent({
    required this.url,
    this.urlDark,
    this.urlError,
    required this.dimensions,
    required this.width,
    required this.height,
    this.blurhash,
    this.caption,
    this.playbackMode,
  }) : super(type: 'video', data: {
          'url': url,
          'dimensions': dimensions,
          'width': width,
          'height': height,
        });

  factory VideoContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return VideoContent(
      url: data['url'] ?? '',
      urlDark: data['urlDark'],
      urlError: data['urlError'],
      dimensions: data['dimensions'] ?? 'square',
      width: (data['width'] ?? 100).toDouble(),
      height: (data['height'] ?? 100).toDouble(),
      blurhash: data['blurhash'],
      caption: data['caption'],
      playbackMode: data['playbackMode'],
    );
  }
}

// Modelo para flip cards
class FlipCardContent extends Content {
  final List<Content> front;
  final List<Content> back;

  FlipCardContent({
    required this.front,
    required this.back,
  }) : super(type: 'flipcard', data: {
          'front': front,
          'back': back,
        });

  factory FlipCardContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return FlipCardContent(
      front: (data['front'] as List<dynamic>?)
          ?.map((item) => Content.fromJson(item))
          .toList() ?? [],
      back: (data['back'] as List<dynamic>?)
          ?.map((item) => Content.fromJson(item))
          .toList() ?? [],
    );
  }
}

// Modelo para carruseles
class CarouselContent extends Content {
  final List<Content> items;

  CarouselContent({
    required this.items,
  }) : super(type: 'carousel', data: {'items': items});

  factory CarouselContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return CarouselContent(
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => Content.fromJson(item))
          .toList() ?? [],
    );
  }
}

// Modelo para metadatos
class MetadataContent extends Content {
  final String lastUpdateDate;
  final List<Author> authors;
  final String bibliography;
  final String references;
  final String hash;

  MetadataContent({
    required this.lastUpdateDate,
    required this.authors,
    required this.bibliography,
    required this.references,
    required this.hash,
  }) : super(type: 'metadata', data: {
          'lastUpdateDate': lastUpdateDate,
          'authors': authors,
          'bibliography': bibliography,
          'references': references,
          'hash': hash,
        });

  factory MetadataContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return MetadataContent(
      lastUpdateDate: data['lastUpdateDate'] ?? '',
      authors: (data['authors'] as List<dynamic>?)
          ?.map((author) => Author.fromJson(author))
          .toList() ?? [],
      bibliography: data['bibliography'] ?? '',
      references: data['references'] ?? '',
      hash: data['hash'] ?? '',
    );
  }
}

// Modelo para autores en metadata
class Author {
  final String userId;
  final String name;
  final String? profilePic;
  final String? role;

  Author({
    required this.userId,
    required this.name,
    this.profilePic,
    this.role,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      profilePic: json['profilePic'],
      role: json['role'],
    );
  }
}

// Modelo para gráficos
class GraphContent extends Content {
  @override
  final String type;
  final String title;
  final String? subtitle;
  final List<String> names;
  final List<String> data1;
  final String data1Name;
  final bool isHorizontal;
  final String? resourceUrl;

  GraphContent({
    required this.type,
    required this.title,
    this.subtitle,
    required this.names,
    required this.data1,
    required this.data1Name,
    required this.isHorizontal,
    this.resourceUrl,
  }) : super(type: 'graph', data: {
          'type': type,
          'title': title,
        });

  factory GraphContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return GraphContent(
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      names: List<String>.from(data['names'] ?? []),
      data1: List<String>.from(data['data1'] ?? []),
      data1Name: data['data1Name'] ?? '',
      isHorizontal: data['isHorizontal'] ?? false,
      resourceUrl: data['resourceUrl'],
    );
  }
}

// Modelo para tarjetas
class CardsContent extends Content {
  final List<CardItem> cards;

  CardsContent({
    required this.cards,
  }) : super(type: 'cards', data: {'cards': cards});

  factory CardsContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return CardsContent(
      cards: (data['cards'] as List<dynamic>?)
          ?.map((card) => CardItem.fromJson(card))
          .toList() ?? [],
    );
  }
}

// Modelo para cada tarjeta individual
class CardItem {
  final List<Content> content;

  CardItem({required this.content});

  factory CardItem.fromJson(Map<String, dynamic> json) {
    return CardItem(
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => Content.fromJson(item))
          .toList() ?? [],
    );
  }
}

// Modelo para webview
class WebViewContent extends Content {
  @override
  final String type;
  final String url;
  final String? html;
  final String dimensions;
  final double width;
  final double height;
  final bool showInPreview;
  final String? caption;

  WebViewContent({
    required this.type,
    required this.url,
    this.html,
    required this.dimensions,
    required this.width,
    required this.height,
    required this.showInPreview,
    this.caption,
  }) : super(type: 'webview', data: {
          'type': type,
          'url': url,
          'dimensions': dimensions,
        });

  factory WebViewContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return WebViewContent(
      type: data['type'] ?? '',
      url: data['url'] ?? '',
      html: data['html'],
      dimensions: data['dimensions'] ?? 'custom',
      width: (data['width'] ?? 100).toDouble(),
      height: (data['height'] ?? 100).toDouble(),
      showInPreview: data['showInPreview'] ?? false,
      caption: data['caption'],
    );
  }
}