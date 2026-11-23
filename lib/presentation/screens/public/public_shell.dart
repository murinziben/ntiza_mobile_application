import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/ui.dart';

class NavItem {
  const NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Floating rounded bottom navigation used by every role shell. A green pill
/// slides behind the selected item.
class NtizaBottomNav extends StatelessWidget {
  const NtizaBottomNav({super.key, required this.items, required this.index, required this.onTap});
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    final slide = n <= 1 ? 0.0 : -1 + 2 * index / (n - 1);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadow.floating,
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: Alignment(slide, 0),
                duration: motion(context, const Duration(milliseconds: 260)),
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 1 / n,
                  heightFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.green100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        label: items[i].label,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => onTap(i),
                          child: ExcludeSemantics(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: i == index ? 1.12 : 1,
                                  duration: motion(context, const Duration(milliseconds: 220)),
                                  curve: Curves.easeOutBack,
                                  child: Icon(items[i].icon,
                                      size: 24,
                                      color: i == index ? AppColors.primaryDark : AppColors.faint),
                                ),
                                const SizedBox(height: 3),
                                Text(items[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                                        color:
                                            i == index ? AppColors.primaryDark : AppColors.faint)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scaffold with the shared bottom nav; the visible tab fades in on a switch.
class NavShell extends StatelessWidget {
  const NavShell({super.key, required this.shell, required this.items});
  final StatefulNavigationShell shell;
  final List<NavItem> items;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _TabFade(index: shell.currentIndex, child: shell),
        bottomNavigationBar: NtizaBottomNav(
          items: items,
          index: shell.currentIndex,
          onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      );
}

class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0.35);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _c, child: widget.child);
}

const publicNav = [
  NavItem('Home', Icons.home_outlined),
  NavItem('Equipment', Icons.agriculture_outlined),
  NavItem('Help', Icons.help_outline),
  NavItem('Account', Icons.person_outline),
];

class PublicShell extends StatelessWidget {
  const PublicShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => NavShell(shell: shell, items: publicNav);
}
