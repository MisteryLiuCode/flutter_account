// ignore_for_file: avoid_print
import 'dart:ui' as ui;

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:collection/collection.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/db_tools/db_helper.dart';
import '../../../models/brief_accounting_state.dart';

import '../bill_item_modify/index.dart';

/// 2024-05-28
/// 账单列表，按月查看
///   默认显示当前月的所有账单项次，并额外显示每天的总计的支出和收入；
///   点击选中年月日期，可切换到其他月份；选中的月份所在行有当月总计的支出和收入。
///   在显示选中月日期的清单时，如果有的话，可以上拉加载上一个月的项次数据，下拉加载后一个月的项次数据；
///     如果当前加载的账单项次不止一个月的数据，则在滚动时大概估算到当前展示的是哪一个月的项次，来更新显示的选中日期；
///     实现逻辑：
///         主要是绘制好每月项次列表后，保留每个月占用的总高度，存入数组；
///         根据滚动控制器得到当前已经加载的高度，和保留每个月总高度的对象列表进行比较；
///         如果“上一个的累加高度 <=  已加载的高度 < 当前的累加高度”，则当前月就是要展示的月份
///     两点注意：
///         1 存每月列表组件高度的数组存的是月份排序后的累加高度：
///            [{'2024-03': 240}, // 3月份组件总高度 240
///             {'2024-02': 490}, // 4月份组件总高度 490-240=250
///             {'2024-01': 630}, // 5月份组件总高度 630-490=140
///             {'2023-12': 670}, // ...
///             // ... 更多的月份数据];
///         2 滚动控制器总加载的高度和实际组件逐个计算的高度不一致，原因不明？？？
class CategoryList extends StatefulWidget {
  final String category;
  final String selectMonth;
  final String totalAmount;

