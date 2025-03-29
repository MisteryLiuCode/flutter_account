import 'package:shared_preferences/shared_preferences.dart';

const accountUrlKey = 'account_url';
const accountIdKey = 'account_id';

Future<void> saveAccountUrl(String accountUrl) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(accountUrlKey, accountUrl);
}

Future<void> saveAccountId(String accountId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(accountIdKey, accountId);
}

Future<String> getAccountUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(accountUrlKey)?? "";
}

Future<String> getAccountId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(accountIdKey)?? "";
}
