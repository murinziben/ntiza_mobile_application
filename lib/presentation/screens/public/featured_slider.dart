import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../widgets/ui.dart';

/// Auto-advancing carousel of featured machines. It pauses while the user
/// touches it and stays still when system animations are turned off.
class FeaturedSlider extends StatefulWidget {
  const FeaturedSlider({
    super.key,
    required this.items,
    this.interval = const Duration(seconds: 4),
  });
  final List<Equipment> items;
  final Duration interval;

  @override
  State<FeaturedSlider> createState() => _FeaturedSliderState();
}

class _FeaturedSliderState extends State<FeaturedSlider> {
  final _controller = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || _touching || widget.items.length < 2 || !_controller.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final next = (_page + 1) % widget.items.length;
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 176,
          child: Listener(
            onPointerDown: (_) => _touching = true,
            onPointerUp: (_) => _touching = false,
            onPointerCancel: (_) => _touching = false,
            child: PageView.builder(
              controller: _controller,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _Slide(item: items[i]),
              ),
            ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: motion(context, const Duration(milliseconds: 250)),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : AppColors.green100,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.item});
  final Equipment item;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Featured: ${item.name}, ${rwf(item.price)} per ${item.unit}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadow.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AssetPhoto(item.image),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC052E16)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusChip(item.availabilityLabel),
                            const SizedBox(height: 8),
                            Text(item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800)),
                            Text('${rwf(item.price)} / ${item.unit} · ${item.place}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
                        decoration:
                            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child:
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: () => context.push('/equipment/${item.id}')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Machines to feature: ones that can be booked first, free-today ones before
/// the rest, at most [limit].
List<Equipment> featuredEquipment(List<Equipment> all, {int limit = 5}) {
  int rank(Equipment e) => switch (e.availability) {
        Availability.freeToday => 0,
        Availability.freeLater => 1,
        Availability.fullyBooked => 2,
        Availability.maintenance => 3,
      };
  final sorted = [...all]..sort((a, b) => rank(a).compareTo(rank(b)));
  return sorted.where((e) => e.bookable).take(limit).toList();
}
