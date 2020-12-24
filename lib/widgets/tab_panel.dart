import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A tab that allows user to drag and replace the order. Used to replace
/// [Tab] on desktop.
///
/// DO NOT use it directly in your code. It has some callback functions combined with
/// [_DraggableTabBar] to complete the placement procedure. Use [TabPage] and set
/// [TabPage.tabs] or [TabPage.tabNames] instead.
class _DraggableTab extends StatefulWidget {
  /// panel height, default to 40 and changes are not supported yet
  final double height = 40;

  /// the widget in the tab
  final Widget child;

  /// the text of the tab, ignored when [child] is not null
  final String text;

  /// tab's index, useful during replacement
  final int index;

  /// when the tab is being dragged, it will be called
  final Function(int, double) updatingListener;

  /// when the drag is finished, it will be called
  final Function(int) finishListener;

  /// when the tab is clicked, it will be called
  final Function(int) tapListener;

  /// the [Material.elevation] when the tab is selected
  final double selectedElevation;

  /// whether to enable the animation of tab slide, default to true,
  /// if you want more stability and better performance, set it to false from
  /// [TabPage], with the argument [TabPage.tabAnimate]
  final bool animate;

  /// whether this tab is initially selected
  final bool initialSelect;

  _DraggableTab(
      {Key key,
      @required this.index,
      this.child,
      this.text,
      this.selectedElevation = 0,
      this.animate = true,
      this.initialSelect = false,
      this.updatingListener,
      this.finishListener,
      this.tapListener})
      : super(key: key) {
    assert(child != null || text != null);
  }

  @override
  State createState() => _DraggableTabState();
}

class _DraggableTabState extends State<_DraggableTab> {
  double left = 0;
  double targetLeft = 0;
  double _lastX = 0;
  bool selected = false;
  Timer translateTimer;
  WidgetsBinding binding;

  void setSelected(bool selected) {
    setState(() {
      this.selected = selected;
    });
  }

  void setLeft(double left) {
    if (widget.animate) {
      this.targetLeft = left;
      if (translateTimer != null && translateTimer.isActive) {
        translateTimer.cancel();
      }
      translateTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
        double delta = (targetLeft - this.left) / 5;
        setState(() {
          if (delta.abs() < 0.1) {
            this.left = targetLeft;
            timer.cancel();
          } else {
            this.left = this.left + delta;
          }
        });
      });
    } else {
      setState(() {
        this.left = left;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((timeStamp) {
      setSelected(widget.initialSelect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      child: GestureDetector(
        child: Material(
          elevation: selected ? widget.selectedElevation : 0,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8)
              ),
              border: Border(
                top: BorderSide(color: Colors.transparent),
                bottom: BorderSide(color: Colors.transparent),
                left: BorderSide(color: Colors.transparent),
                right: BorderSide(color: Colors.transparent)
              )
            ),
            alignment: Alignment.center,
            height: widget.height,
            child: widget.child ?? Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.text, style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal
              ),),
            ),
          ),
        ),
        onTap: () {
          if (widget.tapListener != null) widget.tapListener(widget.index);
        },
        onHorizontalDragStart: (detail) {
          _lastX = detail.localPosition.dx;
        },
        onHorizontalDragEnd: (detail) {
          if (widget.finishListener != null) {
            widget.finishListener(widget.index);
          }
        },
        onHorizontalDragUpdate: (detail) {
          setState(() {
            double targetX = left + (detail.localPosition.dx - _lastX);
            left = max(0, targetX);
            if (targetX == left) {
              _lastX = detail.localPosition.dx;
            }
            if (widget.updatingListener != null)
              widget.updatingListener(widget.index, left);
          });
        },
        onVerticalDragStart: (detail) {
          _lastX = detail.localPosition.dx;
        },
        onVerticalDragEnd: (detail) {
          if (widget.finishListener != null) {
            widget.finishListener(widget.index);
          }
        },
        onVerticalDragUpdate: (detail) {
          setState(() {
            double targetX = left + (detail.localPosition.dx - _lastX);
            left = max(0, targetX);
            if (targetX == left) {
              _lastX = detail.localPosition.dx;
            }
            if (widget.updatingListener != null)
              widget.updatingListener(widget.index, left);
          });
        },
      ),
    );
  }
}

/// A tab bar with [_DraggableTab] inside. Used to replace
/// [TabBar] on desktop.
///
/// Add or delete pages are not supported yet, but will be implemented in future.
///
/// DO NOT use it directly in your code. It has some callback functions combined with
/// [TabPage] to complete the placement procedure. Use [TabPage] and set
/// [TabPage.tabs] or [TabPage.tabNames] instead.
class _DraggableTabBar extends StatefulWidget {
  /// tabs
  final List<Widget> children;

  /// tab texts
  final List<String> texts;

  /// when the tab is selected, it will be called
  final Function(int) updateSelected;

  /// whether to enable the animation of tab slide, default to true,
  /// if you want more stability and better performance, set it to false from
  /// [TabPage], with the argument [TabPage.tabAnimate]
  final bool animate;

  /// tab index that initially selected
  final int initialIndex;

  _DraggableTabBar({Key key, this.children, this.texts, this.updateSelected, this.animate, this.initialIndex = 0})
      : super(key: key) {
    assert(children != null || texts != null);
  }

  @override
  State createState() => _DraggableTabBarState();
}

class _DraggableTabBarState extends State<_DraggableTabBar> {
  List<double> lefts = [];
  List<double> widths = [];
  List<GlobalKey<_DraggableTabState>> keys = [];
  List<_DraggableTab> tabs = [];
  List<int> indexes = [];
  WidgetsBinding _widgetsBinding;
  bool init = false;
  int selected = 0;

