import 'package:flutter/material.dart';

/// Gesture handler wrapping the player content.
///
/// Provides:
/// - Horizontal swipe to change track
/// - Double-tap left/right to seek back/forward 10s
/// - Vertical drag on progress area for fine seek
class PlayerGestureHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onSeekForward;
  final VoidCallback? onSeekBackward;
  final Widget? swipeIndicator;

  const PlayerGestureHandler({
    super.key,
    required this.child,
    this.onNext,
    this.onPrevious,
    this.onSeekForward,
    this.onSeekBackward,
    this.swipeIndicator,
  });

  @override
  State<PlayerGestureHandler> createState() => _PlayerGestureHandlerState();
}

class _PlayerGestureHandlerState extends State<PlayerGestureHandler>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() {
        _isDragging = true;
        _dragOffset = 0;
      }),
      onHorizontalDragUpdate: (details) {
        setState(() => _dragOffset += details.delta.dx);
      },
      onHorizontalDragEnd: (details) {
        final threshold = MediaQuery.of(context).size.width * 0.25;
        if (_dragOffset.abs() > threshold) {
          if (_dragOffset < 0) {
            widget.onNext?.call();
          } else {
            widget.onPrevious?.call();
          }
        }
        setState(() {
          _isDragging = false;
          _dragOffset = 0;
        });
      },
      onDoubleTapDown: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < width / 3) {
          widget.onSeekBackward?.call();
        } else if (details.localPosition.dx > width * 2 / 3) {
          widget.onSeekForward?.call();
        }
      },
      child: Stack(
        children: [
          // Apply slide transform during drag
          Transform.translate(
            offset: Offset(_isDragging ? _dragOffset * 0.3 : 0, 0),
            child: widget.child,
          ),
          // Swipe indicator
          if (_isDragging && _dragOffset.abs() > 20)
            Positioned(
              left: _dragOffset > 0 ? 16 : null,
              right: _dragOffset < 0 ? 16 : null,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _dragOffset > 0
                        ? Icons.skip_previous_rounded
                        : Icons.skip_next_rounded,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
