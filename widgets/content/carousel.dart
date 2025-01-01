import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CarouselWidget extends StatefulWidget {
  final List<Widget> items;
  final double? height;
  final bool showIndicator;
  final ScrollController? controller;

  const CarouselWidget({
    super.key,
    required this.items,
    this.height,
    this.showIndicator = true,
    this.controller,
  });

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.93,
      initialPage: _currentPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (!_isAnimating) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height ?? MediaQuery.of(context).size.height * 0.5,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: _currentPage == index ? 0 : 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
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
                    child: Container(
                      color: Colors.white,
                      child: widget.items[index],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.showIndicator && widget.items.length > 1) ...[
          const SizedBox(height: 16),
          SmoothPageIndicator(
            controller: _pageController,
            count: widget.items.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              spacing: 8,
              expansionFactor: 2,
              activeDotColor: const Color(0xFFF7C325),
              dotColor: Colors.grey.withOpacity(0.2),
            ),
            onDotClicked: (index) {
              setState(() {
                _isAnimating = true;
              });
              _pageController
                  .animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                  .then((_) {
                setState(() {
                  _isAnimating = false;
                });
              });
            },
          ),
        ],
      ],
    );
  }
}

// Widget auxiliar para controles de navegación personalizados
class CarouselControls extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoBack;
  final bool canGoForward;

  const CarouselControls({
    super.key,
    required this.onPrevious,
    required this.onNext,
    this.canGoBack = true,
    this.canGoForward = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: canGoBack ? onPrevious : null,
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: canGoBack 
                ? Colors.black54 
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        IconButton(
          onPressed: canGoForward ? onNext : null,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 20,
            color: canGoForward 
                ? Colors.black54 
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
} 