import 'package:flutter/services.dart';

final class FriendShareService {
  const FriendShareService({
    this.channel = const MethodChannel('in.sanskar.chessmaster/actions'),
  });

  final MethodChannel channel;

  Future<void> shareTeamCode(String text) {
    return channel.invokeMethod<void>('shareText', <String, Object?>{
      'text': text,
    });
  }
}
