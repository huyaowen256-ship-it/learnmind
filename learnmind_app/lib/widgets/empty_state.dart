import 'package:flutter/material.dart';
import '../theme.dart';

/// 空状态类型枚举
enum EmptyStateType {
  noCards,      // 无知识卡片
  noResults,   // 搜索无结果
  noReview,    // 无待复习
  noStats,     // 无统计数据
  error,       // 加载错误
}

/// 插图式空状态组件（纯Dart绘制，无外部资源依赖）
class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final illustColor = isDark ? AppColors.darkTextSecondary : AppColors.illustrationBlue;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 插图区域
            SizedBox(
              width: 160,
              height: 140,
              child: CustomPaint(
                painter: _EmptyStateIllustrationPainter(
                  type: type,
                  color: illustColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 标题
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_getSubtitle() != null) ...[
              const SizedBox(height: 8),
              Text(
                _getSubtitle()!,
                style: TextStyle(fontSize: 14, color: fgColor),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(_getActionIcon()),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (title != null) return title!;
    switch (type) {
      case EmptyStateType.noCards:
        return '还没有知识卡片';
      case EmptyStateType.noResults:
        return '没有找到相关结果';
      case EmptyStateType.noReview:
        return '今日复习已全部完成';
      case EmptyStateType.noStats:
        return '暂无统计数据';
      case EmptyStateType.error:
        return '加载失败';
    }
  }

  String? _getSubtitle() {
    if (subtitle != null) return subtitle;
    switch (type) {
      case EmptyStateType.noCards:
        return '点击下方按钮添加第一张知识卡片吧';
      case EmptyStateType.noResults:
        return '换个关键词试试';
      case EmptyStateType.noReview:
        return '太棒了，明天再来看看新的待复习内容';
      case EmptyStateType.noStats:
        return '添加知识卡片后会自动统计';
      case EmptyStateType.error:
        return '请检查网络后重试';
    }
  }

  IconData _getActionIcon() {
    switch (type) {
      case EmptyStateType.noCards:
      case EmptyStateType.error:
        return Icons.add;
      case EmptyStateType.noResults:
        return Icons.search_off;
      default:
        return Icons.refresh;
    }
  }
}

/// 自定义插图绘制
class _EmptyStateIllustrationPainter extends CustomPainter {
  final EmptyStateType type;
  final Color color;

  _EmptyStateIllustrationPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    switch (type) {
      case EmptyStateType.noCards:
        _paintNoCards(canvas, size, paint, fillPaint);
        break;
      case EmptyStateType.noResults:
        _paintNoResults(canvas, size, paint, fillPaint);
        break;
      case EmptyStateType.noReview:
        _paintNoReview(canvas, size, paint, fillPaint);
        break;
      case EmptyStateType.noStats:
        _paintNoStats(canvas, size, paint, fillPaint);
        break;
      case EmptyStateType.error:
        _paintError(canvas, size, paint, fillPaint);
        break;
    }
  }

  void _paintNoCards(Canvas canvas, Size size, Paint paint, Paint fill) {
    // 书本图形
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final bookPath = Path();
    // 翻开书本
    bookPath.moveTo(cx - 30, cy - 20);
    bookPath.lineTo(cx - 30, cy + 20);
    bookPath.quadraticBezierTo(cx - 30, cy + 30, cx, cy + 25);
    bookPath.quadraticBezierTo(cx + 30, cy + 30, cx + 30, cy + 20);
    bookPath.lineTo(cx + 30, cy - 20);
    bookPath.quadraticBezierTo(cx + 30, cy - 30, cx, cy - 25);
    bookPath.quadraticBezierTo(cx - 30, cy - 30, cx - 30, cy - 20);
    bookPath.close();
    canvas.drawPath(bookPath, fill);
    canvas.drawPath(bookPath, paint);
    // 书脊
    canvas.drawLine(Offset(cx, cy - 25), Offset(cx, cy + 25), paint);
    // 页面线
    canvas.drawLine(Offset(cx - 15, cy - 15), Offset(cx - 15, cy + 15), paint..color = color.withValues(alpha: 0.4));
    canvas.drawLine(Offset(cx + 15, cy - 15), Offset(cx + 15, cy + 15), paint..color = color.withValues(alpha: 0.4));
    // 星星装饰
    _drawStar(canvas, Offset(cx - 40, cy - 30), 8, paint..color = color.withValues(alpha: 0.6));
    _drawStar(canvas, Offset(cx + 42, cy - 28), 6, paint..color = color.withValues(alpha: 0.5));
  }

  void _paintNoResults(Canvas canvas, Size size, Paint paint, Paint fill) {
    // 放大镜
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;
    final radius = 28.0;
    canvas.drawCircle(Offset(cx - 8, cy - 8), radius, fill);
    canvas.drawCircle(Offset(cx - 8, cy - 8), radius, paint);
    // 镜柄
    canvas.drawLine(
      Offset(cx + radius - 16, cy + radius - 16),
      Offset(cx + radius + 5, cy + radius + 5),
      paint..strokeWidth = 4,
    );
    // X 在镜内
    final xPaint = paint..color = color.withValues(alpha: 0.5)..strokeWidth = 2.5;
    canvas.drawLine(Offset(cx - 18, cy - 18), Offset(cx + 2, cy + 2), xPaint);
    canvas.drawLine(Offset(cx - 18, cy + 2), Offset(cx + 2, cy - 18), xPaint);
  }

  void _paintNoReview(Canvas canvas, Size size, Paint paint, Paint fill) {
    // 对勾圆圈
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;
    canvas.drawCircle(Offset(cx, cy), 32, fill);
    canvas.drawCircle(Offset(cx, cy), 32, paint);
    // 对勾
    final checkPaint = paint..strokeWidth = 3.5;
    canvas.drawLine(Offset(cx - 14, cy), Offset(cx - 4, cy + 12), checkPaint);
    canvas.drawLine(Offset(cx - 4, cy + 12), Offset(cx + 16, cy - 10), checkPaint);
    // 周围装饰圆点
    for (var i = 0; i < 4; i++) {
      final angle = i * 3.14159 / 2 + 0.5;
      final r = 48.0;
      canvas.drawCircle(
        Offset(cx + r * _cos(angle), cy + r * _sin(angle)),
        3,
        fill..color = color.withValues(alpha: 0.3),
      );
    }
  }

  void _paintNoStats(Canvas canvas, Size size, Paint paint, Paint fill) {
    // 柱状图（空）
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final barW = 14.0;
    final spacing = 22.0;
    final heights = [30.0, 50.0, 35.0];
    for (var i = 0; i < 3; i++) {
      final x = cx - spacing + i * spacing;
      final h = heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barW / 2, cy - h, barW, h),
          const Radius.circular(4),
        ),
        fill..color = color.withValues(alpha: 0.1 + i * 0.05),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barW / 2, cy - h, barW, h),
          const Radius.circular(4),
        ),
        paint..color = color.withValues(alpha: 0.4 - i * 0.08),
      );
    }
    // 基线
    canvas.drawLine(Offset(cx - spacing - barW, cy), Offset(cx + spacing + barW, cy), paint..color = color.withValues(alpha: 0.3));
  }

  void _paintError(Canvas canvas, Size size, Paint paint, Paint fill) {
    // 断开的连接图标
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;
    // 左半圆
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 8, cy - 8), width: 36, height: 36),
      0.8,
      1.5,
      false,
      paint,
    );
    // 右半圆
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 8, cy + 8), width: 36, height: 36),
      3.14 + 0.8,
      1.5,
      false,
      paint,
    );
    // 闪电符号
    _drawStar(canvas, Offset(cx, cy - 30), 7, paint..color = color.withValues(alpha: 0.5));
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = i * 3.14159 * 2 / 5 - 3.14159 / 2;
      final outerX = center.dx + r * _cos(angle);
      final outerY = center.dy + r * _sin(angle);
      final innerAngle = angle + 3.14159 / 5;
      final innerX = center.dx + r * 0.4 * _cos(innerAngle);
      final innerY = center.dy + r * 0.4 * _sin(innerAngle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double angle) => _cosApprox(angle);
  double _sin(double angle) => _sinApprox(angle);

  // Simple trig approximations
  static double _cosApprox(double x) {
    x = x % (2 * 3.14159265358979);
    double x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720;
  }

  static double _sinApprox(double x) {
    x = x % (2 * 3.14159265358979);
    double x2 = x * x;
    return x - x2 * x / 6 + x2 * x2 * x / 120 - x2 * x2 * x2 * x / 5040;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
