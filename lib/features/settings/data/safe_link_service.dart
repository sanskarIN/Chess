import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

final class SafeLinkService {
  const SafeLinkService();

  Future<bool> openOrCopy(Uri uri) async {
    if (!_allowed(uri)) {
      return false;
    }
    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    return false;
  }

  bool _allowed(Uri uri) {
    return uri.scheme == 'https' || uri.scheme == 'mailto';
  }
}
