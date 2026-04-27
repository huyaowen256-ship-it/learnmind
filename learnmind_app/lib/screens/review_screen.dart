import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/knowledge_provider.dart';
import '../services/api_service.dart';
import '../models/knowledge_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import 'dart:async';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _currentIndex = 0;
  List<ReviewQuestion> _currentQuestions = [];
  int _selectedOption = -1;
  String? _selectedAnswer;
  bool _answered = false;
  bool _loadingQuestions = false;
  String _sessionId = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(todayReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: dashboard.when(
        data: (data) {
          if (data.cards.isEmpty) {
            return const EmptyStateWidget(type: EmptyStateType.noReview);
          }

          if (_currentIndex >= data.cards.length) {
            return _ReviewCompleteScreen(
              reviewed: data.cards.length,
              onRestart: () => setState(() => _currentIndex = 0),
            );
          }

          final card = data.cards[_currentIndex];
          return _ReviewCardView(
            card: card,
            currentIndex: _currentIndex,
            total: data.cards.length,
            loadingQuestions: _loadingQuestions,
            currentQuestions: _currentQuestions,
            selectedOption: _selectedOption,
            selectedAnswer: _selectedAnswer,
            answered: _answered,
            onStartReview: () => _loadQuestions(card.id),
            onSelectOption: (i) => setState(() => _selectedOption = i),
            onSelectAnswer: (a) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _selectedAnswer = a);
              });
            },
            onSubmit: () => _submitReview(card.id),
            onNext: () => setState(() {
              _currentIndex++;
              _answered = false;
              _selectedOption = -1;
              _selectedAnswer = null;
              _currentQuestions = [];
            }),
          );
        },
        loading: () => const Center(child: ShimmerStatCard()),
        error: (e, _) => EmptyStateWidget(
          type: EmptyStateType.error,
          onAction: () => ref.invalidate(todayReviewProvider),
          actionLabel: '重试',
        ),
      ),
    );
  }

  Future<void> _loadQuestions(String cardId) async {
    setState(() => _loadingQuestions = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.getReviewQuestions(cardId);
      setState(() {
        _currentQuestions = result.questions;
        _sessionId = result.sessionId;
        _loadingQuestions = false;
      });
    } catch (e) {
      setState(() => _loadingQuestions = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成题目失败: $e')));
    }
  }

  Future<void> _submitReview(String cardId) async {
    if (_answered) return;

    // 用选择的选项/答案反推 quality
    int quality;
    if (_currentQuestions.isNotEmpty) {
      final q = _currentQuestions[0];
      if (q.questionType == 'multiple_choice' && _selectedOption >= 0) {
        final correct = q.options != null && q.options!.length > _selectedOption &&
            (_selectedOption == _correctOptionIndex(q));
        quality = correct ? 5 : (_selectedOption == -1 ? 0 : 2);
      } else {
        quality = _selectedAnswer != null ? 4 : 1;
      }
    } else {
      quality = 3;
    }

    try {
      final api = ref.read(apiServiceProvider);
      await api.submitReview(cardId, quality);
      setState(() => _answered = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(quality >= 3 ? '✅ 正确！继续加油' : '❌ 需要加强记忆'), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e')));
    }
  }

  int _correctOptionIndex(ReviewQuestion q) {
    if (q.answer.isEmpty) return 0;
    // 解析 "B" 这样的答案
    final match = RegExp(r'[A-D]').firstMatch(q.answer);
    if (match == null) return 0;
    return match.group()!.codeUnitAt(0) - 65;
  }
}

class _ReviewCardView extends StatelessWidget {
  final KnowledgeCard card;
  final int currentIndex, total;
  final bool loadingQuestions;
  final List<ReviewQuestion> currentQuestions;
  final int selectedOption;
  final String? selectedAnswer;
  final bool answered;
  final VoidCallback onStartReview;
  final Function(int) onSelectOption;
  final Function(String) onSelectAnswer;
  final VoidCallback onSubmit;
  final VoidCallback onNext;

  const _ReviewCardView({
    required this.card,
    required this.currentIndex,
    required this.total,
    required this.loadingQuestions,
    required this.currentQuestions,
    required this.selectedOption,
    required this.selectedAnswer,
    required this.answered,
    required this.onStartReview,
    required this.onSelectOption,
    required this.onSelectAnswer,
    required this.onSubmit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 进度
        Row(
          children: [
            Text('第 ${currentIndex + 1} / $total 题', style: TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text('${card.title}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (currentIndex + 1) / total, backgroundColor: AppColors.divider, color: AppColors.primary),
        const SizedBox(height: 24),

        // 题目区域
        if (currentQuestions.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
            child: Column(
              children: [
                Text('准备好复习了吗？', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Text(card.content, style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 20),
                if (loadingQuestions)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: onStartReview,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始答题'),
                  ),
              ],
            ),
          ),
        ] else ...[
          for (var i = 0; i < currentQuestions.length; i++) _QuestionWidget(
            question: currentQuestions[i],
            index: i,
            selectedOption: selectedOption,
            selectedAnswer: selectedAnswer,
            answered: answered,
            onSelectOption: onSelectOption,
            onSelectAnswer: onSelectAnswer,
          ),
          const SizedBox(height: 20),
          if (!answered)
            ElevatedButton(onPressed: onSubmit, child: const Text('提交答案'))
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('答题完成，继续下一题！')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: onNext, child: const Text('下一题')),
              ],
            ),
        ],
      ],
    );
  }
}

