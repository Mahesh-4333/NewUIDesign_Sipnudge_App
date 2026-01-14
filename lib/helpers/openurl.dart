import 'package:url_launcher/url_launcher.dart';

class OpenUrlHelper {
  static Future<void> openTermsUrl() async {
    final Uri url = Uri.parse('https://sipnudge.com/policies/terms-of-service');

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }

  static Future<void> openprivacysUrl() async {
    final Uri url = Uri.parse('https://sipnudge.com/policies/privacy-policy');

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }
}
