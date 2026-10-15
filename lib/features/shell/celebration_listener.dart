import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../league/league_provider.dart';
import '../league/league_up_dialog.dart';
import '../profile/badges.dart';
import '../profile/widgets/badge_widgets.dart';

/// Muestra los festejos pendientes, uno por uno, donde sea que esté el
/// usuario (por ejemplo, encima del resultado de una lección): primero el
/// ascenso de liga y después cada insignia nueva.
class CelebrationListener extends StatefulWidget {
  const CelebrationListener({super.key, required this.child});

  final Widget child;

  @override
  State<CelebrationListener> createState() => _CelebrationListenerState();
}

class _CelebrationListenerState extends State<CelebrationListener> {
  BadgeProvider? _badges;
  LeagueProvider? _league;
  bool _showing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final badges = context.read<BadgeProvider>();
    final league = context.read<LeagueProvider>();
    if (badges != _badges || league != _league) {
      _badges?.removeListener(_maybeShow);
      _league?.removeListener(_maybeShow);
      _badges = badges..addListener(_maybeShow);
      _league = league..addListener(_maybeShow);
      _maybeShow();
    }
  }

  @override
  void dispose() {
    _badges?.removeListener(_maybeShow);
    _league?.removeListener(_maybeShow);
    super.dispose();
  }

  bool get _pending =>
      _league?.promotionToCelebrate != null || _badges?.nextCelebration != null;

  void _maybeShow() {
    if (_showing || !_pending) return;
    _showing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _showing = false;
        return;
      }
      final promotion = _league?.promotionToCelebrate;
      final badge = _badges?.nextCelebration;
      if (promotion != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => LeagueUpDialog(result: promotion),
        );
        _showing = false;
        _league?.promotionCelebrated(); // dispara _maybeShow otra vez
      } else if (badge != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => BadgeCelebrationDialog(badge: badge),
        );
        _showing = false;
        _badges?.celebrationShown();
      } else {
        _showing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
