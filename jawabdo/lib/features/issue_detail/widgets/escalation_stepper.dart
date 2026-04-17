import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/issue.dart';

class EscalationStepper extends StatelessWidget {
  final EscalationTier currentTier;
  final List<EscalationHistoryEntry> history;

  const EscalationStepper({
    super.key,
    required this.currentTier,
    required this.history,
  });

  static const _tiers = [
    EscalationTier.ward,
    EscalationTier.municipal,
    EscalationTier.state,
    EscalationTier.mediaNgo,
  ];

  static const _labels = ['Ward', 'Municipal', 'State', 'Media/NGO'];

  static const _colors = [
    AppColors.tierWard,
    AppColors.tierMunicipal,
    AppColors.tierState,
    AppColors.tierMediaNgo,
  ];

  EscalationHistoryEntry? _historyFor(EscalationTier tier) {
    final tierStr = escalationTierToString(tier);
    try {
      return history.firstWhere((h) => h.tier == tierStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _tiers.indexOf(currentTier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escalation Tier',
            style: GoogleFonts.sourceCodePro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_tiers.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final tierIdx = i ~/ 2;
                final completed = tierIdx < currentIdx;
                return Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: completed
                          ? _colors[tierIdx]
                          : AppColors.cardDivider,
                    ),
                    child: completed
                        ? null
                        : CustomPaint(painter: _DashedLinePainter()),
                  ),
                );
              }
              final idx = i ~/ 2;
              final tier = _tiers[idx];
              final isCurrent = idx == currentIdx;
              final isCompleted = idx < currentIdx;
              final entry = _historyFor(tier);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: entry != null
                        ? '${entry.triggeredAt.toLocal().toString().substring(0, 10)}\n${entry.reason}'
                        : '',
                    child: isCurrent
                        ? _PulsingNode(color: _colors[idx])
                        : Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted ? _colors[idx] : Colors.white,
                              border: Border.all(
                                color: isCompleted ? _colors[idx] : AppColors.cardDivider,
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[idx],
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isCurrent || isCompleted
                          ? _colors[idx]
                          : AppColors.grey,
                    ),
                  ),
                  if (entry != null)
                    Text(
                      entry.triggeredAt.toLocal().toString().substring(0, 10),
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 9,
                        color: AppColors.grey,
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PulsingNode extends StatefulWidget {
  final Color color;
  const _PulsingNode({required this.color});

  @override
  State<_PulsingNode> createState() => _PulsingNodeState();
}

class _PulsingNodeState extends State<_PulsingNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = Tween(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24 * _anim.value,
            height: 24 * _anim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.2),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
            child: const Icon(Icons.circle, size: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cardDivider
      ..strokeWidth = 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
