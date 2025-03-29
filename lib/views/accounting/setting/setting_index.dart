import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_account/common/utils/account_info_util.dart';

import '../../../common/constants.dart';

class SettingIndex extends StatefulWidget {
  const SettingIndex({super.key});

  @override
  State createState() => _SettingIndexState();
}

class _SettingIndexState extends State<SettingIndex> {

  final TextEditingController _urlController = TextEditingController();

  final TextEditingController _accountIdController = TextEditingController();
  String urlAddress ="";
  String accountId ="";
  @override
  void initState() {
    // TODO: implement initState
    // 初始化urlAddress和accountId的值
    initAccountInfo();
    super.initState();
  }

  Future<void> initAccountInfo() async {
    // 初始化urlAddress和accountId的值
    var url = await getAccountUrl();
    var id = await getAccountId();
    setState(() {
      urlAddress = url;
      accountId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();  // 返回上一个页面
          },
        ),
        title: Text('设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            _buildSettingsGroup(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup() {
    return SettingsGroup(
      items: [
        SettingsItem(
          onTap: () async {
            String? url = await _showUrlInputDialog(context);
            if (url != null && url.isNotEmpty) {
              setState(() {
                urlAddress = url;  // 更新subtitle为用户输入的地址
              });
            }
          },
          icons: Icons.link,
          iconStyle: IconStyle(),
          title: '账本访问地址',
          subtitle: urlAddress,
        ),

        SettingsItem(
          onTap: () async {
            String? id = await _showAccountIdInputDialog(context);
            if (id != null && id.isNotEmpty) {
              setState(() {
                accountId = id;  // 更新subtitle为用户输入的地址
              });
            }
          },
          icons: Icons.key,
          iconStyle: IconStyle(),
          title: '账本id',
          subtitle: accountId,
        ),
      ],
    );
  }
  Future<String?> _showUrlInputDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('输入URL地址'),
          content: TextField(
            controller: _urlController,
            decoration: InputDecoration(hintText: "请输入URL"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                saveAccountUrl(_urlController.text);
                Navigator.of(context).pop(_urlController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showAccountIdInputDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('输入账本id'),
          content: TextField(
            controller: _accountIdController,
            decoration: InputDecoration(hintText: "请输入账本id"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                saveAccountId(_accountIdController.text);
                Navigator.of(context).pop(_accountIdController.text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _urlController.dispose(); // 释放控制器
    super.dispose();
  }
}
