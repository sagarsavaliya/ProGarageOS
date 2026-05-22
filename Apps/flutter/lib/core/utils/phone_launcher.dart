import 'package:url_launcher/url_launcher.dart';

/// Opens the device phone dialer for [phone] (any format accepted).
Future<void> launchPhoneDialer(String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: digits);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
