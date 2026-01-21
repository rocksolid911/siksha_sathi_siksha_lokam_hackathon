import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

import '../../core/constants/app_text_styles.dart';
import '../../features/sos/presentation/sos_bottom_sheet.dart';

/// SOS Floating Action Button
/// Always visible, pulsing animation to draw attention
class SOSFloatingButton extends StatefulWidget {
  final String activeGrade;
  final String activeSubject;
  final int studentCount;

  const SOSFloatingButton({
    super.key,
    this.activeGrade = '',
    this.activeSubject = '',
    this.studentCount = 35,
  });

  @override
  State<SOSFloatingButton> createState() => _SOSFloatingButtonState();
}

class _SOSFloatingButtonState extends State<SOSFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showSOSBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SOSBottomSheet(
        activeGrade: widget.activeGrade,
        activeSubject: widget.activeSubject,
        studentCount: widget.studentCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.sos.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => _showSOSBottomSheet(context),
              backgroundColor: AppColors.sos,
              elevation: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emergency_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  Text(
                    'SOS',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
