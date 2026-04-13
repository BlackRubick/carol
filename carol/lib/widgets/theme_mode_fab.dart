import 'package:flutter/material.dart';

class ThemeModeFab extends StatelessWidget {
  const ThemeModeFab({
    super.key,
    required this.themeMode,
    required this.onToggle,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: Align(
          alignment: Alignment.topRight,
          child: Material(
            color: colorScheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            elevation: 2,
            child: IconButton(
              // Keep the button outside Overlay-sensitive tooltip behavior.
              onPressed: onToggle,
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
