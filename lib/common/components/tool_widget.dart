// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:form_builder_file_picker/form_builder_file_picker.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../constants.dart';

// 绘制转圈圈
Widget buildLoader(bool isLoading) {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  } else {
    return Container();
  }
}

commonHintDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: TextStyle(fontSize: 12.sp)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

// 显示底部提示条(默认都是出错或者提示的)
void showSnackMessage(
  BuildContext context,
  String message, {
  Color? backgroundColor = Colors.red,
}) {
  var snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
    backgroundColor: backgroundColor,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

/// 构建文本生成的图片结果列表
/// 点击预览，长按下载
// buildNetworkImageViewGrid(
//   String style,
//   List<String> urls,
//   BuildContext context,
// ) {
//   return GridView.count(
//     crossAxisCount: 2,
//     shrinkWrap: true,
//     mainAxisSpacing: 5.sp,
//     crossAxisSpacing: 5.sp,
//     physics: const NeverScrollableScrollPhysics(),
//     children: buildImageList(style, urls, context),
//   );
// }

// 2024-06-27 在小米6中此放在上面imageViewGrid没问题，但Z60U就报错；因为无法调试，错误原因不知
// 所以在文生图历史记录中点击某个记录时，不使用上面那个，而使用这个
// buildImageList(String style, List<String> urls, BuildContext context) {
//   return List.generate(urls.length, (index) {
//     return GridTile(
//       child: GestureDetector(
//         // 单击预览
//         onTap: () {
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return Dialog(
//                 backgroundColor: Colors.transparent, // 设置背景透明
//                 child: PhotoView(
//                   imageProvider: NetworkImage(urls[index]),
//                   // 设置图片背景为透明
//                   backgroundDecoration: const BoxDecoration(
//                     color: Colors.transparent,
//                   ),
//                   // 可以旋转
//                   // enableRotation: true,
//                   // 缩放的最大最小限制
//                   minScale: PhotoViewComputedScale.contained * 0.8,
//                   maxScale: PhotoViewComputedScale.covered * 2,
//                   errorBuilder: (context, url, error) =>
//                       const Icon(Icons.error),
//                 ),
//               );
//             },
//           );
//         },
//         // 长按保存到相册
//         onLongPress: () async {
//           if (Platform.isAndroid) {
//             final deviceInfoPlugin = DeviceInfoPlugin();
//             final deviceInfo = await deviceInfoPlugin.androidInfo;
//             final sdkInt = deviceInfo.version.sdkInt;
//
//             // Android9对应sdk是28,<=28就不显示保存按钮
//             if (sdkInt > 28) {
//               // 点击预览或者下载
//               var response = await Dio().get(urls[index],
//                   options: Options(responseType: ResponseType.bytes));
//
//               print(response.data);
//
//               // 安卓9及以下好像无法保存
//               final result = await ImageGallerySaver.saveImage(
//                 Uint8List.fromList(response.data),
//                 quality: 100,
//                 name: "${style}_${DateTime.now().millisecondsSinceEpoch}",
//               );
//               if (result["isSuccess"] == true) {
//                 EasyLoading.showToast("图片已保存到相册！");
//               } else {
//                 EasyLoading.showToast("无法保存图片！");
//               }
//             } else {
//               EasyLoading.showToast("Android 9 及以下版本无法长按保存到相册！");
//             }
//           }
//         },
//         // 默认缓存展示
//         child: SizedBox(
//           height: 0.2.sw,
//           child: CachedNetworkImage(
//             imageUrl: urls[index],
//             fit: BoxFit.cover,
//             progressIndicatorBuilder: (context, url, downloadProgress) =>
//                 Center(
//               child: SizedBox(
//                 height: 50.sp,
//                 width: 50.sp,
//                 child: CircularProgressIndicator(
//                   value: downloadProgress.progress,
//                 ),
//               ),
//             ),
//             errorWidget: (context, url, error) => const Icon(Icons.error),
//           ),
//         ),
//       ),
//     );
//   }).toList();
// }

/// 构建图片预览，可点击放大
/// 注意限定传入的图片类型，要在这些条件之中
Widget buildImageView(
  dynamic image,
  BuildContext context, {
  // 是否是本地文件地址(暂时没使用到网络地址)
  bool? isFileUrl = false,
}) {
  // 如果没有图片数据，直接返回文提示
  if (image == null) {
    return const Center(
      child: Text(
        '请选择图片',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  print("显示的图片类型---${image.runtimeType == File}-${image.runtimeType} -$image");

  ImageProvider imageProvider;
  // 只有base64的字符串或者文件格式
  if (image.runtimeType == String && isFileUrl == false) {
    imageProvider = MemoryImage(base64Decode(image));
  }
  if (image.runtimeType == String && isFileUrl == true) {
    imageProvider = FileImage(File(image));
  } else {
    // 如果直接传文件，那就是文件
    imageProvider = FileImage(image);
  }

  return GridTile(
    child: GestureDetector(
      // 单击预览
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: PhotoView(
                imageProvider: imageProvider,
                // 设置图片背景为透明
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                // 可以旋转
                // enableRotation: true,
                // 缩放的最大最小限制
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                errorBuilder: (context, url, error) => const Icon(Icons.error),
              ),
            );
          },
        );
      },
      // 默认显示文件图片
      child: RepaintBoundary(
        child: Center(
          child: Image(image: imageProvider, fit: BoxFit.scaleDown),
        ),
      ),
    ),
  );
}

// 生成随机颜色
Color genRandomColor() =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

// 生成随机颜色带透明度
Color genRandomColorWithOpacity({double? opacity}) =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(opacity ?? math.Random().nextDouble());

// 指定长度的随机字符串
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
math.Random _rnd = math.Random();
String getRandomString(int length) {
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );
}

