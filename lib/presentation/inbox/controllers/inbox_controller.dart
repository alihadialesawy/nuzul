import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/inbox_item_model.dart';
import '../../../data/repositories/inbox_repository.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository();
});

final inboxItemsProvider = FutureProvider.autoDispose<List<InboxItemModel>>((ref) async {
  final repo = ref.watch(inboxRepositoryProvider);
  final result = await repo.fetchInboxItems();
  return result.when(
    success: (items) => items,
    failure: (message) => throw Exception(message),
  );
});