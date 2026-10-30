import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/design_system.dart';
import '../domain/simple_markdown.dart';

/// Mostra o texto dos conteúdos (Markdown simples) com a tipografia do app.
class MarkdownView extends StatefulWidget {
  const MarkdownView({super.key, required this.data});

  final String data;

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _link(String url) {
    final r = TapGestureRecognizer()
      ..onTap = () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    _recognizers.add(r);
    return r;
  }

  TextSpan _spans(BuildContext context, String text, TextStyle? base) {
    return TextSpan(
      style: base,
      children: [
        for (final s in SimpleMarkdown.inline(text))
          switch (s.style) {
            MdSpanStyle.bold => TextSpan(
              text: s.text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            MdSpanStyle.italic => TextSpan(
              text: s.text,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            MdSpanStyle.link => TextSpan(
              text: s.text,
              style: TextStyle(
                color: context.colors.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: _link(s.url!),
            ),
            MdSpanStyle.plain => TextSpan(text: s.text),
          },
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final body = context.text.bodyLarge?.copyWith(height: 1.55);
    final children = <Widget>[];
    for (final b in SimpleMarkdown.parse(widget.data)) {
      switch (b.type) {
        case MdBlockType.heading:
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm),
              child: Semantics(
                header: true,
                child: Text.rich(
                  _spans(
                    context,
                    b.text,
                    context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        case MdBlockType.subheading:
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
              child: Semantics(
                header: true,
                child: Text.rich(
                  _spans(
                    context,
                    b.text,
                    context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        case MdBlockType.paragraph:
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Text.rich(_spans(context, b.text, body)),
            ),
          );
        case MdBlockType.bullet || MdBlockType.ordered:
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm, left: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      b.type == MdBlockType.ordered ? '${b.number}.' : '•',
                      style: body?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: Text.rich(_spans(context, b.text, body))),
                ],
              ),
            ),
          );
        case MdBlockType.quote:
          children.add(
            Container(
              margin: const EdgeInsets.only(bottom: Space.md),
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer.withValues(alpha: 0.4),
                border: Border(
                  left: BorderSide(color: context.colors.primary, width: 4),
                ),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Text.rich(_spans(context, b.text, body)),
            ),
          );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
