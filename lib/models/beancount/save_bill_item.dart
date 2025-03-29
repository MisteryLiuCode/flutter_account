class SaveBillItem {
  final String? id;
  final String payee;
  final String date;
  final String desc;
  final List<Entries> entries;

  SaveBillItem({
    this.id,
    required this.payee,
    required this.date,
    required this.desc,
    required this.entries,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payee': payee,
      'date': date,
      'desc': desc,
      'entries': entries.map((e) => e.toJson()).toList(), // 序列化 List<Entries>
    };
  }
}

class Entries{
  final String account;
  final double number;
  final String currency;
  Entries({
    required this.account,
    required this.number,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'account': account,
      'number': number,
      'currency': currency,
    };
  }

}