
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart' hide CarouselController;

import 'accounting/bill_item_modify/index.dart';
import 'accounting/bill_report/index.dart';
import 'accounting/bill_list/index.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  PageController _pageController = PageController();

  static final GlobalKey<BillItemIndexState> billItemIndexKey = GlobalKey<BillItemIndexState>();

  static final List<Widget> _widgetOptions = <Widget>[
    BillItemIndex(key: billItemIndexKey),
    BillReportIndex(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SizedBox.expand(
          child: PageView(
            controller: _pageController,
            // onPageChanged: (index) {
            //   setState(() => _selectedIndex = index);
            // },
            children: _widgetOptions,
            physics: NeverScrollableScrollPhysics(),
          ),
        ),
        bottomNavigationBar: ConvexAppBar(
          backgroundColor: Color.fromARGB(255,255,215,5),
          style: TabStyle.fixedCircle,
            onTap: (index) {
              if (index == 1) {
                // “添加”按钮逻辑，打开新的页面
                // Navigator.push(
                //   context,
                //   PageRouteBuilder(
                //     pageBuilder: (context, animation, secondaryAnimation) {
                //       return BillEditPage(); // 你的添加页面
                //     },
                //     transitionsBuilder:
                //         (context, animation, secondaryAnimation, child) {
                //       const begin = Offset(0.0, 1.0); // 从底部进入
                //       const end = Offset.zero;
                //       const curve = Curves.easeInOut;
                //       var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                //       var offsetAnimation = animation.drive(tween);
                //       return SlideTransition(position: offsetAnimation, child: child);
                //     },
                //   ),
                // );
                // 点击添加按钮
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BillEditPage(),
                  ),
                ).then((isAdded) async {
                  if (isAdded == true) {
                    // await Future.delayed(const Duration(milliseconds:150 ));
                    // 调用 BillItemIndex 的刷新方法
                    billItemIndexKey.currentState?.controller.callRefresh();
                  }
                });
              } else {
                setState(() {
                  print("点击了" + index.toString());
                  _selectedIndex = index == 0 ? 0 : index - 1;  // 索引计算
                  _pageController.animateToPage(
                    _selectedIndex,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                });
              }
            },
          items: [
            TabItem(icon: Icons.history,isIconBlend: false, title: '记录'),
            TabItem(icon: Icons.add,isIconBlend: false, title: '添加'),
            TabItem(icon: Icons.pie_chart,isIconBlend: false, title: '统计'),
          ],
        ),
      ),
    );
  }
}
