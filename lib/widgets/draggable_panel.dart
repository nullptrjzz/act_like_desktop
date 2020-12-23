import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 可拖动的边缘，包括上下左右
class DraggableSides {
  final bool top;
  final bool bottom;
  final bool left;
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

/// 可拖拉缩放的Panel，由[Container]包裹一个[child]。
/// 鼠标在组件边缘时会变成可缩放的指针，参考[SystemMouseCursors]中的相关对象。
class DraggablePanel extends StatefulWidget {
  /// 初始的组件大小
  final Size size;

  /// 组件最小大小
  final Size minSize;

  /// 组件最大大小
  final Size maxSize;
  final Widget child;

  /// 可拖拉边框的粗细，默认为8
  final double sideSize;

  /// 可拖动的边缘，包括上下左右
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
  GestureDetector cornerDetector([double fh = 1, double fv = 1, int style = 0]) =>
      GestureDetector(
        child: MouseRegion(
          child: Container(
            width: widget.sideSize,
          ),
          cursor: style == 0 ? SystemMouseCursors.resizeUpLeftDownRight
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
            width = min(
                max(widget.minSize.width,
                    width + fh * (d.localPosition.dx - lastX)),
                widget.maxSize.width);
            height = min(
                max(widget.minSize.height,
                    height + fv * (d.localPosition.dy - lastY)),
                widget.maxSize.height);
            lastX = d.localPosition.dx;
            lastY = d.localPosition.dy;
          });
        },
        onHorizontalDragUpdate: (d) {
          setState(() {
            width = min(
                max(widget.minSize.width,
                    width + fh * (d.localPosition.dx - lastX)),
                widget.maxSize.width);
            height = min(
                max(widget.minSize.height,
                    height + fv * (d.localPosition.dy - lastY)),
                widget.maxSize.height);
            lastX = d.localPosition.dx;
            lastY = d.localPosition.dy;
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
          lastY = d.localPosition.dy;
        },
        onHorizontalDragStart: (d) {
          lastX = d.localPosition.dx;
          lastY = d.localPosition.dy;
        },
        onVerticalDragUpdate: (d) {
          setState(() {
            width = min(
                max(widget.minSize.width,
                    width + f * (d.localPosition.dx - lastX)),
                widget.maxSize.width);
            lastX = d.localPosition.dx;
          });
        },
        onHorizontalDragUpdate: (d) {
          setState(() {
            width = min(
                max(widget.minSize.width,
                    width + f * (d.localPosition.dx - lastX)),
                widget.maxSize.width);
            lastX = d.localPosition.dx;
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
          lastX = d.localPosition.dx;
          lastY = d.localPosition.dy;
        },
        onHorizontalDragStart: (d) {
          lastX = d.localPosition.dx;
          lastY = d.localPosition.dy;
        },
        onVerticalDragUpdate: (d) {
          setState(() {
            height = min(
                max(widget.minSize.height,
                    height + f * (d.localPosition.dy - lastY)),
                widget.maxSize.height);
            lastY = d.localPosition.dy;
          });
        },
        onHorizontalDragUpdate: (d) {
          setState(() {
            height = min(
                max(widget.minSize.height,
                    height + f * (d.localPosition.dy - lastY)),
                widget.maxSize.height);
            lastY = d.localPosition.dy;
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
