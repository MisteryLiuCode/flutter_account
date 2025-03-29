import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';

import '../../../common/constants.dart';
import '../../../common/db_tools/db_helper.dart';
import '../../../models/brief_accounting_state.dart';

class Searchindex extends StatefulWidget {
  const Searchindex({Key? key}) : super(key: key);

  @override
  State<Searchindex> createState() => SearchPage();
}

class SearchPage extends State<Searchindex> {
  // 单纯的账单条目列表
  List<BillItem> billItems = [];

  bool search = false;

  // 按日分组后的账单条目对象(key是日期，value是条目列表)
  Map<String, List<BillItem>> billItemGroupByDayMap = {};

  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // 所有数据放入列表中
    loadBillData();
  }

  loadBillData() async {
    CusDataResult temp = await _dbHelper.queryBillItemListApi(null, null);
    var newData = temp.data as List<BillItem>;
    setState(() {
      billItems = newData;
      // billItemGroupByDayMap = groupBy(billItems, (BillItem item) => item.date);
    });
  }

  void searchBill(String query) {
    if (query.isEmpty) {
      setState(() {
        search = false; // 显示所有数据
      });
    } else {
      var searchBillItems = billItems.where((item) {
        return item.item != null &&
            item.item.toLowerCase().contains(query.toLowerCase());
      }).toList();
      setState(() {
        search = true; // 显示搜索结果
        // 使用contains方法进行模糊匹配
        billItemGroupByDayMap =
            groupBy(searchBillItems, (BillItem item) => item.date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 220, 68),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 220, 68),
        title: Text('搜索'),
      ),
      body: Column(
        children: [
          // Search bar with filter options
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (query) {
                searchBill(query);
              },
              decoration: InputDecoration(
                hintText: '搜索类别/备注/金额',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Placeholder area (no data)
          if (!search || search && billItemGroupByDayMap.isEmpty) buildNoData(),
          if (search) buildBillItemList()
        ],
      ),
    );
  }

  buildNoData() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_copy_outlined,
              color: Colors.grey,
              size: 50,
            ),
            SizedBox(height: 10),
            Text(
              search ? '搜索无数据' : '暂无数据',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

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
        childBuilder: (BuildContext context, ScrollPhysics physics) {
          return CustomScrollView(
            slivers: [
              const HeaderLocator.sliver(),
              // SliverList(delegate: SliverChildListDelegate(_data.map((e) => listItem(e)).toList())),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildBillItemCard(index);
                  },
                  childCount: billItemGroupByDayMap.entries.length,
                ),
              ),
              const FooterLocator.sliver(),
            ],
            physics: physics,
          );
        },
      ),
    );
  }

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
            trailing: Text(
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
