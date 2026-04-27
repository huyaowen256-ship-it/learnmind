import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/knowledge_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final KnowledgeCard card;
  const ChatScreen({super.key, required this.card});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messages = <_ChatMessage>[];
  final _controller = TextEditingController();
  bool _loading = false;
  String? _sessionId;
  String? _understood;

  @override
  void initState() {
    super.initState();
    // 启动时自动讲解
    WidgetsBinding.instance.addPostFrameCallback((_) => _explain());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI讲解', style: TextStyle(fontSize: 16)),
            Text(widget.card.title, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          if (_sessionId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新讲解',
              onPressed: () => setState(() {
                _messages.clear();
                _sessionId = null;
                _explain();
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          // 对话区域
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_loading)
                          Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text('AI正在分析 "${widget.card.title}"...', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          )
                        else
                          const Text('点击发送开始讲解'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildMessage(_messages[i]),
                  ),
          ),

          // 理解确认按钮
          if (_messages.isNotEmpty && _messages.last.role == 'assistant')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _UnderstandButton(label: '懂了 👍', onTap: () => _setUnderstand('懂了')),
                  const SizedBox(width: 8),
                  _UnderstandButton(label: '有点模糊', color: AppColors.warning, onTap: () => _setUnderstand('有点模糊')),
                  const SizedBox(width: 8),
                  _UnderstandButton(label: '完全不懂', color: AppColors.error, onTap: () => _setUnderstand('完全不懂')),
                ],
              ),
            ),

          // 输入区
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '追问直到弄懂...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendFollowup(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _sendFollowup,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (msg.understood != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.white.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '你说：${msg.understood}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isUser ? Colors.white70 : AppColors.success,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }

  Future<void> _explain() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.explainCard(widget.card.id);
      setState(() {
        _sessionId = result.sessionId;
        _messages.add(_ChatMessage(role: 'user', content: '请讲解这个概念'));
        _messages.add(_ChatMessage(role: 'assistant', content: result.message));
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('讲解失败: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendFollowup() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请等待首次讲解完成')));
      return;
    }

    setState(() => _loading = true);
    _controller.clear();

    setState(() => _messages.add(_ChatMessage(role: 'user', content: text)));

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.followup(widget.card.id, _sessionId!, text);
      setState(() => _messages.add(_ChatMessage(role: 'assistant', content: result.message)));
    } catch (e) {
      setState(() => _messages.removeLast());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('追问失败: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setUnderstand(String status) {
    setState(() {
      _messages.add(_ChatMessage(
        role: 'user',
        content: status,
        understood: status,
      ));
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: _getEncourageMessage(status),
      ));
    });
  }

  String _getEncourageMessage(String status) {
    if (status == '懂了') return '太棒了！🎉 这说明你已经理解了这个概念。可以在复习页面测试一下自己的掌握程度～';
    if (status == '有点模糊') return '没关系！换一种解释方式——这个概念的核心是：\n\n**用更简单的话说**：试着从最基础的角度重新理解，我们一起来拆解它。有什么具体的地方卡住了？';
    return '别担心！遇到困难是正常的。告诉我哪里完全看不懂，我会用最基础的方式一步一步解释，直到你完全弄懂为止。💪';
  }
}

class _ChatMessage {
  final String role;
  final String content;
  final String? understood;

  _ChatMessage({required this.role, required this.content, this.understood});
}

class _UnderstandButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _UnderstandButton({required this.label, this.color = AppColors.success, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }
}
