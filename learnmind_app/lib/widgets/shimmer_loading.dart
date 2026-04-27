import 'package:flutter/material.dart';
import '../theme.dart';

/// 骨架屏加载效果组件
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkSurface : Colors.grey.shade200;
    final highlightColor = isDark ? AppColors.darkDivider : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Shift gradient: 0→0.5→1 gives left→center→right shimmer
        final double stop = (t * 2).clamp(0.0, 1.0);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [0.0, stop, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏卡片占位（模拟知识卡片列表项）
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: ShimmerLoading(width: double.infinity, height: 16)),
              const SizedBox(width: 12),
              const ShimmerLoading(width: 50, height: 20, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 10),
          const ShimmerLoading(width: double.infinity, height: 13),
          const SizedBox(height: 6),
          const ShimmerLoading(width: 200, height: 13),
          const SizedBox(height: 10),
          Row(
            children: const [
              ShimmerLoading(width: 50, height: 18, borderRadius: 6),
              SizedBox(width: 6),
              ShimmerLoading(width: 65, height: 18, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// 骨架屏列表（加载中显示3个骨架卡片）
class ShimmerCardList extends StatelessWidget {
  final int count;

  const ShimmerCardList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }
}

/// 骨架屏统计卡片
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.85),
            AppColors.primaryLight.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const ShimmerLoading(width: 100, height: 56, borderRadius: 8),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              ShimmerLoading(width: 50, height: 24, borderRadius: 6),
              ShimmerLoading(width: 50, height: 24, borderRadius: 6),
              ShimmerLoading(width: 50, height: 24, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}
