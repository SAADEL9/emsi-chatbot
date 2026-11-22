import 'package:flutter/material.dart';

import '../theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.onSettings, this.onMenu});
  final VoidCallback? onSettings;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 10),
      child: Row(
        children: [
          if (onMenu != null)
            IconButton(
              tooltip: 'Ouvrir le menu',
              onPressed: onMenu,
              icon: const Icon(Icons.menu_rounded, color: EmsiColors.navy),
            ),
          Container(
            width: 2,
            height: 54,
            decoration: BoxDecoration(
              color: EmsiColors.navy,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMSI Chatbot',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: EmsiColors.ink,
                  ),
                ),
                Text(
                  'Votre assistant intelligent 🎓',
                  style: TextStyle(fontSize: 15, color: EmsiColors.ink),
                ),
              ],
            ),
          ),
          if (onSettings != null)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD7E0F1)),
                color: Colors.white.withValues(alpha: 0.32),
              ),
              child: IconButton(
                tooltip: 'Paramètres',
                onPressed: onSettings,
                icon: const Icon(
                  Icons.settings_rounded,
                  color: EmsiColors.navy,
                  size: 27,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
