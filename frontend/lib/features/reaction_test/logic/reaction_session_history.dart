import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reaction_session_record.dart';

final reactionSessionHistoryProvider =
    StateNotifierProvider<
      ReactionSessionHistoryNotifier,
      List<ReactionSessionRecord>
    >((ref) => ReactionSessionHistoryNotifier());

final class ReactionSessionHistoryNotifier
    extends StateNotifier<List<ReactionSessionRecord>> {
  ReactionSessionHistoryNotifier() : super(const []);

  void add(ReactionSessionRecord entry) {
    state = [entry, ...state].take(50).toList(growable: false);
  }
}
