import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Tappable card row used on Home and Train hub screens.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: DesignTokens.borderRadiusMd,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: DesignTokens.minTouchTarget,
          ),
          child: Padding(
            padding: DesignTokens.cardPadding,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: DesignTokens.iconSizeLg,
                  color: DesignTokens.accent,
                ),
                const SizedBox(width: DesignTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: DesignTokens.titleMedium),
                      Text(subtitle, style: DesignTokens.bodySmall),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: DesignTokens.space4,
                  color: DesignTokens.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
