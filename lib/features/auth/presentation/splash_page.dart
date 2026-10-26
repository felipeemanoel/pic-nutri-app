import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/session_controller.dart';

/// A abertura acompanha a verificação real da sessão, sem espera artificial.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _logo = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _details = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.status == AnimationStatus.dismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (session.hasError && !session.isLoading) {
      return Scaffold(
        body: SafeArea(
          child: ErrorView(
            message: friendlyMessage(session.error!),
            onRetry: () => ref.invalidate(sessionControllerProvider),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF087F5B),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.3, -0.35),
              radius: 1.2,
              colors: [Color(0xFF11956D), Color(0xFF087F5B), Color(0xFF06533F)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned(top: -110, right: -140, child: _Halo(size: 360)),
              const Positioned(
                bottom: -160,
                left: -180,
                child: _Halo(size: 420),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Space.xxxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _logo,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.06),
                              end: Offset.zero,
                            ).animate(_logo),
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.94,
                                end: 1,
                              ).animate(_logo),
                              child: Image.asset(
                                'assets/brand/picnutri_logo_square_white.png',
                                width: 248,
                                semanticLabel: 'PicNutri',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Space.xl),
                        FadeTransition(
                          opacity: _details,
                          child: Column(
                            children: [
                              Text(
                                'Sua evolução, no seu ritmo.',
                                textAlign: TextAlign.center,
                                style: context.text.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: Space.xxxl),
                              SizedBox(
                                width: 64,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    minHeight: 3,
                                    value:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? 0.5
                                        : null,
                                    color: Colors.white,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.18,
                                    ),
                                    semanticsLabel: 'Abrindo o PicNutri',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.045),
          width: 40,
        ),
      ),
    ),
  );
}