class _QuestionWidget extends StatelessWidget {
  final ReviewQuestion question;
  final int index;
  final int selectedOption;
  final String? selectedAnswer;
  final bool answered;
  final Function(int) onSelectOption;
  final Function(String) onSelectAnswer;

  const _QuestionWidget({
    required this.question,
    required this.index,
    required this.selectedOption,
    required this.selectedAnswer,
    required this.answered,
    required this.onSelectOption,
    required this.onSelectAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Q${index + 1}', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(question.questionType == 'multiple_choice' ? '选择题' : '简答题', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(question.question, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 12),
          if (question.questionType == 'multiple_choice' && question.options != null) ...[
            ...question.options!.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: answered ? null : () => onSelectOption(e.key),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _optionColor(e.key),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _optionBorderColor(e.key)),
                      ),
                      child: Row(
                        children: [
                          Text('${String.fromCharCode(65 + e.key)}. ', style: TextStyle(fontWeight: FontWeight.w600, color: _optionTextColor(e.key))),
                          Expanded(child: Text(e.value.replaceAll(RegExp(r'^[A-D]\.\s*'), ''), style: TextStyle(color: _optionTextColor(e.key)))),
                        ],
                      ),
                    ),
                  ),
                )),
          ] else ...[
            TextField(
              enabled: !answered,
              decoration: const InputDecoration(hintText: '输入你的答案...'),
              maxLines: 3,
              onChanged: onSelectAnswer,
            ),
          ],
        ],
      ),
    );
  }

  Color _optionColor(int i) {
    if (answered) {
      return AppColors.primary.withValues(alpha: 0.05);
    }
    return selectedOption == i ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background;
  }

  Color _optionBorderColor(int i) {
    if (answered) return AppColors.divider;
    return selectedOption == i ? AppColors.primary : AppColors.divider;
  }

  Color _optionTextColor(int i) {
    return selectedOption == i ? AppColors.primary : AppColors.textPrimary;
  }
}

class _ReviewCompleteScreen extends StatelessWidget {
  final int reviewed;
  final VoidCallback onRestart;
  const _ReviewCompleteScreen({required this.reviewed, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('今日复习完成！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('共复习 $reviewed 张卡片', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRestart, child: const Text('再看一遍')),
        ],
      ),
    );
  }
}
