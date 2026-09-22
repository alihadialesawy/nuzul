import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/community_post_model.dart';
import '../../../data/repositories/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

final communityFeedProvider =
FutureProvider.autoDispose<List<CommunityPostModel>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  final result = await repo.fetchFeed();
  return result.when(
    success: (posts) => posts,
    failure: (message) {
      // ignore: avoid_print
      print('=== COMMUNITY FEED ERROR: $message ===');
      throw Exception(message);
    },
  );
});

final communityFeedByDestinationProvider = FutureProvider.autoDispose
    .family<List<CommunityPostModel>, String>((ref, destinationCity) async {
  final repo = ref.watch(communityRepositoryProvider);
  final result = await repo.fetchFeed(destinationCity: destinationCity);
  return result.when(
    success: (posts) => posts,
    failure: (message) => throw Exception(message),
  );
});