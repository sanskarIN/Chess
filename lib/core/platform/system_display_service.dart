import 'package:flutter/services.dart';

final class SystemDisplayService {
  const SystemDisplayService();

  static const MethodChannel _channel = MethodChannel(
    'in.sanskar.chessmaster/actions',
  );

  Future<void> setKeepScreenOn(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', <String, Object?>{
        'enabled': enabled,
      });
    } on MissingPluginException {
      // Non-Android and widget-test hosts do not expose the Android window.
    } on PlatformException {
      // Display preferences must never prevent a game from opening.
    }
  }
}
