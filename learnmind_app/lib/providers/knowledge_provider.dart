import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/knowledge_card.dart';
import '../services/api_service.dart';

// ── 知识卡片列表 ──────────────────────────────────────────

final knowledgeCardsProvider =
    FutureProvider.family<List<KnowledgeCard>, Map<String, String?>?>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  return api.getKnowledgeCards(q: params?['q'], tag: params?['tag']);
});

final knowledgeCardsNotifierProvider =
    StateNotifierProvider<KnowledgeCardsNotifier, AsyncValue<List<KnowledgeCard>>>((ref) {
  return KnowledgeCardsNotifier(ref);
});

class KnowledgeCardsNotifier extends StateNotifier<AsyncValue<List<KnowledgeCard>>> {
  final Ref _ref;

  KnowledgeCardsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? q, String? tag}) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiServiceProvider);
      final cards = await api.getKnowledgeCards(q: q, tag: tag);
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createCard(String title, String content, List<String> tags) async {
    final api = _ref.read(apiServiceProvider);
    final newCard = await api.createCard(KnowledgeCard(
      id: '',
      title: title,
      content: content,
      tags: tags,
      createdAt: '',
      updatedAt: '',
      sm2Data: SM2Data(),
    ));

    state.whenData((cards) {
      state = AsyncValue.data([newCard, ...cards]);
    });
  }

  Future<void> deleteCard(String id) async {
    final api = _ref.read(apiServiceProvider);
    await api.deleteCard(id);
    _ref.invalidate(filteredCardsProvider);
    _ref.invalidate(todayReviewProvider);
    state.whenData((cards) {
      state = AsyncValue.data(cards.where((c) => c.id != id).toList());
    });
  }

  Future<void> refresh() async {
    await load();
  }
}

// ── 今日复习 ──────────────────────────────────────────────

final todayReviewProvider = FutureProvider<ReviewDashboard>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getTodayReviews();
});

// ── 学习统计 ──────────────────────────────────────────────

final statsProvider = FutureProvider<Stats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getStats();
});

// ── 搜索状态 ──────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedTagProvider = StateProvider<String?>((ref) => null);

// ── 筛选后的卡片列表 ──────────────────────────────────────

final filteredCardsProvider = FutureProvider<List<KnowledgeCard>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final tag = ref.watch(selectedTagProvider);
  final api = ref.watch(apiServiceProvider);
  return api.getKnowledgeCards(q: query.isEmpty ? null : query, tag: tag);
});
