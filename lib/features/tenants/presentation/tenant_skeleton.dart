import 'package:flutter/material.dart';

enum TenantPlaceholder { cards, fields, document, ledger }

class TenantSkeleton extends StatefulWidget {
  const TenantSkeleton(this.layout, {super.key});
  final TenantPlaceholder layout;

  @override
  State<TenantSkeleton> createState() => _TenantSkeletonState();
}

class _TenantSkeletonState extends State<TenantSkeleton>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.stop();
    } else if (!animation.isAnimating) {
      animation.repeat();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  Widget block(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shapes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.layout == TenantPlaceholder.ledger)
          Row(
            children: [
              Expanded(child: block(0, 64)),
              const SizedBox(width: 12),
              Expanded(child: block(0, 64)),
            ],
          ),
        for (
          var i = 0;
          i < (widget.layout == TenantPlaceholder.fields ? 2 : 3);
          i++
        )
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: widget.layout == TenantPlaceholder.cards
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(100, 14),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          block(40, 40),
                          const SizedBox(width: 12),
                          Expanded(child: block(0, 32)),
                          const SizedBox(width: 12),
                          block(52, 32),
                        ],
                      ),
                      const SizedBox(height: 12),
                      block(double.infinity, 42),
                    ],
                  )
                : block(
                    double.infinity,
                    widget.layout == TenantPlaceholder.document ? 98 : 52,
                  ),
          ),
      ],
    );
    return Semantics(
      label: 'Loading tenant information',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RepaintBoundary(
            child: MediaQuery.disableAnimationsOf(context)
                ? shapes
                : AnimatedBuilder(
                    animation: animation,
                    child: shapes,
                    builder: (context, child) => ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        final offset = animation.value * 4 - 2;
                        return LinearGradient(
                          begin: Alignment(offset - 1, 0),
                          end: Alignment(offset + 1, 0),
                          colors: [
                            colors.surfaceContainerHighest,
                            colors.surfaceContainerLow,
                            colors.surfaceContainerHighest,
                          ],
                        ).createShader(bounds);
                      },
                      child: child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
