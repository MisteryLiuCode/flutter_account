// ignore_for_file: avoid_print

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../common/constants.dart';

/// 2024-05-22
/// brief_accounting 数据库目前就就1个主要的基础表
///   后续可能会根据报表查询sql得到的VO，再说
///   如果每笔支出还有非常多的细节，像微信支付宝账单那种，这里只能预留有个支出收入详情表了

/// 支出和收入条目
class BillItem {
  String id; // 用uuid生成
  int itemType; // 0 收入；1 支出
  String date; // 日期，yyyy-MM-DD
  String? account; // 最简单的分类
  String item; // 条目
  double number; // 数值
  String? gmtModified; // 异动时间
  /// 扩展的几个栏位，懒得加VO了
  String? month;
  double? expendTotal;
  double? incomeTotal;

  BillItem({
    required this.id,
    required this.itemType,
    required this.date,
    this.account,
    required this.item,
    required this.number,
    this.gmtModified,
    this.month,
    this.expendTotal,
    this.incomeTotal,
  });
  // 无参构造
  BillItem.empty()
      : id = const Uuid().v1(),
        itemType = 1,
        date = DateTime.now().toString(),
        account = '',
        item = '',
        number = 0.0,
        gmtModified = '',
        month = '',
        expendTotal = 0.0,
        incomeTotal = 0.0;

  Map<String, dynamic> toMap() {
    return {
      'bill_item_id': id,
      'item_type': itemType,
      'date': date,
      'category': account,
      'item': item,
      'value': number,
      'gmt_modified': gmtModified,
    };
  }

  // 主要是账单条目表单初始化值得时候，需要转类型
  Map<String, dynamic> toStringMap() {
    return {
      'bill_item_id': id,
      'item_type': itemType == 0 ? '收入' : '支出',
      'date': DateTime.tryParse(date) ?? DateTime.now(),
      'category': account,
      'item': item,
      'value': number.toStringAsFixed(2),
      'gmt_modified': gmtModified,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['bill_item_id'] != null
          ? map['bill_item_id'].toString()
          : const Uuid().v1(),
      itemType: map['item_type'] as int,
      date: map['date'] as String,
      account: map['category'] as String?,
      item: map['item'] as String,
      number: map['value'] as double,
      gmtModified: map['gmt_modified'] as String?,
      month: map['month'] as String?,
      expendTotal: map['expend_total'] as double?,
      incomeTotal: map['income_total'] as double?,
    );
  }

  // 从 JSON 映射中创建 User 实例的工厂方法
  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] != null
          ? json['id'].toString()
          : const Uuid().v1(),
      itemType: json['item_type'] != null
          ? json['item_type'] as int
          : 1,
      date: json['date'] as String,
      account: json['account'] as String?,
      item: json['desc'],
      number: json['number'] != null
          ? double.parse(json['number'])
          : 0.00,
      gmtModified: json['gmt_modified'] ??
          '',
        // DateFormat(constDatetimeFormat).format(DateTime.now())
    );
  }

  // 将实例转换为 JSON 映射的方法（可选）
  Map<String, dynamic> toJson() {
    return {
      'bill_item_id': id,
      'itemType': itemType,
      'date': date,
      'category': account,
      'item': item,
      'value': number,
      'gmt_modified': gmtModified,
    };
  }

  @override
  String toString() {
    return '''
    BillItem{
      billItemId: $id, itemType: $itemType, date: $date, category: $account, 
      item: $item, value: $number, gmtModified: $gmtModified,
      month: $month, expendTotal: $expendTotal, incomeTotal: $incomeTotal,
    }
    ''';
  }
}

// 一些VO
class BillGroup {
  String startDateOfYear;
  String startDateOfMonth;
  String startDateOfDay;
  double totalYear;
  double totalMonth;
  double totalDay;

  BillGroup({
    this.startDateOfYear = "",
    this.startDateOfMonth = "",
    this.startDateOfDay = "",
    this.totalYear = 0.0,
    this.totalMonth = 0.0,
    this.totalDay = 0.0,
  });

