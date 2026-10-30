/// Leitor de Markdown simples usado nos conteúdos da equipe: títulos (## e
/// ###), parágrafos, listas com marcador ou numeradas, citações e, dentro do
/// texto, **negrito**, *itálico* e [links](https://...). Nada de HTML.
library;

enum MdBlockType { heading, subheading, paragraph, bullet, ordered, quote }

class MdBlock {
  const MdBlock(this.type, this.text, {this.number});

  final MdBlockType type;
  final String text;

  /// Número do item em listas numeradas.
  final int? number;

  @override
  String toString() => '$type($number): $text';
}

enum MdSpanStyle { plain, bold, italic, link }

class MdSpan {
  const MdSpan(this.text, this.style, {this.url});

  final String text;
  final MdSpanStyle style;
  final String? url;

  @override
  String toString() => '$style:$text${url == null ? '' : '<$url>'}';
}

abstract final class SimpleMarkdown {
  static final _ordered = RegExp(r'^(\d+)[.)]\s+(.*)$');
  static final _bullet = RegExp(r'^[-*+]\s+(.*)$');
  static final _tableSep = RegExp(r'^\|?\s*:?-{2,}');

  static List<MdBlock> parse(String source) {
    final blocks = <MdBlock>[];
    final paragraph = <String>[];

    void flush() {
      if (paragraph.isNotEmpty) {
        blocks.add(MdBlock(MdBlockType.paragraph, paragraph.join(' ')));
        paragraph.clear();
      }
    }

    for (final raw in source.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        flush();
        continue;
      }
      if (line.startsWith('### ') || line.startsWith('#### ')) {
        flush();
        blocks.add(
          MdBlock(
            MdBlockType.subheading,
            line.replaceFirst(RegExp(r'^#+\s+'), ''),
          ),
        );
      } else if (line.startsWith('# ') || line.startsWith('## ')) {
        flush();
        blocks.add(
          MdBlock(
            MdBlockType.heading,
            line.replaceFirst(RegExp(r'^#+\s+'), ''),
          ),
        );
      } else if (line.startsWith('>')) {
        flush();
        blocks.add(
          MdBlock(MdBlockType.quote, line.replaceFirst(RegExp(r'^>\s?'), '')),
        );
      } else if (_bullet.hasMatch(line)) {
        flush();
        blocks.add(
          MdBlock(MdBlockType.bullet, _bullet.firstMatch(line)!.group(1)!),
        );
      } else if (_ordered.hasMatch(line)) {
        flush();
        final m = _ordered.firstMatch(line)!;
        blocks.add(
          MdBlock(
            MdBlockType.ordered,
            m.group(2)!,
            number: int.parse(m.group(1)!),
          ),
        );
      } else if (line.startsWith('|')) {
        // Tabela: cada linha vira um item de lista ("a · b · c").
        flush();
        if (_tableSep.hasMatch(line)) continue;
        final cells = line
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty);
        blocks.add(MdBlock(MdBlockType.bullet, cells.join(' · ')));
      } else {
        paragraph.add(line);
      }
    }
    flush();
    return blocks;
  }

  static final _inline = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|\[([^\]]+)\]\(([^)\s]+)\)|\*(?!\s)(.+?)\*|_(?!\s)(.+?)_',
  );

  static List<MdSpan> inline(String text) {
    final spans = <MdSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > last) {
        spans.add(MdSpan(text.substring(last, m.start), MdSpanStyle.plain));
      }
      if (m.group(1) != null || m.group(2) != null) {
        spans.add(MdSpan(m.group(1) ?? m.group(2)!, MdSpanStyle.bold));
      } else if (m.group(3) != null) {
        final url = m.group(4)!;
        final safe = url.startsWith('https://') || url.startsWith('http://');
        spans.add(
          MdSpan(
            m.group(3)!,
            safe ? MdSpanStyle.link : MdSpanStyle.plain,
            url: safe ? url : null,
          ),
        );
      } else {
        spans.add(MdSpan(m.group(5) ?? m.group(6)!, MdSpanStyle.italic));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(MdSpan(text.substring(last), MdSpanStyle.plain));
    }
    return spans;
  }
}
