import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/knowledge_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import 'knowledge_detail_screen.dart';
import 'add_card_screen.dart';
import 'review_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final todayReview = ref.watch(todayReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LearnMind')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsProvider);
          ref.invalidate(todayReviewProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 欢迎语
            Text(
              '欢迎回来 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '每天进步一点点，积小流成江海',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // 今日复习卡片
            todayReview.when(
              data: (data) => _ReviewCard(count: data.count),
              loading: () => const ShimmerStatCard(),
              error: (_, __) => _ErrorCard(onRetry: () => ref.invalidate(todayReviewProvider)),
            ),
            const SizedBox(height: 16),

            // 统计卡片
            stats.when(
              data: (s) => _StatsGrid(stats: s),
              loading: () => _ShimmerStatsGrid(),
              error: (_, __) => _ErrorCard(onRetry: () => ref.invalidate(statsProvider)),
            ),
            const SizedBox(height: 24),

            // 快捷操作
            Text(
              '快捷操作',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle_outline,
                    label: '添加知识',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCardScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.search,
                    label: '搜索',
                    color: AppColors.accent,
                    onTap: () => DefaultTabController.of(context).animateTo(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 最新知识卡片
            _RecentCards(),
          ],
        ),
      ),
    );
  }
}

class _ShimmerStatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final bd = isDark ? AppColors.darkDivider : AppColors.divider;
    return Row(
      children: [
        Expanded(child: _ShimmerStatTile(bg: bg, bd: bd)),
        const SizedBox(width: 12),
        Expanded(child: _ShimmerStatTile(bg: bg, bd: bd)),
        const SizedBox(width: 12),
        Expanded(child: _ShimmerStatTile(bg: bg, bd: bd)),
      ],
    );
  }
}

class _ShimmerStatTile extends StatelessWidget {
  final Color bg, bd;
  const _ShimmerStatTile({required this.bg, required this.bd});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bd),
      ),
      child: Column(
        children: [
          ShimmerLoading(width: 22, height: 22, borderRadius: 6),
          const SizedBox(height: 8),
          ShimmerLoading(width: 30, height: 20, borderRadius: 6),
          const SizedBox(height: 2),
          ShimmerLoading(width: 50, height: 11, borderRadius: 4),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int count;
  final int dueCount;
  const _ReviewCard({required this.count, required this.dueCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: count > 0 ? [AppColors.primary, AppColors.primaryLight] : [Colors.grey.shade400, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.schedule, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count > 0 ? '今日待复习' : '今日已完成',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  count > 0 ? '$count 张卡片' : '太棒了！',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (count > 0) Text('点击开始复习', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          if (count > 0)
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ReviewStartPage())),
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _ReviewStartPage extends ConsumerWidget {
  const _ReviewStartPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('开始复习')),
      body: const Center(child: Text('复习流程页面（后续完善）')),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Stats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(label: '知识库', value: '${stats.totalCards}', icon: Icons.book, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _StatTile(label: '今日待复习', value: '${stats.dueToday}', icon: Icons.schedule, color: AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(child: _StatTile(label: '本周新增', value: '${stats.thisWeekNew}', icon: Icons.add_circle, color: AppColors.accent)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RecentCards extends ConsumerWidget {
  const _RecentCards();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(filteredCardsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近添加', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        cards.when(
          data: (list) {
            if (list.isEmpty) return Container(padding: const EdgeInsets.all(24), child: Center(child: Text('暂无知识卡片，点击上方添加', style: TextStyle(color: AppColors.textSecondary))));
            return Column(
              children: list.take(3).map((card) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(card.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(card.reviewStatusLabel, style: TextStyle(color: _statusColor(card.reviewStatusLabel), fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KnowledgeDetailScreen(card: card))),
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('加载失败')),
        ),
      ],
    );
  }

  Color _statusColor(String label) {
    if (label == '新卡片') return AppColors.statusNew;
    if (label == '待复习') return AppColors.statusReview;
    return AppColors.statusMastered;
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(height: 100, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)), child: const Center(child: CircularProgressIndicator()));
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.error_outline, color: AppColors.error), const SizedBox(width: 12), const Expanded(child: Text('加载失败')), TextButton(onPressed: onRetry, child: const Text('重试'))]));
}
