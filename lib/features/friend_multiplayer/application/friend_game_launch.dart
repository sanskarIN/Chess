import '../../chess/application/game_setup.dart';
import 'friend_match_controller.dart';

final class FriendGameLaunch {
  const FriendGameLaunch({required this.setup, required this.controller});

  final GameSetup setup;
  final FriendMatchController controller;
}