// 指定长度的范围的随机字符串(包含上面那个，最大最小同一个值即可)
String generateRandomString(int minLength, int maxLength) {
  int length = minLength + _rnd.nextInt(maxLength - minLength + 1);

  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );
}

// 异常弹窗
commonExceptionDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

///
/// form builder 库中文本栏位和下拉选择框组件的二次封装
///
// 构建表单的文本输入框
Widget cusFormBuilerTextField(String name,
    {String? initialValue,
    double? valueFontSize,
    int? maxLines,
    String? hintText, // 可不传提示语
    TextStyle? hintStyle,
    String? labelText, // 可不传栏位标签，在输入框前面有就行
    String? Function(Object?)? validator,
    bool? isOutline = false, // 输入框是否有线条
    bool isReadOnly = false, // 输入框是否有线条
    TextInputType? keyboardType,
    void Function(String?)? onChanged,
    List<TextInputFormatter>? inputFormatters}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.sp),
    child: FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      maxLines: maxLines,
      readOnly: isReadOnly,
      style: TextStyle(fontSize: valueFontSize),
      // 2023-12-04 没有传默认使用name，原本默认的.text会弹安全键盘，可能无法输入中文
      // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
      // 注意：如果有最大行超过1的话，默认启用多行的键盘类型
      enableSuggestions: true,
      keyboardType: keyboardType ??
          ((maxLines != null && maxLines > 1)
              ? TextInputType.multiline
              : TextInputType.text),

      decoration: _buildInputDecoration(
        isOutline,
        isReadOnly,
        labelText,
        hintText,
        hintStyle,
      ),
      validator: validator,
      onChanged: onChanged,
      // 输入的格式限制
      inputFormatters: inputFormatters,
    ),
  );
}

/// 构建下拉多选弹窗模块栏位(主要为了样式统一)
Widget buildModifyMultiSelectDialogField(
  BuildContext context, {
  required List<CusLabel> items,
  GlobalKey<FormFieldState<dynamic>>? key,
  List<dynamic> initialValue = const [],
  String? labelText,
  String? hintText,
  String? Function(List<dynamic>?)? validator,
  required void Function(List<dynamic>) onConfirm,
}) {
  // 把预设的基础活动选项列表转化为 MultiSelectDialogField 支持的列表
  final formattedItems = items
      .map<MultiSelectItem<CusLabel>>(
          (opt) => MultiSelectItem<CusLabel>(opt, opt.cnLabel))
      .toList();

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.sp),
    child: MultiSelectDialogField(
      key: key,
      items: formattedItems,
      // ？？？？ 好像是不带validator用了这个初始值就会报错
      initialValue: initialValue,
      title: Text(hintText ?? ''),
      // selectedColor: Colors.blue,
      decoration: BoxDecoration(
        // color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.all(Radius.circular(5.sp)),
        border: Border.all(
          width: 2.sp,
          color: Theme.of(context).disabledColor,
        ),
      ),
      // buttonIcon: const Icon(Icons.fitness_center, color: Colors.blue),
      buttonIcon: const Icon(Icons.restaurant_menu),
      buttonText: Text(
        labelText ?? "",
        style: TextStyle(
          // color: Colors.blue[800],
          fontSize: 12.sp,
        ),
      ),
      // searchable: true,
      validator: validator,
      onConfirm: onConfirm,
      cancelText: const Text("取消"),
      confirmText: const Text("确认"),
    ),
  );
}

