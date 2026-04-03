import 'package:flutter/material.dart';

/// Shared scaffold with a [BottomNavigationBar] that switches between
/// three placeholder tabs: Home, Vitals, and Profile.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const List<_TabDefinition> _tabs = [
    _TabDefinition(
      icon: Icons.home_rounded,
      label: 'Home',
      color: Color(0xFF6C63FF),
    ),
    _TabDefinition(
      icon: Icons.monitor_heart_rounded,
      label: 'Vitals',
      color: Color(0xFF00C9A7),
    ),
    _TabDefinition(
      icon: Icons.person_rounded,
      label: 'Profile',
      color: Color(0xFFFF6B6B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tab = _tabs[_currentIndex];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _PlaceholderTab(
          key: ValueKey(_currentIndex),
          icon: tab.icon,
          label: tab.label,
          color: tab.color,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.icon, color: colorScheme.primary),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _TabDefinition {
  final IconData icon;
  final String label;
  final Color color;

  const _TabDefinition({
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// A simple placeholder body for each tab.
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PlaceholderTab({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
