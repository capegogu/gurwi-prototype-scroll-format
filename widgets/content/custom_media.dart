import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';
import 'dart:developer' as developer;

enum MediaType { image, video, animatedWebp, unknown }

class CustomMediaWidget extends StatefulWidget {
  const CustomMediaWidget({
    super.key,
    this.width,
    this.height,
    this.heightDynamic,
    required this.media,
    this.mediaError,
    required this.borderRadius,
    this.topLeftRadius,
    this.topRightRadius,
    this.bottomLeftRadius,
    this.bottomRightRadius,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.shimmerColor = Colors.white,
    this.enableFullscreen,
    this.enablePinchToZoom,
    this.shouldUpdate = false,
  });

  final double? width;
  final double? height;
  final double? heightDynamic;
  final String media;
  final String? mediaError;
  final double borderRadius;
  final double? topLeftRadius;
  final double? topRightRadius;
  final double? bottomLeftRadius;
  final double? bottomRightRadius;
  final Color backgroundColor;
  final Color shimmerColor;
  final bool? enableFullscreen;
  final bool? enablePinchToZoom;
  final bool shouldUpdate;

  @override
  State<CustomMediaWidget> createState() => _CustomMediaWidgetState();
}

class _CustomMediaWidgetState extends State<CustomMediaWidget>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late MediaType _mediaType;
  bool _isLoading = true;
  bool _hasError = false;
  VideoPlayerController? _videoController;
  late String _currentMediaUrl;
  String? _fallbackMediaUrl;
  final bool _isVisible = true;
  Timer? _visibilityTimer;
  bool _keepPlaying = false;
  DateTime _lastVisibleTime = DateTime.now();
  bool _isMediaReady = false;

  bool get _isFullscreenEnabled => widget.enableFullscreen ?? false;
  bool get _isPinchZoomEnabled => widget.enablePinchToZoom ?? false;

  late final Color _effectiveBackgroundColor = widget.backgroundColor;
  late final Color _effectiveShimmerColor = widget.shimmerColor;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolveMediaUrls();
  }

  @override
  void didUpdateWidget(CustomMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldUpdate &&
        (widget.media != oldWidget.media ||
            widget.mediaError != oldWidget.mediaError)) {
      _resolveMediaUrls();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    _visibilityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_mediaType == MediaType.video && _videoController != null) {
      if (state == AppLifecycleState.resumed) {
        _ensureVideoPlayback();
      } else {
        _videoController!.pause();
      }
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (_mediaType == MediaType.video && _videoController != null) {
      if (info.visibleFraction > 0.5) {
        _lastVisibleTime = DateTime.now();
        _keepPlaying = true;
        _ensureVideoPlayback();
      } else {
        _keepPlaying = false;
        _visibilityTimer?.cancel();
        _visibilityTimer = Timer(const Duration(seconds: 5), () {
          if (!_keepPlaying &&
              DateTime.now().difference(_lastVisibleTime).inSeconds > 5) {
            _videoController!.pause();
          }
        });
      }
    }
  }

  void _ensureVideoPlayback() {
    if (_videoController != null && !_videoController!.value.isPlaying) {
      _videoController!.play();
    }
  }

  void _resolveMediaUrls() {
    try {
      _currentMediaUrl = widget.media;
      _fallbackMediaUrl = widget.mediaError;

      developer.log('Primary media URL: $_currentMediaUrl');
      developer.log('Fallback media URL: $_fallbackMediaUrl');

      if (_currentMediaUrl.isEmpty && _fallbackMediaUrl == null) {
        throw Exception('Both primary and fallback media URLs are empty');
      }

      _loadMedia(_currentMediaUrl);
    } catch (e) {
      developer.log('Error resolving media URLs: $e');
      _setErrorState();
    }
  }

  void _loadMedia(String url) {
    setState(() {
      _isLoading = true;
      _isMediaReady = false;
    });
    if (_isVideoUrl(url)) {
      _mediaType = MediaType.video;
      _initializeVideo(url);
    } else if (_isAnimatedWebpUrl(url)) {
      _mediaType = MediaType.animatedWebp;
      _initializeAnimatedWebp(url);
    } else {
      _mediaType = MediaType.image;
      _loadImage(url);
    }
  }

  bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.webm', '.mkv'];
    return videoExtensions.any((ext) => url.toLowerCase().endsWith(ext)) ||
        url.contains('video') ||
        url.contains('mp4') ||
        url.contains('mov');
  }

  bool _isAnimatedWebpUrl(String url) {
    return url.toLowerCase().endsWith('.webp');
  }

  void _initializeVideo(String url) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.network(url);
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      await _videoController!.setVolume(0.0);
      _ensureVideoPlayback();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isMediaReady = true;
        });
      }
    } catch (e) {
      developer.log("Error initializing video: $e");
      _handleMediaError();
    }
  }

  void _initializeAnimatedWebp(String url) {
    // For animated WebP, we'll consider it loaded once the network image starts loading
    _loadImage(url);
  }

  void _loadImage(String url) {
    final imageProvider = NetworkImage(url);
    imageProvider.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (info, synchronousCall) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _isMediaReady = true;
                });
              }
            },
            onError: (exception, stackTrace) {
              developer.log("Error loading image: $exception");
              _handleMediaError();
            },
          ),
        );
  }

  void _handleMediaError() {
    if (_fallbackMediaUrl != null && _fallbackMediaUrl != _currentMediaUrl) {
      developer.log("Attempting to load fallback media");
      _currentMediaUrl = _fallbackMediaUrl!;
      _loadMedia(_currentMediaUrl);
    } else {
      _setErrorState();
    }
  }

  void _setErrorState() {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isMediaReady = false;
      });
    }
  }

  void _toggleFullscreen() {
    if (_isFullscreenEnabled) {
      Navigator.of(context)
          .push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullscreenMediaView(
          mediaUrl: _currentMediaUrl,
          mediaType: _mediaType,
          videoController: _videoController,
          enablePinchToZoom: _isPinchZoomEnabled,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ))
          .then((_) {
        if (_mediaType == MediaType.video && _videoController != null) {
          _ensureVideoPlayback();
        }
      });
    }
  }

  void forcePlayVideo() {
    if (_mediaType == MediaType.video && _videoController != null) {
      _videoController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key('custom-media-widget-${widget.media}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: GestureDetector(
        onTap: _isFullscreenEnabled ? _toggleFullscreen : null,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft:
                Radius.circular(widget.topLeftRadius ?? widget.borderRadius),
            topRight:
                Radius.circular(widget.topRightRadius ?? widget.borderRadius),
            bottomLeft:
                Radius.circular(widget.bottomLeftRadius ?? widget.borderRadius),
            bottomRight: Radius.circular(
                widget.bottomRightRadius ?? widget.borderRadius),
          ),
          child: Container(
            width: widget.width,
            height: widget.heightDynamic ?? widget.height,
            color: _effectiveBackgroundColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isMediaReady) _buildMedia(),
                if (_isLoading || !_isMediaReady)
                  Shimmer.fromColors(
                    baseColor: _effectiveBackgroundColor,
                    highlightColor: _effectiveShimmerColor,
                    period: const Duration(milliseconds: 1500),
                    child: Container(
                      color: _effectiveShimmerColor,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedia() {
    switch (_mediaType) {
      case MediaType.video:
        return _buildVideo();
      case MediaType.animatedWebp:
        return _buildAnimatedWebp();
      case MediaType.image:
        return _buildImage();
      case MediaType.unknown:
        return Container();
    }
  }

  Widget _buildVideo() {
    return _videoController!.value.isInitialized
        ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          )
        : Container();
  }

  Widget _buildAnimatedWebp() {
    return Image.network(
      _currentMediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        developer.log("Error in Image.network: $error");
        return Container();
      },
    );
  }

  Widget _buildImage() {
    return Image.network(
      _currentMediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        developer.log("Error in Image.network: $error");
        return Container();
      },
    );
  }
}

class _FullscreenMediaView extends StatelessWidget {
  final String mediaUrl;
  final MediaType mediaType;
  final VideoPlayerController? videoController;
  final bool enablePinchToZoom;

  const _FullscreenMediaView({
    required this.mediaUrl,
    required this.mediaType,
    this.videoController,
    required this.enablePinchToZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: _buildFullscreenMedia(),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenMedia() {
    switch (mediaType) {
      case MediaType.video:
        return videoController!.value.isInitialized
            ? AspectRatio(
                aspectRatio: videoController!.value.aspectRatio,
                child: VideoPlayer(videoController!),
              )
            : const Center(child: CircularProgressIndicator());
      case MediaType.animatedWebp:
      case MediaType.image:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: enablePinchToZoom
              ? PhotoView(
                  imageProvider: NetworkImage(mediaUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  initialScale: PhotoViewComputedScale.contained,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                )
              : Image.network(
                  mediaUrl,
                  fit: BoxFit.contain,
                ),
        );
      case MediaType.unknown:
        return Container();
    }
  }
}