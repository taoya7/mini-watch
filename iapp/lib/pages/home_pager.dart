import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../store/ws_store.dart';
import 'agent_page.dart';
import 'report_page.dart';
import 'traffic_light_page.dart';

/// 主屏左右滑动容器；切页时主动上报 ws；支持服务端远程 goto_page 跳转
class HomePager extends StatefulWidget {
  const HomePager({super.key});

  @override
  State<HomePager> createState() => _HomePagerState();
}

class _HomePagerState extends State<HomePager> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // 启动时上报首屏
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportPage(_index));
    // 订阅服务端下发的远程指令
    wsStore.addMessageListener(_onWsMessage);
  }

  @override
  void dispose() {
    wsStore.removeMessageListener(_onWsMessage);
    _controller.dispose();
    super.dispose();
  }

  /// 切页上报
  void _reportPage(int index) {
    final route = AppRoutes.byIndex(index);
    wsStore.send({
      'type': 'page_change',
      'page': {...route.toJson(), 'index': index},
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _onPageChanged(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _reportPage(index);
  }

  /// 服务端下发跳转指令
  void _onWsMessage(Object? msg) {
    if (msg is! Map) return;
    if (msg['type'] != 'goto_page') return;
    final id = msg['page_id'];
    if (id is! String) return;
    final idx = AppRoutes.pagerPages.indexWhere((r) => r.id == id);
    if (idx < 0 || idx == _index) return;
    _controller.animateToPage(
      idx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: const BouncingScrollPhysics(),
      onPageChanged: _onPageChanged,
      children: const [ReportPage(), TrafficLightPage(), AgentPage()],
    );
  }
}
