import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/knowledge_provider.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _tags = <String>[];
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加知识'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题 *',
                hintText: '例如：什么是链式求导法则？',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '标题不能为空' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // 内容
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '核心内容 *',
                hintText: '输入你想掌握的核心知识...',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              validator: (v) => v == null || v.trim().isEmpty ? '内容不能为空' : null,
            ),
            const SizedBox(height: 16),

            // 标签
            const Text('标签（可选）', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(hintText: '输入标签后按回车添加'),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addTag(_tagController.text),
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.primary,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((t) => Chip(
                  label: Text(t),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _tags.remove(t)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // 提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI会基于你输入的内容生成讲解和复习题，建议内容具体清晰',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isNotEmpty && !_tags.contains(t) && _tags.length < 5) {
      setState(() => _tags.add(t));
      _tagController.clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(knowledgeCardsNotifierProvider.notifier).createCard(
        _titleController.text.trim(),
        _contentController.text.trim(),
        _tags,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 知识卡片添加成功')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
