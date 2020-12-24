import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Draggable sides, including top, bottom, left and right.
class DraggableSides {
  /// enables the drag-resize operation on the top edge
  final bool top;

  /// enables the drag-resize operation on the bottom edge
  final bool bottom;

  /// enables the drag-resize operation on the left edge
  final bool left;

  /// enables the drag-resize operation on the right edge
  final bool right;

  const DraggableSides(
      {this.top = false,
      this.bottom = false,
      this.left = false,
      this.right = false});

  const DraggableSides.none()
      : this(top: false, bottom: false, left: false, right: false);

  DraggableSides.all({bool isDraggable = false})
      : this(
            top: isDraggable,
            bottom: isDraggable,
            left: isDraggable,
            right: isDraggable);

  DraggableSides.symmetric({bool vertical = false, bool horizontal = false})
      : this(
            top: vertical,
            bottom: vertical,
            left: horizontal,
            right: horizontal);
}

/// A draggable panel, containing a [Container] which wraps the [child].
/// Mouse pointer will become the "resize" style, see [SystemMouseCursors].
class DraggablePanel extends StatefulWidget {
  /// initial widget size
  final Size size;

  /// minimum widget size
  final Size minSize;

  /// maximum widget size
  final Size maxSize;

  /// widget in the panel
  final Widget child;

  /// the width of draggable edge, default to 8
  final double sideSize;

  /// draggable sides, including top, bottom, left and right
  final DraggableSides draggableSides;

  DraggablePanel(
      {Key key,
      @required this.size,
      this.minSize = const Size(0, 0),
      this.maxSize = const Size(double.maxFinite, double.maxFinite),
      this.draggableSides = const DraggableSides.none(),
      this.sideSize = 8,
      @required this.child})
      : super(key: key) {
    assert(size != null);
    assert(size.width >= minSize.width);
    assert(size.height >= minSize.height);
  }

  @override
  State createState() => _DraggablePanelState(key);
}

class _DraggablePanelState extends State<DraggablePanel> {
  final Key key;
  double width;
  double height;
  _DraggablePanelState(this.key);

  double lastX = 0;
  double lastY = 0;

  @override
  void initState() {
    super.initState();

    width = widget.size.width;
    height = widget.size.height;
  }

  // 四个角上的缩放
  GestureDetector cornerDetector(
          [double fh = 1, double fv = 1, int style = 0]) =>
      GestureDetector(
        child: MouseRegion(
          child: Container(
            width: widget.sideSize,
          ),
          cursor: style == 0
              ? SystemMouseCursors.resizeUpLeftDownRight
              : SystemMouseCursors.resizeUpRightDownLeft,
        ),
        onVerticalDragStart: (d) {
          lastX = d.localPosition.dx;
          lastY = d.localPosition.dy;
        },
        onHorizontalDragStart: (d) {
          lastX = d.localPosition.dx;
          lastY = d.localPosition.dy;
        },
        onVerticalDragUpdate: (d) {
          setState(() {
            double targetX = width + fh * (d.localPosition.dx - lastX);
            double targetY = height + fv * (d.localPosition.dy - lastY);

            width =
                min(max(widget.minSize.width, targetX), widget.maxSize.width);
            height =
                min(max(widget.minSize.height, targetY), widget.maxSize.height);

            if (width == targetX) {
              lastX = d.localPosition.dx;
            }
            if (height == targetY) {
              lastY = d.localPosition.dy;
            }
          });
        },
        onHorizontalDragUpdate: (d) {
          setState(() {
            double targetX = width + fh * (d.localPosition.dx - lastX);
            double targetY = height + fv * (d.localPosition.dy - lastY);

            width =
                min(max(widget.minSize.width, targetX), widget.maxSize.width);
            height =
                min(max(widget.minSize.height, targetY), widget.maxSize.height);

            if (width == targetX) {
              lastX = d.localPosition.dx;
            }
            if (height == targetY) {
              lastY = d.localPosition.dy;
            }
          });
        },
      );

