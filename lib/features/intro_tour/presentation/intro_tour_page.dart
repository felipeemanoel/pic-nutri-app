import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../data/intro_tour_store.dart';

/// Uma etapa da primeira visita: uma ação essencial, explicada em poucas palavras.
class IntroStep {
  const IntroStep({
    required this.icon,
    required this.title,
    required this.message,
    this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? color;
}

const introSteps = [
  IntroStep(
    icon: Icons.restaurant_menu_rounded,
    title: 'Registre suas refeições',
    message:
        'Na aba Alimentação, toque em "Refeição". Pode ser por foto, por texto ou buscando os alimentos.',
  ),
  IntroStep(
    icon: Icons.water_drop_rounded,
    title: 'Registre a água',
    message:
        'No Início, toque em "200 ml" no cartão de água a cada copo. Tocando no cartão, você informa outras quantidades.',
  ),
  IntroStep(
    icon: Icons.insights_rounded,
    title: 'Acompanhe metas e evolução',
    message:
        'O Início mostra suas metas do dia e o resumo da semana. Em Evolução, você vê seu progresso com o tempo.',
  ),
];

/// Primeira visita guiada: três etapas com "Próximo", "Pular" e "Concluir".
///
/// Aparece automaticamente uma vez por conta (a conclusão ou dispensa fica
/// salva localmente e sincronizada com o servidor). Na ajuda, pode ser revista sem alterar nada ([review]).
class IntroTourPage extends ConsumerStatefulWidget {
  const IntroTourPage({super.key, this.review = false});

  final bool review;

  @override
  ConsumerState<IntroTourPage> createState() => _IntroTourPageState();
}

class _IntroTourPageState extends ConsumerState<IntroTourPage> {
  final _pages = PageController();
  int _index = 0;
  bool _closing = false;
  bool _moving = false;

  bool get _last => _index == introSteps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_closing || _moving) return;
    if (_last) return _finish('completed');
    setState(() => _moving = true);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _pages.jumpToPage(_index + 1);
    } else {
      await _pages.nextPage(
        duration: Motion.medium,
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(() => _moving = false);
  }

  /// Libera a saída antes de navegar; a rede não bloqueia o fechamento.
  Future<void> _finish(String status) async {
    if (_closing) return;
    final account = ref.read(currentAccountProvider);
    final store = ref.read(introTourStoreProvider);
    final repository = ref.read(authRepositoryProvider);
    setState(() => _closing = true);
    if (!widget.review && account != null) {
      await store.writeStatus(account.email, status);
      if (mounted && ref.read(currentAccountProvider)?.email == account.email) {
        unawaited(store.sync(account.email, repository));
      }
    }
    if (!mounted) return;
    // PopScope precisa receber canPop=true antes do pop programático.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentAccountProvider);
    return PopScope(
      canPop: widget.review || _closing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish('skipped');
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: TextButton(
                    onPressed: _closing ? null : () => _finish('skipped'),
                    child: Text(widget.review ? 'Fechar' : 'Pular'),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: introSteps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) =>
                      _StepView(step: introSteps[i], position: i + 1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.page,
                  Space.md,
                  Space.page,
                  Space.xl,
                ),
                child: Column(
                  children: [
                    _Dots(count: introSteps.length, index: _index),
                    const SizedBox(height: Space.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _closing || _moving ? null : _next,
                        child: Text(_last ? 'Concluir' : 'Próximo'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step, required this.position});

  final IntroStep step;
  final int position;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(
      horizontal: Space.page,
      vertical: Space.lg,
    ),
    child: Column(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.pic.brandContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 56, color: context.colors.primary),
          ),
        ),
        const SizedBox(height: Space.xxl),
        Semantics(
          header: true,
          label: 'Etapa $position de ${introSteps.length}: ${step.title}',
          excludeSemantics: true,
          child: Text(
            step.title,
            style: context.text.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          step.message,
          style: context.text.bodyLarge?.copyWith(
            color: context.pic.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : Motion.fast,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? context.colors.primary : context.pic.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    ),
  );
}