// formbuilder 下拉框和文本输入框的样式等内容
InputDecoration _buildInputDecoration(
  bool? isOutline,
  bool isReadOnly,
  String? labelText,
  String? hintText,
  TextStyle? hintStyle,
) {
  final contentPadding = isOutline != null && isOutline
      ? EdgeInsets.symmetric(horizontal: 5.sp, vertical: 15.sp)
      : EdgeInsets.symmetric(horizontal: 5.sp, vertical: 5.sp);

  return InputDecoration(
    isDense: true,
    labelText: labelText,
    hintText: hintText,
    hintStyle: hintStyle,
    contentPadding: contentPadding,
    border: isOutline != null && isOutline
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          )
        : isReadOnly
            ? InputBorder.none
            : null,
    // 设置透明底色
    filled: true,
    fillColor: Colors.transparent,
  );
}

buildSmallChip(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return Chip(
    label: Text(labelText),
    backgroundColor: bgColor,
    labelStyle: TextStyle(fontSize: labelTextSize),
    labelPadding: EdgeInsets.zero,
    // 设置负数会报错，但好像看到有点效果呢
    // labelPadding: EdgeInsets.fromLTRB(0, -6.sp, 0, -6.sp),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

// 用一个按钮假装是一个标签，用来展示
buildSmallButtonTag(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return RawMaterialButton(
    onPressed: () {},
    constraints: const BoxConstraints(),
    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    fillColor: bgColor ?? Colors.grey[300],
    child: Text(
      labelText,
      style: TextStyle(fontSize: labelTextSize ?? 12.sp),
    ),
  );
}

// 一般当做标签用，比上面个还小
// 传入的字体最好不超过10
buildTinyButtonTag(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return SizedBox(
    // 传入大于12的字体，修正为12；不传则默认12
    height: ((labelTextSize != null && labelTextSize > 10.sp)
            ? 10.sp
            : labelTextSize ?? 10.sp) +
        10.sp,
    child: RawMaterialButton(
      onPressed: () {},
      constraints: const BoxConstraints(),
      padding: EdgeInsets.fromLTRB(4.sp, 2.sp, 4.sp, 2.sp),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp),
      ),
      fillColor: bgColor ?? Colors.grey[300],
      child: Text(
        labelText,
        style: TextStyle(
          // 传入大于10的字体，修正为10；不传则默认10
          fontSize: (labelTextSize != null && labelTextSize > 10.sp)
              ? 10.sp
              : labelTextSize ?? 10.sp,
        ),
      ),
    ),
  );
}

// 带有横线滚动条的datatable
buildDataTableWithHorizontalScrollbar({
  required ScrollController scrollController,
  required List<DataColumn> columns,
  required List<DataRow> rows,
}) {
  return Scrollbar(
    thickness: 5,
    // 设置交互模式后，滚动条和手势滚动方向才一致
    interactive: true,
    radius: Radius.circular(5.sp),
    // 不设置这个，滚动条默认不显示，在滚动时才显示
    thumbVisibility: true,
    // trackVisibility: true,
    // 滚动条默认在右边，要改在左边就配合Transform进行修改(此例没必要)
    // 刻意预留一点空间给滚动条
    controller: scrollController,
    child: SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: DataTable(
        // dataRowHeight: 10.sp,
        dataRowMinHeight: 60.sp, // 设置行高范围
        dataRowMaxHeight: 100.sp,
        headingRowHeight: 25, // 设置表头行高
        horizontalMargin: 10, // 设置水平边距
        columnSpacing: 20.sp, // 设置列间距
        columns: columns,
        rows: rows,
      ),
    ),
  );
}

/// ----
///
// 图片轮播
buildImageCarouselSlider(
  List<String> imageList, {
  bool isNoImage = false, // 是否不显示图片，默认就算无图片也显示占位图片
  int type = 3, // 轮播图是否可以点击预览图片，预设为3(具体类型参看下方实现方法)
}) {
  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true, // 自动播放
      enlargeCenterPage: true, // 居中图片放大
      aspectRatio: 16 / 9, // 图片宽高比
      viewportFraction: 1, // 图片占屏幕宽度的比例
      // 只有一张图片时不滚动
      enableInfiniteScroll: imageList.length > 1,
    ),
    // 除非指定不显示图片，否则没有图片也显示一张占位图片
    items: isNoImage
        ? null
        : imageList.isEmpty
            ? [Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown)]
            : imageList.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return _buildImageCarouselSliderType(
                      type,
                      context,
                      imageUrl,
                      imageList,
                    );
                  },
                );
              }).toList(),
  );
}

// 2024-03-12 根据图片地址前缀来区分是否是网络图片，使用不同的方式展示图片
Widget buildNetworkOrFileImage(String imageUrl, {BoxFit? fit}) {
  if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      // progressIndicatorBuilder: (context, url, progress) => Center(
      //   child: CircularProgressIndicator(
      //     value: progress.progress,
      //   ),
      // ),

      /// placeholder 和 progressIndicatorBuilder 只能2选1
      // placeholder: (context, url) => Center(
      //   child: SizedBox(
      //     width: 50.sp,
      //     height: 50.sp,
      //     child: const CircularProgressIndicator(),
      //   ),
      // ),
      errorWidget: (context, url, error) => Center(
        child: Icon(Icons.error, size: 36.sp),
      ),
    );

