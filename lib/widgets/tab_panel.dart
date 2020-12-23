import 'package:flutter/material.dart';

class TabPage extends StatefulWidget {
  @override
  State createState() => _TagPageState();
}

class _TagPageState extends State<TabPage> with TickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: names.length, vsync: this);
  }

  final names = ['First tab', 'Second Tab', 'Third Tab'];

  Widget _buildLayout() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          indicator: UnderlineTabIndicator(),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: names
              .map((e) => Tab(
                    text: e,
                  ))
              .toList(),
          controller: _tabController,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: names
                .map((e) => Container(
                      color: Colors.red,
                      height: 200,
                      child: Center(
                        child: Text(e),
                      ),
                    ))
                .toList(),
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
