import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../data/professional_models.dart';
import '../data/professional_repository.dart';
import 'professional_widgets.dart';

/// Perfil público do profissional e pedido de contato.
class ProfessionalDetailPage extends ConsumerWidget {
  const ProfessionalDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(professionalProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Profissional')),
      body: AsyncValueView<Professional>(
        value: value,
        onRetry: () => ref.invalidate(professionalProvider(id)),
        data: (p) => _Body(professional: p),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.professional});

  final Professional professional;

  @override
  Widget build(BuildContext context) {
    final p = professional;
    final price = priceLabel(p);
    final place = [p.neighborhood, p.place].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
      children: [
        Text(p.name, style: context.text.headlineSmall),
        Text(p.categoryLabel, style: context.text.bodyMedium),
        const SizedBox(height: Space.sm),
        VerifiedCouncil(professional: p),
        if (p.bio != null && p.bio!.isNotEmpty) ...[
          const SectionHeader(title: 'Apresentação'),
          Text(p.bio!),
        ],
        if (p.specialties.isNotEmpty) ...[
          const SectionHeader(title: 'Especialidades'),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [for (final s in p.specialties) Chip(label: Text(s.label))],
          ),
        ],
        const SectionHeader(title: 'Atendimento'),
        _Line(icon: Icons.videocam_outlined, text: p.modalities.map(modalityLabel).join(' e ')),
        if (p.inPerson && place.isNotEmpty) _Line(icon: Icons.place_outlined, text: place),
        if (p.distanceKm != null)
          _Line(icon: Icons.near_me_outlined, text: 'Cerca de ${p.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km de você'),
        if (price != null) _Line(icon: Icons.payments_outlined, text: 'Valor informado pelo profissional: $price'),
        if (p.availabilityNotes != null && p.availabilityNotes!.isNotEmpty)
          _Line(icon: Icons.schedule_outlined, text: p.availabilityNotes!),
        const SizedBox(height: Space.lg),
        const StatusBanner(
          message:
              'O PicNutri não agenda horários nem intermedeia pagamentos. O profissional responde pelo portal e '
              'combina o atendimento diretamente com você. Nenhum dado de saúde é enviado sem a sua autorização.',
        ),
        const SizedBox(height: Space.lg),
        if (p.hasPendingRequest) ...[
          const StatusBanner(
            tone: BannerTone.success,
            message: 'Solicitação enviada. Você será avisado quando o profissional responder.',
          ),
          const SizedBox(height: Space.sm),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.contactRequests),
            child: const Text('Ver minhas solicitações'),
          ),
        ] else if (!p.acceptsNewClients)
          const StatusBanner(
            tone: BannerTone.warning,
            message: 'Este profissional não está aceitando novos atendimentos no momento.',
          )
        else
          FilledButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              useSafeArea: true,
              builder: (_) => ContactRequestSheet(professional: p),
            ),
            icon: const Icon(Icons.mail_outline),
            label: const Text('Solicitar contato'),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.pic.textSecondary),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Pedido de contato com consentimentos separados: dados de contato (sempre
/// necessário) e, opcionalmente, compartilhamento de dados do app.
class ContactRequestSheet extends ConsumerStatefulWidget {
  const ContactRequestSheet({super.key, required this.professional});

  final Professional professional;

  @override
  ConsumerState<ContactRequestSheet> createState() => _ContactRequestSheetState();
}

class _ContactRequestSheetState extends ConsumerState<ContactRequestSheet> {
  final _requestId = newRequestId();
  final _message = TextEditingController();
  final _phone = TextEditingController();
  final _purpose = TextEditingController();
  late String _modality = widget.professional.modalities.first;
  bool _shareContact = false;
  bool _shareData = false;
  final Set<String> _categories = {};
  int _days = 30;
  bool _shareConsent = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    _phone.dispose();
    _purpose.dispose();
    super.dispose();
  }

  bool get _valid =>
      _shareContact &&
      (!_shareData || (_categories.isNotEmpty && _purpose.text.trim().length >= 5 && _shareConsent));

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final p = widget.professional;
    try {
      await ref.read(professionalRepositoryProvider).requestContact(
        p.id,
        modality: _modality,
        requestId: _requestId,
        message: _message.text.trim().isEmpty ? null : _message.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        share: _shareData
            ? ShareRequest(categories: _categories.toList(), purpose: _purpose.text.trim(), days: _days)
            : null,
      );
      ref
        ..invalidate(professionalProvider(p.id))
        ..invalidate(contactRequestsProvider)
        ..invalidate(shareGrantsProvider);
      if (!mounted) return;
      showMessage(context, 'Solicitação enviada. Você será avisado quando ${p.name} responder.');
      Navigator.of(context).pop();
    } on Object catch (e) {
      // A folha cobre a tela: o erro aparece nela, não num aviso por baixo.
      if (mounted) setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.professional;
    final healthConsent = ref.watch(currentAccountProvider)?.consents.healthData ?? false;
    final shareOptions = ref.watch(professionalsMetaProvider).value?.shareCategories ?? const <ValueLabel>[];
    final chosen = shareOptions.where((o) => _categories.contains(o.value)).map((o) => o.label.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        children: [
          Text('Solicitar contato com ${p.name}', style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          if (p.modalities.length > 1)
            SegmentedButton<String>(
              segments: [for (final m in p.modalities) ButtonSegment(value: m, label: Text(modalityLabel(m)))],
              selected: {_modality},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _modality = s.first),
            )
          else
            Text('Atendimento ${modalityLabel(_modality).toLowerCase()}', style: context.text.bodyMedium),
          const SizedBox(height: Space.md),
          TextField(
            controller: _message,
            maxLength: 1000,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Mensagem (opcional)',
              hintText: 'Conte o que você procura e os melhores horários.',
            ),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telefone para contato (opcional)'),
          ),
          const SizedBox(height: Space.sm),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _shareContact,
            onChanged: (v) => setState(() => _shareContact = v ?? false),
            title: Text('Autorizo enviar meu nome, e-mail e o telefone informado a ${p.name} para responder esta solicitação.'),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _shareData && healthConsent,
            onChanged: healthConsent ? (v) => setState(() => _shareData = v) : null,
            title: const Text('Compartilhar também dados do PicNutri (opcional)'),
            subtitle: Text(
              healthConsent
                  ? 'Você escolhe quais dados, para quê e por quanto tempo. Pode revogar quando quiser.'
                  : 'Requer a autorização de dados de saúde em Perfil > Privacidade e dados.',
            ),
          ),
          if (_shareData && healthConsent) ...[
            for (final o in shareOptions)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _categories.contains(o.value),
                title: Text(o.label),
                onChanged: (v) => setState(() {
                  if (v ?? false) {
                    _categories.add(o.value);
                  } else {
                    _categories.remove(o.value);
                  }
                }),
              ),
            TextField(
              controller: _purpose,
              maxLength: 255,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Finalidade',
                hintText: 'Ex.: preparar a primeira consulta',
              ),
            ),
            Text('Por quanto tempo', style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 dias')),
                ButtonSegment(value: 30, label: Text('30 dias')),
                ButtonSegment(value: 90, label: Text('90 dias')),
              ],
              selected: {_days},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _shareConsent,
              onChanged: (v) => setState(() => _shareConsent = v ?? false),
              title: Text(
                'Autorizo ${p.name} a consultar ${chosen.isEmpty ? 'os dados marcados' : chosen.join(', ')}'
                '${_purpose.text.trim().isEmpty ? '' : ' para "${_purpose.text.trim()}"'}, por $_days dias. '
                'Cada consulta fica registrada e posso revogar em Privacidade e dados.',
              ),
            ),
          ],
          const SizedBox(height: Space.md),
          if (_error != null) ...[
            StatusBanner(tone: BannerTone.error, message: _error!),
            const SizedBox(height: Space.sm),
          ],
          LoadingButton(label: 'Enviar solicitação', loading: _sending, onPressed: _valid ? _send : null),
        ],
      ),
    );
  }
}
