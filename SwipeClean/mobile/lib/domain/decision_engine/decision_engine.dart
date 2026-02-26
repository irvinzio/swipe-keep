import 'package:photo_manager/photo_manager.dart';

enum SwipeDecision { keep, delete }

abstract class DecisionEngine {
  Future<SwipeDecision> decide(AssetEntity asset);
}
