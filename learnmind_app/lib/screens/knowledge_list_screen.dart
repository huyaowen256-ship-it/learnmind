import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/knowledge_provider.dart';
import '../services/api_service.dart';
import '../models/knowledge_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import 'knowledge_detail_screen.dart';
import 'add_card_screen.dart';

class KnowledgeListScreen extends ConsumerStatefulWidget {
  const KnowledgeListScreen({super.key});

  @override
  ConsumerState<KnowledgeListScreen> createState() => _KnowledgeListScreenState();
}

class _KnowledgeListScreenState extends ConsumerState<KnowledgeListScreen> {
  final _searchController = TextEditingController();
  final _allTags = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(filteredCardsProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCardScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索标题或内容...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.invalidate(filteredCardsProvider);
                      })
                    : null,
              ),
              onSubmitted: (v) {
                ref.read(searchQueryProvider.notifier).state = v;
                ref.invalidate(filteredCardsProvider);
              },
            ),
          ),

          // 标签筛选
          cards.when(
            data: (cardList) {
              _allTags.clear();
              for (var c in cardList) {
                _allTags.addAll(c.tags);
              }
              if (_allTags.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('全部'),
                        selected: selectedTag == null,
                        onSelected: (_) {
                          ref.read(selectedTagProvider.notifier).state = null;
                          ref.invalidate(filteredCardsProvider);
                        },
                      ),
                    ),
                    ..._allTags.map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tag),
                            selected: selectedTag == tag,
                            onSelected: (_) {
                              ref.read(selectedTagProvider.notifier).state = tag;
                              ref.invalidate(filteredCardsProvider);
                            },
                          ),
                        )),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),

          // 卡片列表
          Expanded(
            child: cards.when(
              data: (cardList) {
                if (cardList.isEmpty) {
                  return EmptyStateWidget(
                    type: EmptyStateType.noCards,
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCardScreen())),
                    actionLabel: '添加第一张卡片',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(filteredCardsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: cardList.length,
                    itemBuilder: (context, index) {
                      final card = cardList[index];
                      return _KnowledgeCardItem(card: card);
                    },
                  ),
                );
              },
              loading: () => const ShimmerCardList(),
              error: (e, _) => EmptyStateWidget(
                type: EmptyStateType.error,
                onAction: () => ref.invalidate(filteredCardsProvider),
                actionLabel: '重试',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeCardItem extends ConsumerWidget {
  final KnowledgeCard card;
  const _KnowledgeCardItem({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('删除 "${card.title}"？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(knowledgeCardsNotifierProvider.notifier).deleteCard(card.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KnowledgeDetailScreen(card: card))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'card-title-${card.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(card.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                    ),
                    _StatusBadge(label: card.reviewStatusLabel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  card.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (card.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: card.tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(t, style: TextStyle(color: AppColors.primary, fontSize: 11)),
                        )).toList(),
                  ),
                ],
                const SizedBox(height: 6),
                Text(card.createdAtFormatted, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (label == '新卡片') {
      color = AppColors.statusNew;
    } else if (label == '待复习') {
      color = AppColors.statusReview;
    } else {
      color = AppColors.statusMastered;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
