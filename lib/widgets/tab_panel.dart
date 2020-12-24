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

  _DraggableTab(
      {Key key,
      @required this.index,
      this.child,
      this.selectedElevation = 4,
      this.updatingListener,
      this.finishListener,
      this.tapListener})
      : super(key: key);

  @override
  State createState() => _DraggableTabState();
}

class _DraggableTabState extends State<_DraggableTab> {
  double left = 0;
  double _lastX = 0;
  bool selected = false;

  void setSelected(bool selected) {
    setState(() {
      this.selected = selected;
    });
  }

  void setLeft(double left) {
    setState(() {
      this.left = left;
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
            alignment: Alignment.center,
            height: widget.height,
            child: widget.child,
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

  /// when the tab is selected, it will be called
  final Function(int) updateSelected;

  _DraggableTabBar({Key key, this.children = const [], this.updateSelected}) : super(key: key);

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

    int index = 0;
    widget.children.forEach((child) {
      keys.add(GlobalKey<_DraggableTabState>());
      lefts.add(0);
      widths.add(0);
      indexes.add(index);
      tabs.add(_DraggableTab(
        key: keys[index],
        child: widget.children[index],
        index: index,
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
      index++;
    });
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

  List<Widget> get tabList => tabs == null
      ? tabNames.map((e) => Text(e)).toList() : tabs;

  TabPage({this.tabs, this.tabNames = const [], this.pages = const []}) {
    assert((tabs != null && tabs.length == pages.length) || tabNames.length == pages.length);
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
          children: widget.tabList,
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
