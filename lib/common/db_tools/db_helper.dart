// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_account/models/beancount/save_bill_item.dart';
import '../../models/brief_accounting_state.dart';
import '../constants.dart';

class DBHelper {
  // api删除单条
  Future<bool> deleteBillItemByIdApi(String transactionId) async {
    try {
      print("api请求删除账单记录：");
      print(transactionId);

      // 发起 API 请求并等待响应
      Response response = await dio.delete(
        TRANSACTION_DELETE_URL,
        queryParameters: {
          "id": transactionId,
        },
      );

      print("api请求删除账单记录结果：");
      print(response.data);

      // 根据返回结果判断是否删除成功
      if (response.data['data'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      print("api请求删除账单记录错误：");
      print(error);
      return false;
    } finally {
      print('执行完毕');
    }
  }

  Future<CusDataResult> queryBillItemListApi(
      String? selectedMonth, String? category) async {
    String year = "";
    String month = "";
    if (selectedMonth != null) {
      var split = selectedMonth!.split("-");
      year = split[0];
      month = split[1];
    }

    Response response = await dio.get(TRANSACTION_LIST_URL,
        queryParameters: {"year": year, "month": month, "type": category});
    print("api请求交易列表结果：");
    print(response);
// 转换为 List<BillItem>，并过滤掉 number < 0 的项
    List<BillItem> billItemList = (response.data['data'] as List)
        .map<BillItem>((item) => BillItem.fromJson(item))
        .where((billItem) => billItem.number >= 0)
        .map((billItem) {
      billItem.itemType = 1;
      return billItem;
    }).toList();

    return CusDataResult(data: billItemList, total: billItemList.length);
  }

  // api获取账单最大日期和最小日期
  Future<SimplePeriodRange> queryDateRangeListApi() async {
    // 默认起止范围为当前
    var range = SimplePeriodRange(
      minDate: DateTime.now(),
      maxDate: DateTime.now(),
    );

    Response response = await dio.get(MONTH_LIST_URL);
    print("api请求月份列表结果：");
    print(response);
    if (response.statusCode == 200) {
      var data = response.data;
      print("api请求月份列表结果：");
      print(data);
      var listData = data["data"] as List;

      if (listData.isNotEmpty) {
        listData = listData.map((e) {
          if (RegExp(r'^\d{4}-\d{1,2}$').hasMatch(e)) {
            List<String> parts = e.split('-');
            String year = parts[0];
            String month = parts[1].padLeft(2, '0'); // 补全月份
            return DateTime.parse("$year-$month-01");
          }
          return DateTime.parse(e + "-01");
        }).toList();
        // 对日期排序
        listData.sort((a, b) => a.compareTo(b));
        range.minDate = listData.first;
        range.maxDate = listData.last;
      }
    }
    return range;
  }

  // api查询月度/年度统计数据
  Future<BillPeriodCount> queryBillCountListApi(String selectedMonth) async {
    var split = selectedMonth.split("-");
    Response response = await dio
        .get(STATS_URL, queryParameters: {"year": split[0], "month": split[1]});
    print("api请求月度/年度消费统计结果：");
    print(response.data);
    return BillPeriodCount.fromMap(response.data['data'], split);
  }

  /**
   * 查询所有账户(分类)
   * eg:"account": "Expenses:Eat:日常吃饭",
   */
  Future<Map<String, String>> queryAccountList() async {
    Map<String, String> accountsMap = {};
    Response response = await dio.get(CATEGORY_LIST_URL);
    print("api请求账户(分类)结果：");
    print(response.data);
    var listData = response.data["data"] as List;
    // 过滤不展示的account
    var filteredList = listData.where((e) {
      String? account = e['account'];
      return account != null &&
          account.isNotEmpty &&
          account != "\"\"" &&
          account != "CNY" &&
          account != "Assets:Account" &&
          account != "Equity:OpenBalance" &&
          account != "Income:Investment" &&
          account != "Income:Other" &&
          account != "Income:Salary";
    }).toList();

    for (var e in filteredList) {
      String account = e['account'];
      String accountView = account.split(":").last;
      accountsMap[accountView] = account;
    }
    return accountsMap;
  }

  /**
   * 保存账单记录
   */
  saveBillItemApi(SaveBillItem tempItem) {
    print("api请求保存账单记录：");
    print(tempItem.toJson());
    dio.post(TRANSACTION_SAVE_URL, data: jsonEncode(tempItem)).then((response) {
      print("api请求保存账单记录结果：");
      print(response.data);
    }).catchError((error) {
      print("api请求保存账单记录错误：");
      print(error);
    });
  }
}

final Dio dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
))
  ..httpClientAdapter = DefaultHttpClientAdapter()
  ..options.headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "ledgerId": ACCOUNT_ID
  };