  /// find the tab to be exchanged according to [left]
  /// -1 for none
  ///
  /// Let mid = current tab's middle position x
  /// _mid = tab compared middle position x
  /// find where (left < _mid && mid > _mid) or (right > _mid && mid < _mid)
  int findExchangeIndex(int current, double left, double width) {
    // start from the first
    double mid = left + width / 2;
    double right = left + width;
    for (int i = 0; i < indexes.length; i++) {
      int realIndex = indexes[i];
      if (realIndex == current) continue;
      double _mid = lefts[realIndex] + widths[realIndex] / 2;
      if (left < _mid && mid > _mid) return realIndex;
      if (right > _mid && mid < _mid) return realIndex;
    }
    return -1;
  }

  int displayIndex(int tabIndex) {
    return indexes.indexOf(tabIndex);
  }

  void updateSelected(int index) {
    if (index >= 0 && index < indexes.length) {
      for (GlobalKey<_DraggableTabState> key in keys) {
        key.currentState.setSelected(false);
      }
      if (widget.updateSelected != null) widget.updateSelected(index);
      setState(() {
        keys[index].currentState.setSelected(true);
        selected = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _widgetsBinding = WidgetsBinding.instance;
    _widgetsBinding.addPostFrameCallback((timeStamp) {
      if (init) return;
      init = true;
      indexes.forEach((i) {
        // i is the index in the order of display
        // realIndex is the widget's index
        int realIndex = indexes[i];
        // the first element
        widths[realIndex] = keys[realIndex].currentContext.size.width;
        if (i == 0)
          lefts[realIndex] = 0;
        else {
          lefts[realIndex] = lefts[indexes[i - 1]] + widths[indexes[i - 1]];
        }
        keys[realIndex].currentState.setLeft(lefts[realIndex]);
      });
    });

    int total = widget.children != null ? widget.children.length : widget.texts.length;
    for (int index = 0; index < total; index++) {
      keys.add(GlobalKey<_DraggableTabState>());
      lefts.add(0);
      widths.add(0);
      indexes.add(index);
      tabs.add(_DraggableTab(
        key: keys[index],
        child: widget.children == null ? null : widget.children[index],
        text: widget.children == null ? widget.texts[index] : null,
        index: index,
        animate: widget.animate,
        initialSelect: widget.initialIndex == index,
        finishListener: (index) {
          keys[index].currentState.setLeft(lefts[index]);
        },
        updatingListener: (tabIndex, left) {
          // update selected when tapped
          if (selected != tabIndex) updateSelected(tabIndex);
          int toExchange = findExchangeIndex(tabIndex, left, widths[tabIndex]);
          if (toExchange != tabIndex && toExchange > -1) {
            // do exchange
            // place the tab to be exchanged
            int controlling = displayIndex(tabIndex);
            int exchanged = displayIndex(toExchange);
            if (controlling > exchanged) {
              // move to right
              lefts[tabIndex] = lefts[toExchange];
              lefts[toExchange] = lefts[tabIndex] + widths[tabIndex];
            } else {
              // move to left
              lefts[toExchange] = lefts[tabIndex];
              lefts[tabIndex] = lefts[toExchange] + widths[toExchange];
            }
            keys[toExchange].currentState.setLeft(lefts[toExchange]);

            // exchange indexes
            indexes[controlling] = toExchange;
            indexes[exchanged] = tabIndex;
          }
        },
        tapListener: (index) {
          updateSelected(index);
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (indexes.isNotEmpty) {
      List<_DraggableTab> children = indexes.map((e) => tabs[e]).toList();
      // put the selected tab on the top
      _DraggableTab top = children.removeAt(displayIndex(selected));
      if (top != null) children.add(top);
      return Container(
        height: 40,
        child: Stack(
          children: children,
        ),
      );
    }

    return Container(
      height: 40,
      child: null,
    );
  }
}

/// A container with [_DraggableTabBar] and the pages inside. Used to replace
/// [TabBar] and [TabBarView] on desktop.
class TabPage extends StatefulWidget {
  /// The tab widgets to show on tab bar
  ///
  /// If [tabs] == null, then [tabNames] must be provided
  final List<Widget> tabs;

  /// The tab names in [String] format, used when [tabs] == null
  final List<String> tabNames;

  /// Cannot be null, but empty list allowed
  final List<Widget> pages;

  /// whether to enable the animation of tab slide, default to true,
  /// if you want more stability and better performance, set it to false
  final bool tabAnimate;

  /// tab index that initially selected
  final int initialIndex;

  TabPage({this.tabs, this.tabNames = const [], this.pages = const [], this.tabAnimate = true, this.initialIndex = 0}) {
    assert((tabs != null && tabs.length == pages.length) ||
        tabNames.length == pages.length);
  }

  @override
  State createState() => _TagPageState();
}

class _TagPageState extends State<TabPage> {
  int selected = 0;

  @override
  void initState() {
    super.initState();
  }

  void updateSelected(int index) {
    setState(() {
      selected = index;
    });
  }

  Widget _buildLayout() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DraggableTabBar(
          updateSelected: updateSelected,
          children: widget.tabs,
          texts: widget.tabNames,
          animate: widget.tabAnimate,
          initialIndex: widget.initialIndex,
        ),
        Expanded(
          child: Container(
            child: IndexedStack(
              index: selected,
              children: widget.pages,
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildLayout(),
    );
  }
}
