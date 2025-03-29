// 时间格式化字符串
const constDatetimeFormat = "yyyy-MM-dd HH:mm:ss";
const constDateFormat = "yyyy-MM-dd";
const constMonthFormat = "yyyy-MM";
const constTimeFormat = "HH:mm:ss";
// 未知的时间字符串
const unknownDateTimeString = '1970-01-01 00:00:00';
const unknownDateString = '1970-01-01';

const String placeholderImageUrl = 'assets/images/no_image.jpg';

late String ACCOUNT_URL;
late String ACCOUNT_ID;

// 交易列表
late String TRANSACTION_LIST_URL = "${ACCOUNT_URL}/api/auth/transaction";
// 月份列表
late String MONTH_LIST_URL = "${ACCOUNT_URL}/api/auth/stats/months";
// 统计
late String STATS_URL = "${ACCOUNT_URL}/api/auth/stats/total";
// 账户分类
late String CATEGORY_LIST_URL = "${ACCOUNT_URL}/api/auth/account/all";
// 保存账单
late String TRANSACTION_SAVE_URL = "${ACCOUNT_URL}/api/auth/transaction";
// 删除账单
late String TRANSACTION_DELETE_URL = "${ACCOUNT_URL}/api/auth/transaction";

// 数据库分页查询数据的时候，还需要带上一个该表的总数量
// 还可以按需补入其他属性
class CusDataResult {
  List<dynamic> data;
  int total;

  CusDataResult({
    required this.data,
    required this.total,
  });
}

// 自定义标签，常用来存英文、中文、全小写带下划线的英文等。
class CusLabel {
  final String enLabel;
  final String cnLabel;
  final dynamic value;

  CusLabel({
    required this.enLabel,
    required this.cnLabel,
    required this.value,
  });
}
