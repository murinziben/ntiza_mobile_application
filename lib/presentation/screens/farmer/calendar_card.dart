import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/ui.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

/// First day of the current month — the calendar's starting page.
DateTime currentMonthStart() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, 1);
}

/// Tomorrow at midnight — the default selected service date.
DateTime tomorrow() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + 1);
}

/// Stateless month calendar. The owner screen keeps [month] and [selected] in
/// providers and passes callbacks, so this widget needs no State of its own.
class CalendarCard extends StatelessWidget {
  const CalendarCard({
    super.key,
    required this.month,
    required this.selected,
    required this.onMonthChanged,
    required this.onSelected,
    this.isEnabled,
    this.isMarked,
    this.isBlocked,
  });

  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onSelected;

  /// Extra rule for selectable days (e.g. days the owner has blocked).
  final bool Function(DateTime day)? isEnabled;

  /// Days to flag as already taken (shown in red, struck through, with a legend).
  final bool Function(DateTime day)? isMarked;

  /// Days the owner switched off (amber, with their own legend entry).
  final bool Function(DateTime day)? isBlocked;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1 = Monday
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = <int?>[
      for (var i = 1; i < firstWeekday; i++) null,
      for (var d = 1; d <= daysInMonth; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1, 1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${_monthNames[month.month - 1]} ${month.year}',
                  style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700)),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1, 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(d, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < cells.length ~/ 7; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++) Expanded(child: _dayCell(cells[r * 7 + c], today)),
              ],
            ),
          if (isMarked != null || isBlocked != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (isMarked != null)
                    _legend(Icons.block, AppColors.dangerBg, AppColors.danger, 'Already booked'),
                  if (isBlocked != null)
                    _legend(Icons.do_not_disturb_on_outlined, AppColors.amberBg,
                        AppColors.amberText, 'Unavailable'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// A day number with an optional diagonal (booked) or horizontal
  /// (unavailable) line across it.
  Widget _struck(String text,
      {required double size,
      required FontWeight weight,
      required Color color,
      bool diagonal = false,
      bool horizontal = false}) {
    final label = Text(text,
        style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: color,
            decoration: horizontal ? TextDecoration.lineThrough : null));
    if (!diagonal) return label;
    return CustomPaint(foregroundPainter: _DiagonalPainter(color), child: label);
  }

  /// Legend entry: an icon on a tile in the day colour, then its meaning.
  Widget _legend(IconData icon, Color bg, Color fg, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        ],
      );

  Widget _dayCell(int? d, DateTime today) {
    if (d == null) return const SizedBox(height: 48);
    final date = DateTime(month.year, month.month, d);
    final on = !date.isBefore(today) && (isEnabled?.call(date) ?? true);
    final isSelected = date == selected;
    final future = !date.isBefore(today);
    final taken = future && (isMarked?.call(date) ?? false);
    final blocked = !taken && future && (isBlocked?.call(date) ?? false);
    return Semantics(
      button: true,
      enabled: on,
      label: taken
          ? '${dayMonth(date)}, already booked'
          : blocked
              ? '${dayMonth(date)}, unavailable'
              : dayMonth(date),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: on ? () => onSelected(date) : null,
        child: Container(
          height: 48,
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : taken
                    ? AppColors.dangerBg
                    : blocked
                        ? AppColors.amberBg
                        : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _struck(
            '$d',
            size: 15.5,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : taken
                    ? AppColors.danger
                    : blocked
                        ? AppColors.amberText
                        : on
                            ? AppColors.ink
                            : AppColors.faint,
            diagonal: taken && !isSelected,
            horizontal: blocked && !isSelected,
          ),
        ),
      ),
    );
  }
}

/// Draws a line from the bottom-left to the top-right corner of its child.
class _DiagonalPainter extends CustomPainter {
  const _DiagonalPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(-2, size.height + 1),
      Offset(size.width + 2, -1),
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DiagonalPainter old) => old.color != color;
}
