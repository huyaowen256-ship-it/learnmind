import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/knowledge_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('学习统计')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(statsProvider),
        child: stats.when(
          data: (s) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 主数据卡片
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('知识库总览', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('${s.totalCards}', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold)),
                    const Text('张知识卡片', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniStat(label: '今日复习', value: '${s.dueToday}', color: Colors.white),
                        _MiniStat(label: '本周新增', value: '${s.thisWeekNew}', color: Colors.white),
                        _MiniStat(label: '本周复习', value: '${s.thisWeekReviewed}', color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 学习进度
              Text('学习进度', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _ProgressTile(
                label: '本周学习频率',
                subtitle: '本周新增 ${s.thisWeekNew} 张卡片',
                progress: s.totalCards > 0 ? (s.thisWeekNew / s.totalCards).clamp(0.0, 1.0) : 0,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _ProgressTile(
                label: '复习完成率',
                subtitle: '本周已复习 ${s.thisWeekReviewed} 次',
                progress: s.totalCards > 0 ? (s.thisWeekReviewed / (s.totalCards * 0.5)).clamp(0.0, 1.0) : 0,
                color: AppColors.accent,
              ),

              const SizedBox(height: 24),
              Text('掌握度分布', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _MasteryBar(totalCards: s.totalCards, newCards: s.thisWeekNew, reviewed: s.thisWeekReviewed),
            ],
          ),
          loading: () => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ShimmerStatCard(),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Expanded(child: ShimmerLoading(width: double.infinity, height: 80, borderRadius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerLoading(width: double.infinity, height: 80, borderRadius: 14)),
                  ],
                ),
              ],
            ),
          ),
          error: (e, _) => EmptyStateWidget(
            type: EmptyStateType.error,
            onAction: () => ref.invalidate(statsProvider),
            actionLabel: '重试',
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
      ],
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final String label, subtitle;
  final double progress;
  final Color color;
  const _ProgressTile({required this.label, required this.subtitle, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: AppColors.divider, color: color, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MasteryBar extends StatelessWidget {
  final int totalCards, newCards, reviewed;
  const _MasteryBar({required this.totalCards, required this.newCards, required this.reviewed});

  @override
  Widget build(BuildContext context) {
    if (totalCards == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('暂无统计数据，添加知识卡片后会自动统计', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final mastered = reviewed > newCards ? (reviewed - newCards).clamp(0, totalCards) : 0;
    final learning = totalCards - newCards - mastered;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _MasterySegment(label: '新卡片', value: newCards, color: AppColors.statusNew, total: totalCards)),
              Expanded(child: _MasterySegment(label: '学习中', value: learning, color: AppColors.statusReview, total: totalCards)),
              Expanded(child: _MasterySegment(label: '已掌握', value: mastered, color: AppColors.statusMastered, total: totalCards)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (newCards > 0) Flexible(flex: newCards, child: Container(height: 12, color: AppColors.statusNew)),
                if (learning > 0) Flexible(flex: learning, child: Container(height: 12, color: AppColors.statusReview)),
                if (mastered > 0) Flexible(flex: mastered, child: Container(height: 12, color: AppColors.statusMastered)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterySegment extends StatelessWidget {
  final String label, value;
  final Color color;
  final int total;
  const _MasterySegment({required this.label, required this.value, required this.color, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text('${total > 0 ? (value / total * 100).toInt() : 0}%', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }
}
