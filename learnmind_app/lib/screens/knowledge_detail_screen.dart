import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/knowledge_card.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

class KnowledgeDetailScreen extends StatelessWidget {
  final KnowledgeCard card;
  const KnowledgeDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 标题
          Hero(
            tag: 'card-title-${card.id}',
            child: Material(
              color: Colors.transparent,
              child: Text(
                card.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 标签
          if (card.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.tags.map<Widget>((t) => Chip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          const SizedBox(height: 16),

          // 内容
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(card.content, style: const TextStyle(fontSize: 15, height: 1.6)),
          ),
          const SizedBox(height: 16),

          // SM-2复习数据
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('复习数据', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SM2Tile('掌握度', '${card.sm2Data.easinessFactor.toStringAsFixed(2)} EF', Icons.psychology),
                    _SM2Tile('间隔', '${card.sm2Data.interval}天', Icons.timer),
                    _SM2Tile('次数', '${card.sm2Data.repetitions}次', Icons.repeat),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '下次复习: ${card.sm2Data.nextReviewLabel}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (card.sm2Data.lastReview != null)
                  Text(
                    '上次复习: ${card.sm2Data.lastReview}',
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 操作按钮
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(card: card)),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('让AI讲解'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('复习功能：在复习页面进行')),
              );
            },
            icon: const Icon(Icons.schedule),
            label: const Text('开始复习'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除 "${card.title}"？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SM2Tile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SM2Tile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