  const CategoryList({
    Key? key,
    required this.category,
    required this.selectMonth,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CategoryList> createState() => CategoryListState();
}

class CategoryListState extends State<CategoryList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final DBHelper _dbHelper = DBHelper();

  // 账单项次的列表滚动控制器
  ScrollController scrollController = ScrollController();

  // 是否查询账单项次中
  bool isLoading = false;

  // 单纯的账单条目列表
  List<BillItem> billItems = [];

  // 按日分组后的账单条目对象(key是日期，value是条目列表)
  Map<String, List<BillItem>> billItemGroupByDayMap = {};

  // 2024-05-27 因为默认查询有额外的分组统计等操作，
  // 所以关键字查询条目的展示要和默认的区分开来
  bool isQuery = false;

  // 关键字输入框控制器
  TextEditingController searchController = TextEditingController();

  // 账单可查询的范围，默认为当前，查询到结果之后更新
  SimplePeriodRange billPeriod = SimplePeriodRange(
    minDate: DateTime.now(),
    maxDate: DateTime.now(),
  );

  // 被选中的月份(yyyy-MM格式，作为查询条件或者反格式化为Datetime时，手动补上day)
  String selectedMonth = DateFormat(constMonthFormat).format(DateTime.now());

  // 虽然是已查询的最大最小日期，但逻辑中只关注年月，所以日最好存1号，避免产生影响
  DateTime minQueryedDate = DateTime.now();
  DateTime maxQueryedDate = DateTime.now();

  // 用户滑动的滚动方向，往上拉是up，往下拉时down，默认为none
  // 往上拉到头时获取更多数据就是取前一个月的，往下拉到头获取更多数据就是后一个月的
  String scollDirection = "none";

  // 用一个map来保存每个月份的条目数据组件的总高度
  // 如果加载了多个月份的数据，可以用列表已滚动的高度和每个月的组件总高度进行对比，得到当前月份
  List<Map<String, double>> monthlyWidgetHeights = [];

  // 选中查询的类型，默认是全部，可切换到“支出|收入|全部”
  String selectedType = "全部账单";

  int incomeTotal = 0;

  int expendTotal = 0;

  // 2024-06-26 是否显示，我自己要用的从json文件导入账单列表数据的按钮
  bool isShowMock = false;
  late Future<BillPeriodCount?> _billCountFuture;

  EasyRefreshController controller = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  @override
  void initState() {
    super.initState();

    // 2024-05-25 初始化查询时就更新已查询的最大日期和最小日期为当天所在月份的1号(后续用到的地方也只关心年月)
    maxQueryedDate = DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();
    minQueryedDate = DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();

    print("初始化时的最大最小查询日期-------------$maxQueryedDate $minQueryedDate");

    getBillPeriod();
    loadBillItemsByMonth();

    _billCountFuture = loadBillCountByMonth();
  }

  void refreshData() {
    setState(() {
      // 调用现有的加载账单数据方法
      loadBillItemsByMonth();
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  /**
   * 获取数据库中账单记录的日期起迄范围
   */
  getBillPeriod() async {
    var tempPeriod = await _dbHelper.queryDateRangeListApi();
    setState(() {
      billPeriod = tempPeriod;
    });
  }

  /**
   * 查询指定月份账单项次列表
   * 获取系统当月的所有账单条目查询出来(这样每日、月度统计就是正确的)，
   * 下滑显示完当月数据化，加载上一个月的所有数据出来
   */
  Future<void> loadBillItemsByMonth() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });
    // 请求线上账本列表
    CusDataResult temp =
        await _dbHelper.queryBillItemListApi(widget.selectMonth, widget.category);
    var newData = temp.data as List<BillItem>;

    setState(() {
      // 如果是往上拉加载数据
      if (scollDirection == "down") {
        billItems.clear();
        billItems.addAll(newData);
      } else {
        billItems.clear();
        billItems.addAll(newData);
      }
      _computeMonthWidgetHeights();
      scrollController.jumpTo(0.0);
      billItemGroupByDayMap = groupBy(billItems, (item) => item.date);
      // 计算支出/收入次数
      expendTotal = 0;
      incomeTotal = 0;
      billItems.forEach((element) {
        if (element.itemType == 1) {
          expendTotal++;
        } else {
          incomeTotal--;
        }
      });
      isLoading = false;
    });
  }

  // 查询选中月份的总支出/收入信息
  Future<BillPeriodCount?> loadBillCountByMonth() async {
    return await _dbHelper.queryBillCountListApi(selectedMonth);
  }

  // 查询指定月份的账单项次数据
  // 在切换了当前月份等情况下回用到
  void handleSearch() {
    setState(() {
      billItems.clear();
      scollDirection == "none";
      _billCountFuture = loadBillCountByMonth();
    });
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();

    loadBillItemsByMonth();
  }

  /*
  不过累加的值和实际的值对不上。
  比如5月测试数据，额外的ListTile*15,原本GestureDetector(child:ListTile())*42,
  计算的高度：15*(48+16+8[card的边框])+56*42=3432
  实际ListView滚动的总高度：3030
  */
  _computeMonthWidgetHeights() {
// 每次都要重新计算，避免累加
    monthlyWidgetHeights.clear();

    // 按照月份分组
    var temp = groupBy(billItems, (item) => item.date.substring(0, 7));

    var monthHegth = 0.0;
    for (var i = 0; i < temp.entries.length; i++) {
      var entry = temp.entries.toList()[i];

      // 处理每个月份的数据
      String tempMonth = entry.key;
      // 每个月实际拥有的账单项次数量
      List<BillItem> tempMonthItems = entry.value;

      // 按天分组统计支出收入的额外项次的数量
      var extraItemsLength =
          groupBy(tempMonthItems, (item) => item.date).entries.length;

      // 当前月份的组件总高度
      monthHegth += tempMonthItems.length * 64.0 + extraItemsLength * (48 + 8);
      // 实际测试，滚动的值比计算的值要小一些：
      //    第1、2个月份计算结果差402，第3个月差388，第4、5、6个月346，第7个月差332，第8个月318……
      //    没有继续下去，原因不明？？？暂时第一个月少算402,后面的几十个像素基本对得上。
      if (i == 0) {
        monthHegth -= 402;
      }

      // 注意，这里存的是每个月的累加高度
      monthlyWidgetHeights.add({tempMonth: monthHegth});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 220, 68),
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('总支出：${widget.totalAmount}￥'),
        leading: IconButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back)
        ),
        backgroundColor: Color.fromARGB(255, 255, 215, 5),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Image.asset('images/search.png', width: 44, height: 44),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            buildBillItemList(),
          ],
        ),
      ),
    );
  }

  // 这里是月度账单下拉后查询的总计结果，理论上只存在1条，不会为空。
  _buildCurrentMonthCountTile(int flag) {
    return FutureBuilder<BillPeriodCount?>(
      future: _billCountFuture,
      builder:
          (BuildContext context, AsyncSnapshot<BillPeriodCount?> snapshot) {
        List<Widget> children;
        // 有数据
        if (snapshot.hasData) {
          var data = snapshot.data!;
          if (data != null) {
            children = <Widget>[
              Text(
                flag == 0
                    ? "¥${data.expendTotalValue}"
                    : "¥${data.incomeTotalValue}",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ];
          } else {
            children = <Widget>[const Text("该月份无账单")];
          }
        } else if (snapshot.hasError) {
          // 有错误
          children = <Widget>[
            const Icon(Icons.error_outline, color: Colors.red, size: 30),
          ];
        } else {
          // 加载中
          children = const <Widget>[
            SizedBox(width: 30, height: 30, child: CircularProgressIndicator()),
          ];
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }

  /// 构建收支条目列表(都是完整月份的列表加在一起的)
  buildBillItemList() {
    return Expanded(
      child: EasyRefresh.builder(
        header: const CupertinoHeader(
          position: IndicatorPosition.locator,
          hapticFeedback: true,
        ),
        footer: const CupertinoFooter(
          position: IndicatorPosition.locator,
          hapticFeedback: true,
        ),
        // onRefresh: () async {
        //   await Future.delayed(const Duration(seconds: 2));
        //   if (!mounted) {}
        //   DateTime selectedMonthDate = DateTime.parse("$selectedMonth-01");
        //   DateTime nextMonthDate = DateTime(
        //     selectedMonthDate.year,
        //     selectedMonthDate.month + 1,
        //     selectedMonthDate.day,
        //   );
        //   String nextMonth = DateFormat(constMonthFormat).format(nextMonthDate);
        //   // 如果当前月份的下一月的1号已经账单中最大日期了，就算到顶了也没有数据可加载乐
        //   if (nextMonthDate.isAfter(billPeriod.maxDate)) {
        //     setState(() {
        //       selectedMonth =
        //           DateFormat(constMonthFormat).format(maxQueryedDate);
        //       scollDirection = "down";
        //       loadBillItemsByMonth();
        //       _billCountFuture = loadBillCountByMonth();
        //     });
        //     controller.finishRefresh(IndicatorResult.success);
        //     controller.resetHeader();
        //     print("已经到最大日期了，不能加载下一个月的数据了");
        //     return;
        //   }
        //   // 正常下拉加载更新的数据，要更新当前选中值和最大查询日期
        //   setState(() {
        //     scollDirection = "down";
        //     selectedMonth = nextMonth;
        //     maxQueryedDate = nextMonthDate;
        //     loadBillItemsByMonth();
        //     _billCountFuture = loadBillCountByMonth();
        //   });
        //   controller.finishRefresh(IndicatorResult.success);
        //   controller.resetHeader();
        // },
        // onLoad: () async {
        //   await Future.delayed(const Duration(seconds: 2));
        //   // 如果已经销毁，不再刷新数据
        //   if (!mounted) {}
        //   DateTime selectedMonthDate = DateTime.parse("$selectedMonth-01");
        //   DateTime lastMonthDate = DateTime(
        //     selectedMonthDate.year,
        //     selectedMonthDate.month - 1,
        //     selectedMonthDate.day,
        //   );
        //   String lastMonth = DateFormat(constMonthFormat).format(lastMonthDate);
        //
        //   // 如果当前月份已经账单中最大日期了，到顶了也不再加载
        //   if (lastMonthDate.isBefore(billPeriod.minDate)) {
        //     setState(() {
        //       selectedMonth =
        //           DateFormat(constMonthFormat).format(minQueryedDate);
        //     });
        //     controller.finishLoad(IndicatorResult.success);
        //     controller.resetFooter();
        //     print("已经到最小日期了，不能加载更多数据了");
        //     return;
        //   }
        //
        //   // 上拉还有旧数据可查就继续查询
        //   setState(() {
        //     scollDirection = "up";
        //     selectedMonth = lastMonth;
        //     minQueryedDate = lastMonthDate;
        //     loadBillItemsByMonth();
        //     _billCountFuture = loadBillCountByMonth();
        //   });
        //   controller.finishLoad(IndicatorResult.success);
        //   controller.resetFooter();
        // },
        childBuilder: (BuildContext context, ScrollPhysics physics) {
          return CustomScrollView(
            controller: isQuery ? null : scrollController,
            slivers: [
              const HeaderLocator.sliver(),
              // SliverList(delegate: SliverChildListDelegate(_data.map((e) => listItem(e)).toList())),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == billItemGroupByDayMap.entries.length) {
                      return buildLoader(isLoading);
                    } else {
                      return _buildBillItemCard(index);
                    }
                  },
                  childCount: billItemGroupByDayMap.entries.length,
                ),
              ),
              const FooterLocator.sliver(),
            ],
            physics: physics,
          );
        },
        controller: controller,
      ),
    );
  }

  // 构建账单项次条目组件(Card中有手势包裹的Tile或者Row)
  _buildBillItemCard(int index) {
    // 获取当前分组的日期和账单项列表
    var entry = billItemGroupByDayMap.entries.elementAt(index);
    String date = entry.key;
    List<BillItem> itemsForDate = entry.value;

    // 计算每天的总支出/收入
    double totalExpend = 0.0;
    double totalIncome = 0.0;
    for (var item in itemsForDate) {
      if (item.itemType != 0) {
        totalExpend += item.number;
      } else {
        totalIncome += item.number;
      }
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(date, style: TextStyle(fontSize: 15.sp)),
            trailing: isQuery
                ? null
                : Text(
                    '支出 ¥${_calculateTotalExpend(itemsForDate).toStringAsFixed(2)} 收入 ¥${_calculateTotalIncome(itemsForDate).toStringAsFixed(2)}',
                    style: TextStyle(
                      // color: Theme.of(context).primaryColor,
                      color: Color(0xFF333333),
                      fontSize: 13.sp,
                    ),
                  ),
            // tileColor: Colors.orange,
            tileColor: Color.fromARGB(255, 255, 220, 68),
            dense: true,
            // 可以添加副标题或尾随图标等
          ),
          // const Divider(), // 可选的分隔线
          // 为每个BillItem创建一个Tile
          Column(
            children: ListTile.divideTiles(
              context: context,
              tiles: itemsForDate.map((item) {
                return SwipeActionCell(
                  key: ValueKey(item.id),
                  trailingActions: <SwipeAction>[
                    SwipeAction(
                      nestedAction: SwipeNestedAction(title: "确认删除"),
                      title: "删除",
                      onTap: (CompletionHandler handler) async {
                        await handler(true);
                        _deleteBillItem(item);
                      },
                      color: Colors.red,
                    ),
                    SwipeAction(
                      title: "编辑",
                      onTap: (CompletionHandler handler) async {
                        handler(false);
                        _editBillItem(item);
                      },
                      color: Colors.grey,
                    ),
                  ],
                  child: _buildItem(item, type: "tile"),
                  backgroundColor: Color.fromARGB(255, 255, 220, 68),
                );
              }).toList(),
            ).toList(),
          ),
        ],
      ),
    );
  }

  _buildItem(BillItem item, {String type = 'tile'}) {
    String recordIcon = item.account != null
        ? "images/${item.account!.replaceAll(":", "_")}.png"
        : "images/Expenses_other.png";
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.sp, horizontal: 10.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.sp, vertical: 12.sp),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 40.sp,
              height: 40.sp,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20.sp),
              ),
              child: Image.asset(
                recordIcon, // 直接使用图片路径
              ),
            ),
            SizedBox(width: 15.sp),
            // 中间文本
            Expanded(
              child: Text(
                item.item,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            // 右侧金额
            Text(
              '${item.itemType == 0 ? '+' : '-'}¥${item.number.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: item.itemType == 0 ? Colors.green : Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBillItem(BillItem item) async {
    _dbHelper.deleteBillItemByIdApi(item.id);
    // 等待2s再刷新
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      handleSearch();
    });
  }

  void _editBillItem(BillItem item) {
    print("编辑对象item:" + item.toString());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillEditPage(billItem: item),
      ),
    ).then((value) {
      if (value != null && value) {
        setState(() {
          controller.callRefresh();
        });
      }
    });
  }

  double _calculateTotalExpend(List<BillItem> items) {
    return items
        .where((item) => item.itemType != 0)
        .fold(0.0, (sum, item) => sum + item.number);
  }

  double _calculateTotalIncome(List<BillItem> items) {
    return items
        .where((item) => item.itemType == 0)
        .fold(0.0, (sum, item) => sum + item.number);
  }
}
