import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chaos_provider.dart';
import '../../providers/user_provider.dart';
import '../overlay/heads_up_banner_overlay.dart';

class ChaosOverlayLayer extends ConsumerStatefulWidget {
  final Widget child;
  const ChaosOverlayLayer({required this.child, super.key});

  @override
  ConsumerState<ChaosOverlayLayer> createState() => _ChaosOverlayLayerState();
}

class _ChaosOverlayLayerState extends ConsumerState<ChaosOverlayLayer>
    with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeX;
  late Animation<double> _shakeY;

  Timer? _shakeTimer;
  Timer? _popupTimer;
  final _rng = Random();

  bool _chaosWasEnabled = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    _shakeY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 3, end: -2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2, end: 2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 2, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _shakeTimer?.cancel();
    _popupTimer?.cancel();
    super.dispose();
  }

  void _startChaos(String notifStyle) {
    _chaosWasEnabled = true;

    // Shake every 10–22s
    _shakeTimer = Timer.periodic(
      Duration(seconds: 10 + _rng.nextInt(12)),
      (_) {
        if (mounted) _shakeCtrl.forward(from: 0);
      },
    );

    // Random popup every 6–14s
    _scheduleNextPopup(notifStyle);
  }

  void _scheduleNextPopup(String notifStyle) {
    final delay = 6 + _rng.nextInt(8); // 6–13s
    _popupTimer = Timer(Duration(seconds: delay), () {
      if (!mounted) return;
      final messages = messagesForStyle(notifStyle);
      final (title, body) = messages[_rng.nextInt(messages.length)];
      ref.read(headsUpProvider.notifier).show(
            title: title,
            body: body,
            urgency: _rng.nextBool()
                ? HeadsUpUrgency.warning
                : HeadsUpUrgency.info,
          );
      // Schedule next
      _scheduleNextPopup(notifStyle);
    });
  }

  void _stopChaos() {
    _chaosWasEnabled = false;
    _shakeTimer?.cancel();
    _popupTimer?.cancel();
    _shakeTimer = null;
    _popupTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final chaosOn = user?.chaosModeEnabled ?? false;
    final notifStyle = user?.notificationStyle ?? 'sarcastic';

    // Start/stop chaos timers when mode changes
    if (chaosOn && !_chaosWasEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startChaos(notifStyle);
      });
    } else if (!chaosOn && _chaosWasEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _stopChaos();
      });
    }

    if (!chaosOn) return widget.child;

    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeX.value, _shakeY.value),
          child: child,
        );
      },
      child: Stack(
        children: [
          widget.child,
          // Scanline overlay
          IgnorePointer(
            child: CustomPaint(
              painter: _ScanlinePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          // Subtle red vignette
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFEF4444).withValues(alpha: 0.07),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scanline painter ─────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}
