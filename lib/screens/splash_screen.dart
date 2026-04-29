import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _exitCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoSlideY;
  late final Animation<double> _glowRadius;
  late final Animation<double> _exitFade;

  static const _bgColor = Color(0xFF0B0B0D);
  static const _accentYellow = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _logoCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _logoSlideY = Tween<double>(begin: 40.0, end: 0.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    _glowRadius = Tween<double>(begin: 80.0, end: 130.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    await Future.delayed(const Duration(milliseconds: 1600));
    await _exitCtrl.forward();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: FadeTransition(
        opacity: _exitFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Animated background ────────────────────────
            _AnimatedBgGradient(),

            // ── Ambient glow ───────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: _glowRadius,
                builder: (_, __) => Container(
                  width: _glowRadius.value * 2.4,
                  height: _glowRadius.value * 2.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _accentYellow.withValues(alpha: 0.20),
                      _accentYellow.withValues(alpha: 0.06),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),

            // ── Main content ───────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 4),

                  // ── App Name in Center ─────────────────────
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _logoFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _logoSlideY.value),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      ),
                    ),
                    child: Text(
                      'KHARCHA',
                      style: GoogleFonts.outfit(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 14,
                        color: _accentYellow,
                        shadows: [
                          Shadow(
                            color: _accentYellow.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: _accentYellow.withValues(alpha: 0.3),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 5),

                  // ── Progress bar at bottom ───────────────────
                  _YellowLoadingBar(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _AnimatedBgGradient extends StatefulWidget {
  @override
  State<_AnimatedBgGradient> createState() => _AnimatedBgGradientState();
}

class _AnimatedBgGradientState extends State<_AnimatedBgGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.4, -1),
              end: Alignment(1, 1 - t * 0.3),
              colors: const [
                Color(0xFF0B0B0D),
                Color(0xFF111115),
                Color(0xFF0B0B0D),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _YellowLoadingBar extends StatefulWidget {
  @override
  State<_YellowLoadingBar> createState() => _YellowLoadingBarState();
}

class _YellowLoadingBarState extends State<_YellowLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100))
      ..forward();
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, __) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loading…',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.white24, letterSpacing: 1),
                ),
                Text(
                  '${(_progress.value * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                      letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: _progress.value,
                minHeight: 3,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFB300)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