// 2024-03-29 这样每次都会重新请求图片，网络图片都不小的，流量顶不住。用上面的
    // return Image.network(
    //   imageUrl,
    //   errorBuilder: (context, error, stackTrace) {
    //     return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
    //   },
    //   fit: fit,
    // );
  } else {
    return Image.file(
      File(imageUrl),
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
      },
      fit: fit,
    );
  }
}

// 2024-03-12 根据图片地址前缀来区分是否是网络图片
bool isNetworkImageUrl(String imageUrl) {
  return (imageUrl.startsWith('http') || imageUrl.startsWith('https'));
}

ImageProvider getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
    return CachedNetworkImageProvider(imageUrl);
    // return NetworkImage(imageUrl);
  } else {
    return FileImage(File(imageUrl));
  }
}

/// 2023-12-26
/// 现在设计轮播图3种形态:
///   1 点击某张图片，可以弹窗显示该图片并进行缩放预览
///   2 点击某张图片，可以跳转新页面对该图片并进行缩放预览
///   3 点击某张图片，可以弹窗对该图片所在整个列表进行缩放预览(默认选项)
///   default 单纯的轮播展示,点击图片无动作
_buildImageCarouselSliderType(
  int type,
  BuildContext context,
  String imageUrl,
  List<String> imageList,
) {
  buildCommonImageWidget(Function() onTap) =>
      GestureDetector(onTap: onTap, child: buildNetworkOrFileImage(imageUrl));

  switch (type) {
    // 这个直接弹窗显示图片可以缩放
    case 1:
      return buildCommonImageWidget(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: PhotoView(
                imageProvider: getImageProvider(imageUrl),
                // 设置图片背景为透明
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                // 可以旋转
                enableRotation: true,
                // 缩放的最大最小限制
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                errorBuilder: (context, url, error) => const Icon(Icons.error),
              ),
            );
          },
        );
      });
    case 2:
      return buildCommonImageWidget(() {
        // 这个是跳转到新的页面去
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoView(
              imageProvider: getImageProvider(imageUrl),
              enableRotation: true,
              errorBuilder: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        );
      });
    case 3:
      return buildCommonImageWidget(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            // 这个弹窗默认是无法全屏的，上下左右会留点空，点击这些空隙可以关闭弹窗
            return Dialog(
              backgroundColor: Colors.transparent,
              child: PhotoViewGallery.builder(
                itemCount: imageList.length,
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: getImageProvider(imageList[index]),
                    errorBuilder: (context, url, error) =>
                        const Icon(Icons.error),
                  );
                },
                // enableRotation: true,
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                loadingBuilder: (BuildContext context, ImageChunkEvent? event) {
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            );
          },
        );
      });
    default:
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: const BoxDecoration(color: Colors.grey),
        child: buildNetworkOrFileImage(imageUrl),
      );
  }
}

// 将图片字符串，转为文件多选框中支持的图片平台文件
// formbuilder的图片地址拼接的字符串，要转回平台文件列表
// List<PlatformFile> convertStringToPlatformFiles(String imagesString) {
//   List<String> imageUrls = imagesString.split(','); // 拆分字符串
//   // 如果本身就是空字符串，直接返回空平台文件数组
//   if (imagesString.trim().isEmpty || imageUrls.isEmpty) {
//     return [];
//   }
//
//   List<PlatformFile> platformFiles = []; // 存储 PlatformFile 对象的列表
//
//   for (var imageUrl in imageUrls) {
//     PlatformFile file = PlatformFile(
//       name: imageUrl,
//       path: imageUrl,
//       size: 32, // 假设图片地址即为文件路径
//     );
//     platformFiles.add(file);
//   }
//
//   return platformFiles;
// }

/// 显示本地路径图片，点击可弹窗显示并缩放
buildClickImageDialog(BuildContext context, String imageUrl) {
  return GestureDetector(
    onTap: () {
      // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
      FocusScope.of(context).unfocus();
      // 这个直接弹窗显示图片可以缩放
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent, // 设置背景透明
            child: PhotoView(
              imageProvider: FileImage(File(imageUrl)),
              // 设置图片背景为透明
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              // 可以旋转
              // enableRotation: true,
              // 缩放的最大最小限制
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 2,
              errorBuilder: (context, url, error) => const Icon(Icons.error),
            ),
          );
        },
      );
    },
    child: Padding(
      padding: EdgeInsets.all(20.sp),
      child: SizedBox(
        width: 0.8.sw,
        child: buildNetworkOrFileImage(imageUrl),
      ),
    ),
  );
}
