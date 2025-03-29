import 'package:flutter/material.dart' hide CarouselController;
import 'package:intl/intl.dart'; // 使用intl库来格式化日期

class YearMonthPicker extends StatefulWidget {
  const YearMonthPicker({super.key});

  @override
  State createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<YearMonthPicker> {
  String _selectedYearMonth = DateFormat('yyyy-MM').format(DateTime.now());

  List<DropdownMenuItem<String>> _buildYearMonthItems() {
    List<DropdownMenuItem<String>> items = [];

    // 假设你想要显示当前年份的前一年到后一年，每个月都作为一个选项
    for (int year = DateTime.now().year - 1;
        year <= DateTime.now().year + 1;
        year++) {
      for (int month = 1; month <= 12; month++) {
        String yearMonth =
            DateFormat('yyyy-MM').format(DateTime(year, month, 1));
        items.add(
          DropdownMenuItem(
            value: yearMonth,
            child: Text(yearMonth),
          ),
        );
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedYearMonth,
      items: _buildYearMonthItems(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedYearMonth = newValue!;
          // 你可以在这里添加逻辑来处理选中的年月，比如解析为DateTime对象等
        });
      },
      hint: const Text('选择年月'),
    );
  }
}
