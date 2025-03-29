import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomSheetOptionPicker extends StatefulWidget {
  final List<String> options;
  final ValueChanged<String?> onConfirm;

  const BottomSheetOptionPicker({
    super.key,
    required this.options,
    required this.onConfirm,
  });

  @override
  State createState() => _BottomSheetOptionPickerState();
}

class _BottomSheetOptionPickerState extends State<BottomSheetOptionPicker> {
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0.6.sh,
      child: Column(
        children: [
          Container(
            height: 0.1.sh,
            color: Colors.amber,
            child: const Text("选择分类"),
          ),
          Container(
            height: 0.4.sh,
            color: Colors.lightBlueAccent[50],
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 一行多个Container
                  Wrap(
                    spacing: 8.0, // 子元素之间的间距
                    runSpacing: 4.0, // 子元素行之间的间距
                    children: widget.options.map((option) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedOption = option;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: _selectedOption == option
                                ? Colors.lightBlue
                                : null,
                          ),
                          child: Text(
                            option,
                            // style: TextStyle(
                            //   color: _selectedOption == option
                            //       ? Colors.black
                            //       : null,
                            // ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  /// 一行多个listtile
                  // Wrap(
                  //   spacing: 8.0, // 子元素之间的间距
                  //   runSpacing: 4.0, // 子元素行之间的间距
                  //   children: widget.options.map((option) {
                  //     bool isSelected = option == _selectedOption;
                  //     return SizedBox(
                  //       width: 0.2.sw,
                  //       child: ListTile(
                  //         title: Text(option),
                  //         selected: isSelected,
                  //         tileColor: isSelected
                  //             ? Colors.black.withOpacity(0.5)
                  //             : null, // 选中时改变颜色
                  //         onTap: () {
                  //           setState(() {
                  //             _selectedOption = option;
                  //           });
                  //         },
                  //       ),
                  //     );
                  //   }).toList(),
                  // ),

                  /// 一行一个listtile
                  // ...widget.options.map((option) {
                  //   bool isSelected = option == _selectedOption;
                  //   return ListTile(
                  //     title: Text(option),
                  //     selected: isSelected,
                  //     onTap: () {
                  //       setState(() {
                  //         _selectedOption = option;
                  //       });
                  //     },
                  //   );
                  // }),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(0.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        widget.onConfirm(null);
                      },
                      child: const Text('取消'),
                    ),
                    SizedBox(width: 10.sp),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedOption != null) {
                          widget.onConfirm(_selectedOption!);
                        }
                      },
                      child: const Text('确定'),
                    ),
                    SizedBox(width: 10.sp),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
