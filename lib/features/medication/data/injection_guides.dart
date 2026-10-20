/// Referências brasileiras para protótipo, consultadas em 19/10/2026.
/// Revisão clínica e versionamento no servidor pendentes antes da publicação.
/// Não contém dose, titulação, conversão de unidades ou técnica de injeção.
/// A apresentação é confirmada pelo usuário; nunca inferida pelo nome livre.
enum BodyRegion { abdomen, thigh, upperArm }

class InjectionGuide {
  const InjectionGuide({
    required this.id,
    required this.brand,
    required this.manufacturer,
    required this.presentation,
    required this.sourceUrl,
    required this.sourceVersion,
    required this.deviceNote,
    required this.rotationNote,
    this.armRequiresHelper = false,
    this.allowedRegions = const {
      BodyRegion.abdomen,
      BodyRegion.thigh,
      BodyRegion.upperArm,
    },
  });

  final String id;
  final String brand;
  final String manufacturer;
  final String presentation;
  final String sourceUrl;
  final String sourceVersion;
  final String deviceNote;
  final String rotationNote;
  final bool armRequiresHelper;

  static const reviewedOn = '19/10/2026';
  final Set<BodyRegion> allowedRegions;

  static const catalog = [
    InjectionGuide(
      id: 'br_saxenda_prefilled_3ml',
      brand: 'Saxenda',
      manufacturer: 'Novo Nordisk',
      presentation: 'Sistema preenchido multidose · 6 mg/mL · 3 mL',
      sourceUrl:
          'https://www.novonordisk.com.br/content/dam/nncorp/br/pt/pdfs/bulas/patient/Saxenda_Bula_Paciente.pdf',
      sourceVersion: 'CCDS 10.0 + SmPC 08/02/2021, v.2',
      deviceNote:
          'Sistema preenchido. Use a agulha compatível indicada na bula e uma agulha nova a cada aplicação. Não conte cliques para definir a dose.',
      rotationNote:
          'Consulte a bula e o profissional que acompanha você sobre a escolha e alternância dos pontos.',
    ),
    InjectionGuide(
      id: 'br_ozempic_1mg_3ml',
      brand: 'Ozempic',
      manufacturer: 'Novo Nordisk',
      presentation: 'Sistema preenchido multidose · 1 mg por dose · 3 mL',
      sourceUrl:
          'https://www.novonordisk.com.br/content/dam/nncorp/br/pt/pdfs/bulas/patient/Ozempic_3mL_1mg_Paciente.pdf',
      sourceVersion: 'EU-PI 20251203 + US-PI 03022025, v.03',
      deviceNote:
          'Esta referência é da apresentação de 1 mg por dose. Não se aplica automaticamente a outras apresentações. O app não converte doses em cliques.',
      rotationNote:
          'Consulte a bula e o profissional que acompanha você sobre a escolha e alternância dos pontos.',
    ),
    InjectionGuide(
      id: 'br_wegovy_multidose',
      brand: 'Wegovy',
      manufacturer: 'Novo Nordisk',
      presentation:
          'Sistema preenchido multidose brasileiro · confira a dose na embalagem',
      sourceUrl:
          'https://www.novonordisk.com.br/content/dam/nncorp/br/pt/pdfs/bulas/patient/Wegovy_Bula_Paciente.pdf',
      sourceVersion:
          'EU-PI 20251212 + EU-PI MASH 03/Mar/2025 + FDA 15/Ago/2025, v.1.0',
      deviceNote:
          'Confira a apresentação e a prescrição na bula completa. Agulhas são de uso único; não reutilize. O app não monta esquemas de doses ou múltiplas aplicações.',
      rotationNote:
          'Consulte as orientações específicas da apresentação na bula. O desenho não identifica distâncias nem avalia a pele.',
    ),
    InjectionGuide(
      id: 'br_mounjaro_single_use_05ml',
      brand: 'Mounjaro',
      manufacturer: 'Eli Lilly',
      presentation: 'Caneta aplicadora de uso único · 0,5 mL',
      sourceUrl:
          'https://delivery-p137454-e1438138.adobeaemcloud.com/adobe/assets/urn:aaid:aem:5b83fd4f-dd38-445f-8cac-e23397c2db86/renditions/original/as/Mounjaro_IFU_uso_Paciente.pdf',
      sourceVersion: 'Instruções de uso CDL28JUN23',
      deviceNote:
          'Caneta de uso único. Esta referência não é de frasco nem de KwikPen. Descarte a caneta usada conforme as instruções do fabricante.',
      rotationNote:
          'As instruções orientam alternar o ponto em cada semana; a região pode se repetir, com outro ponto dentro dela.',
      armRequiresHelper: true,
    ),
  ];
}

/// Somente códigos já oferecidos pela API podem ser gravados.
/// Códigos novos/desconhecidos continuam disponíveis na lista textual.
BodyRegion? regionForSite(String code) => switch (code) {
  'abdomen_left' || 'abdomen_right' => BodyRegion.abdomen,
  'thigh_left' || 'thigh_right' => BodyRegion.thigh,
  'arm_left' ||
  'arm_right' ||
  'upper_arm_left' ||
  'upper_arm_right' => BodyRegion.upperArm,
  _ => null,
};

bool? isLeftSite(String code) =>
    regionForSite(code) == null ? null : code.endsWith('_left');

/// Apenas restringe as referências oferecidas; não identifica a apresentação.
/// Nomes genéricos ou produtos fora da curadoria mantêm o registro manual.
List<InjectionGuide> guidesForMedication(String name) => InjectionGuide.catalog
    .where(
      (guide) => RegExp(
        '(^|[^a-z])${guide.brand.toLowerCase()}([^a-z]|\$)',
      ).hasMatch(name.toLowerCase()),
    )
    .toList();