  void addBillItem(BillItem item) {
    String itemDate = item.date;

    // 如果这是新的一天，重置日累计值
    if (itemDate != startDateOfDay) {
      startDateOfDay = itemDate;
      totalDay = item.number;
    } else {
      totalDay += item.number;
    }

    // 如果这是新的一月，重置月累计值
    if (itemDate.substring(0, 7) != (startDateOfMonth)) {
      startDateOfMonth = itemDate.substring(0, 7);
      totalMonth = totalDay; // 新的月累计值从当日的累计值开始
    } else {
      totalMonth += item.number;
    }

    // 如果这是新的一年，重置年累计值
    if (itemDate.substring(0, 4) != startDateOfYear) {
      startDateOfYear = itemDate.substring(0, 4);
      totalYear = totalMonth; // 新的年累计值从当月的累计值开始
    } else {
      totalYear += item.number;
    }
  }
}

/// 月度年度统计
class BillPeriodCount {
  String period;
  double expendTotalValue;
  double incomeTotalValue;
  double ratio;

  BillPeriodCount({
    required this.period,
    required this.expendTotalValue,
    required this.incomeTotalValue,
    required this.ratio,
  });

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'expend_total_value': expendTotalValue,
      'income_total_value': incomeTotalValue,
      'ratio': ratio,
    };
  }

  factory BillPeriodCount.fromMap(Map<String, dynamic> map,var split) {
    return BillPeriodCount(
      // period: map['period'] != null ? map['period'] : 'period空',
      period: split[0] + '-' + split[1],
      expendTotalValue: double.parse(map['Expenses']),
      incomeTotalValue: map['Income'] != null
          ? double.parse(map['Income'])
          : 0.00,
      ratio: map['ratio'] != null ? map['ratio'] as double : 0,
    );
  }

  @override
  String toString() {
    return '''
    BillPeriodCount{period: $period, expendTotalValue: $expendTotalValue, incomeTotalValue: $incomeTotalValue, ratio: $ratio;}
    ''';
  }
}

/// 简单的日期范围
class SimplePeriodRange {
  DateTime minDate;
  DateTime maxDate;

  SimplePeriodRange({
    required this.minDate,
    required this.maxDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'min_date': minDate,
      'max_date': maxDate,
    };
  }

  factory SimplePeriodRange.fromMap(Map<String, dynamic> map) {
    return SimplePeriodRange(
      minDate: DateTime.tryParse(map['min_date']) ?? DateTime.now(),
      maxDate: DateTime.tryParse(map['max_date']) ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return '''
    SimplePeriodRange{minDate: $minDate, maxDate: $maxDate}
    ''';
  }
}

/// ---------------------- 下面的暂时简化为上面，如果后续真的记录非常多，再考虑拆分为支出和收入两部分

/// 支出
class Expend {
  String expendId; // 用uuid生成
  String date; // 日期，yyyy-MM-DD
  String? category; // 最简单的分类
  String item; // 条目
  double value; // 数值

  Expend({
    required this.expendId,
    required this.date,
    this.category,
    required this.item,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'expend_id': expendId,
      'date': date,
      'category': category,
      'item': item,
      'value': value,
    };
  }

  factory Expend.fromMap(Map<String, dynamic> map) {
    return Expend(
      expendId: map['expend_id'] as String,
      date: map['date'] as String,
      category: map['category'] as String?,
      item: map['item'] as String,
      value: map['value'] as double,
    );
  }

  @override
  String toString() {
    return '''
    Expend{
      expendId: $expendId, date: $date, category:$category, item: $item, value: $value, 
    }
    ''';
  }
}

/// 支出
class Income {
  String incomeId; // 用uuid生成
  String date; // 日期，yyyy-MM-DD
  String? category; // 最简单的分类
  String item; // 条目
  double value; // 数值

  Income({
    required this.incomeId,
    required this.date,
    this.category,
    required this.item,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'income_id': incomeId,
      'date': date,
      'category': category,
      'item': item,
      'value': value,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      incomeId: map['income_id'] as String,
      date: map['date'] as String,
      category: map['category'] as String?,
      item: map['item'] as String,
      value: map['value'] as double,
    );
  }

  @override
  String toString() {
    return '''
    Expend{
      incomeId: $incomeId, date: $date, category:$category, item: $item, value: $value, 
    }
    ''';
  }
}