  // 横向（左右）缩放
  GestureDetector horiDetector([double f = 1]) => GestureDetector(
        child: MouseRegion(
          child: Container(
            width: widget.sideSize,
          ),
          cursor: SystemMouseCursors.resizeLeftRight,
        ),
        onVerticalDragStart: (d) {
          lastX = d.localPosition.dx;
        },
        onHorizontalDragStart: (d) {
          lastX = d.localPosition.dx;
        },
        onVerticalDragUpdate: (d) {
          setState(() {
            double targetX = width + f * (d.localPosition.dx - lastX);

            width =
                min(max(widget.minSize.width, targetX), widget.maxSize.width);

            if (width == targetX) {
              lastX = d.localPosition.dx;
            }
          });
        },
        onHorizontalDragUpdate: (d) {
          setState(() {
            double targetX = width + f * (d.localPosition.dx - lastX);

            width =
                min(max(widget.minSize.width, targetX), widget.maxSize.width);

            if (width == targetX) {
              lastX = d.localPosition.dx;
            }
          });
        },
      );

  // 纵向（上下）缩放
  GestureDetector vertDetector([double f = 1]) => GestureDetector(
        child: MouseRegion(
          child: Container(
            width: widget.sideSize,
          ),
          cursor: SystemMouseCursors.resizeUpDown,
        ),
        onVerticalDragStart: (d) {
          lastY = d.localPosition.dy;
        },
        onHorizontalDragStart: (d) {
          lastY = d.localPosition.dy;
        },
        onVerticalDragUpdate: (d) {
          setState(() {
            double targetY = height + f * (d.localPosition.dy - lastY);

            height =
                min(max(widget.minSize.height, targetY), widget.maxSize.height);

            if (height == targetY) {
              lastY = d.localPosition.dy;
            }
          });
        },
        onHorizontalDragUpdate: (d) {
          setState(() {
            double targetY = height + f * (d.localPosition.dy - lastY);

            height =
                min(max(widget.minSize.height, targetY), widget.maxSize.height);

            if (height == targetY) {
              lastY = d.localPosition.dy;
            }
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          child: widget.child,
        ),

        // left
        (widget.draggableSides.left
            ? Positioned(
                left: 0,
                width: widget.sideSize,
                top: widget.draggableSides.top ? widget.sideSize : 0,
                bottom: widget.draggableSides.bottom ? widget.sideSize : 0,
                child: horiDetector(-1),
              )
            : Container(width: 0, height: 0)),

        // top
        (widget.draggableSides.top
            ? Positioned(
                left: widget.draggableSides.left ? widget.sideSize : 0,
                right: widget.draggableSides.right ? widget.sideSize : 0,
                height: widget.sideSize,
                top: 0,
                child: vertDetector(-1),
              )
            : Container(width: 0, height: 0)),

        // right
        (widget.draggableSides.right
            ? Positioned(
                right: 0,
                width: widget.sideSize,
                top: widget.draggableSides.top ? widget.sideSize : 0,
                bottom: widget.draggableSides.bottom ? widget.sideSize : 0,
                child: horiDetector(),
              )
            : Container(width: 0, height: 0)),

        // bottom
        (widget.draggableSides.bottom
            ? Positioned(
                left: widget.draggableSides.left ? widget.sideSize : 0,
                right: widget.draggableSides.left ? widget.sideSize : 0,
                height: widget.sideSize,
                bottom: 0,
                child: vertDetector(),
              )
            : Container(width: 0, height: 0)),

        // 4个角
        // top left
        (widget.draggableSides.top && widget.draggableSides.left
            ? Positioned(
                left: 0,
                width: widget.sideSize,
                height: widget.sideSize,
                top: 0,
                child: cornerDetector(-1, -1),
              )
            : Container(width: 0, height: 0)),

        // top right
        (widget.draggableSides.top && widget.draggableSides.right
            ? Positioned(
                right: 0,
                width: widget.sideSize,
                height: widget.sideSize,
                top: 0,
                child: cornerDetector(1, -1, 1),
              )
            : Container(width: 0, height: 0)),

        // left bottom
        (widget.draggableSides.top && widget.draggableSides.bottom
            ? Positioned(
                left: 0,
                width: widget.sideSize,
                height: widget.sideSize,
                bottom: 0,
                child: cornerDetector(-1, 1, 1),
              )
            : Container(width: 0, height: 0)),

        // right bottom
        (widget.draggableSides.right && widget.draggableSides.bottom
            ? Positioned(
                right: 0,
                width: widget.sideSize,
                height: widget.sideSize,
                bottom: 0,
                child: cornerDetector(),
              )
            : Container(width: 0, height: 0)),
      ],
    );
  }
}
