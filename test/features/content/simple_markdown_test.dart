import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/content/domain/simple_markdown.dart';

void main() {
  test('separa títulos, parágrafos, listas e citações', () {
    final blocks = SimpleMarkdown.parse(
      'Intro em\nduas linhas.\n\n## Título\n\n### Sub\n\n- um\n* dois\n\n1. primeiro\n2) segundo\n\n> citação',
    );
    expect(blocks.map((b) => b.type).toList(), [
      MdBlockType.paragraph,
      MdBlockType.heading,
      MdBlockType.subheading,
      MdBlockType.bullet,
      MdBlockType.bullet,
      MdBlockType.ordered,
      MdBlockType.ordered,
      MdBlockType.quote,
    ]);
    expect(blocks.first.text, 'Intro em duas linhas.');
    expect(blocks[6].number, 2);
    expect(blocks[6].text, 'segundo');
  });

  test('transforma tabela em itens de lista', () {
    final blocks = SimpleMarkdown.parse(
      '| Semana | Dias |\n|---|---|\n| 1 | 3 dias |',
    );
    expect(blocks.map((b) => b.text).toList(), ['Semana · Dias', '1 · 3 dias']);
  });

  test('marca negrito, itálico e links seguros', () {
    final spans = SimpleMarkdown.inline(
      'Use **proteína**, *calma* e [o guia](https://picnutri.com.br) ou [isto](javascript:alert(1)).',
    );
    expect(
      spans.where((s) => s.style == MdSpanStyle.bold).single.text,
      'proteína',
    );
    expect(
      spans.where((s) => s.style == MdSpanStyle.italic).single.text,
      'calma',
    );
    final link = spans.where((s) => s.style == MdSpanStyle.link).single;
    expect(link.url, 'https://picnutri.com.br');
    expect(spans.map((s) => s.text).join(), contains('isto'));
  });
}
