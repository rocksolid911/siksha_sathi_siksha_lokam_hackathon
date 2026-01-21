import 'package:flutter/material.dart';
import '../../../learn/presentation/screens/learn_screen.dart';
import '../../../snap/presentation/screens/snap_screen.dart';
import '../../../sos/presentation/sos_bottom_sheet.dart';

/// Quick Actions Grid Widget - Redesigned to match new UI
/// Shows the main action buttons with colored rounded cards
class QuickActionsGrid extends StatelessWidget {
  final String activeGrade;
  final String activeSubject;
  final int studentCount;

  const QuickActionsGrid({
    super.key,
    this.activeGrade = '',
    this.activeSubject = '',
    this.studentCount = 35,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rocket_launch, color: Color(0xFFFF6B35), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.mic,
                title: 'Ask',
                subtitle: 'SOS',
                backgroundColor: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                titleColor: const Color(0xFFDC2626),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SOSBottomSheet(
                      activeGrade: activeGrade,
                      activeSubject: activeSubject,
                      studentCount: studentCount,
                      autoStartListening: true, // Auto-start from Quick Actions
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt,
                title: 'Snap',
                subtitle: 'Lesson',
                backgroundColor: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
                titleColor: const Color(0xFF059669),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SnapScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.people_alt,
                title: 'Shared',
                subtitle: 'Strategies',
                backgroundColor: const Color(0xFFFED7AA),
                iconColor: const Color(0xFFEA580C),
                titleColor: const Color(0xFFEA580C),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LearnScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: titleColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
