// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageChooseTitle => 'Escolha o idioma do app';

  @override
  String get languageChooseSubtitle =>
      'Você pode mudar quando quiser em Perfil › Idioma.';

  @override
  String get languageFollowDevice => 'Usar o idioma do aparelho';

  @override
  String get languageInProgress => 'Tradução em andamento';

  @override
  String get languageChange => 'Mudar idioma';

  @override
  String get languageChangeShort => 'Alterar';

  @override
  String get authTagline => 'Um espaço para cuidar de você.';

  @override
  String get authFooter => 'Sua evolução, no seu ritmo.';

  @override
  String get onboardingWelcomeTitle => 'Vamos montar o seu plano';

  @override
  String get onboardingWelcomeSubtitle =>
      'Responda algumas perguntas rápidas e o PicNutri se ajusta a você. Leva cerca de 2 minutos.';

  @override
  String get onboardingWelcomePhotoTitle => 'Registre por foto';

  @override
  String get onboardingWelcomePhotoText =>
      'Fotografe o prato e veja calorias e macros estimados.';

  @override
  String get onboardingWelcomeGoalsTitle => 'Metas feitas para você';

  @override
  String get onboardingWelcomeGoalsText =>
      'Calorias, proteína e água calculadas com os seus dados.';

  @override
  String get onboardingWelcomeProgressTitle => 'Veja a sua evolução';

  @override
  String get onboardingWelcomeProgressText =>
      'Peso, medidas e hábitos em gráficos simples.';

  @override
  String get actionStart => 'Começar';

  @override
  String get actionStartUsing => 'Começar a usar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSectionAccount => 'Conta';

  @override
  String get profileSectionPreferences => 'Preferências';

  @override
  String get profileSectionHelp => 'Ajuda';

  @override
  String get profileGoals => 'Perfil, objetivo e metas';

  @override
  String profileWater(String amount) {
    return 'Água $amount';
  }

  @override
  String get profileMyPlan => 'Meu plano';

  @override
  String get profileProfessionals => 'Profissionais';

  @override
  String get profileProfessionalsSubtitle =>
      'Encontre nutricionistas e educadores físicos';

  @override
  String get profileTrackMedication => 'Acompanhar medicamento';

  @override
  String get profileTrackMedicationSubtitle =>
      'Registre aplicações prescritas e sintomas na Evolução';

  @override
  String get profileSignInMethods => 'Formas de acesso';

  @override
  String get profileSignInMethodsSubtitle => 'Senha, Google, Facebook e Apple';

  @override
  String get profilePrivacy => 'Privacidade e dados';

  @override
  String get profilePrivacySubtitle =>
      'Autorizações, exportação e exclusão da conta';

  @override
  String get profileNotifications => 'Notificações e lembretes';

  @override
  String get profileNotificationsOn => 'Ativadas neste aparelho';

  @override
  String get profileNotificationsOff => 'Desativadas neste aparelho';

  @override
  String get profileTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get profileAssistant => 'Assistente';

  @override
  String get profileAssistantSubtitle =>
      'Consulte seus registros e tire dúvidas sobre o app';

  @override
  String get profileHelpCenter => 'Central de ajuda';

  @override
  String get profileHelpCenterSubtitle =>
      'Perguntas frequentes e orientações de uso';

  @override
  String get profileServerStatusDev => 'Status do servidor (desenvolvimento)';

  @override
  String get profileLogout => 'Sair';

  @override
  String get profileLogoutConfirmTitle => 'Sair da conta?';

  @override
  String get profileLogoutConfirmMessage =>
      'Você precisará entrar novamente neste aparelho.';

  @override
  String get navHome => 'Início';

  @override
  String get navFood => 'Alimentação';

  @override
  String get navProgress => 'Evolução';

  @override
  String get navContent => 'Conteúdo';

  @override
  String get actionRetry => 'Tentar novamente';

  @override
  String get nutrientCarbs => 'Carboidratos';

  @override
  String get nutrientProtein => 'Proteínas';

  @override
  String get nutrientFat => 'Gorduras';

  @override
  String get mealBreakfast => 'Café da manhã';

  @override
  String get mealMorningSnack => 'Lanche da manhã';

  @override
  String get mealLunch => 'Almoço';

  @override
  String get mealAfternoonSnack => 'Lanche da tarde';

  @override
  String get mealDinner => 'Jantar';

  @override
  String get mealSupper => 'Ceia';

  @override
  String get mealOther => 'Outro';

  @override
  String relToday(String time) {
    return 'hoje, $time';
  }

  @override
  String relTomorrow(String time) {
    return 'amanhã, $time';
  }

  @override
  String relYesterday(String time) {
    return 'ontem, $time';
  }

  @override
  String get homeRegister => 'Registrar';

  @override
  String get homeGoodMorning => 'Bom dia';

  @override
  String get homeGoodAfternoon => 'Boa tarde';

  @override
  String get homeGoodEvening => 'Boa noite';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeTagline => 'Cada pequeno cuidado conta.';

  @override
  String get homeQuickPhoto => 'Fotografar prato';

  @override
  String get homeQuickMeal => 'Refeição';

  @override
  String get homeQuickWater => 'Beber água';

  @override
  String get homeYourProgress => 'Sua evolução';

  @override
  String get homeProgressEmpty => 'Acompanhe seu peso e suas fotos';

  @override
  String homeCurrentWeight(String weight) {
    return 'Peso atual: $weight';
  }

  @override
  String homeNextWater(String amount) {
    return 'Faltam $amount de água';
  }

  @override
  String get homeNextWaterMessage => 'Um copo de cada vez já ajuda.';

  @override
  String get homeLogWater => 'Registrar água';

  @override
  String homeNextProtein(String amount) {
    return 'Faltam $amount de proteínas';
  }

  @override
  String get homeNextProteinMessage =>
      'Veja ideias de receitas com boas fontes de proteína.';

  @override
  String get homeSeeRecipes => 'Ver receitas';

  @override
  String get homeSetGoalsTitle => 'Defina suas metas';

  @override
  String get homeSetGoalsMessage =>
      'Com metas de água e proteínas, o app mostra o que falta a cada dia.';

  @override
  String get homeSetGoalsAction => 'Definir metas';

  @override
  String get homeGoalsReached => 'Metas de água e proteínas alcançadas';

  @override
  String get homeGoalsReachedMessage =>
      'Cada cuidado conta. Continue no seu ritmo.';

  @override
  String homeMealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count refeições',
      one: '1 refeição',
    );
    return '$_temp0';
  }

  @override
  String get homeDayBalance => 'Seu dia em equilíbrio';

  @override
  String homeKcalOfGoal(String kcal, String goal) {
    return '$kcal de $goal';
  }

  @override
  String homeKcalLogged(String kcal) {
    return '$kcal registradas';
  }

  @override
  String homeOfGoal(String goal) {
    return 'de $goal';
  }

  @override
  String get homeKcalLoggedShort => 'kcal registradas';

  @override
  String get homeNoMealsDay => 'Nenhuma refeição registrada neste dia.';

  @override
  String get homeSetYourGoal => 'Defina sua meta';

  @override
  String get homeAboveGoal => ' acima da meta';

  @override
  String get homeToGoal => ' para sua meta';

  @override
  String homeMacroSemanticsGoal(String name, String grams, String goal) {
    return '$name: $grams de $goal gramas';
  }

  @override
  String homeMacroSemantics(String name, String grams) {
    return '$name: $grams gramas';
  }

  @override
  String homeWaterAdded(int ml) {
    return '+$ml ml registrados.';
  }

  @override
  String get homeWaterNoneToday => 'Nenhum registro de água hoje.';

  @override
  String homeWaterRemoved(String amount) {
    return 'Registro de $amount removido.';
  }

  @override
  String get homeHydration => 'Hidratação';

  @override
  String get homeHydrationDetails => 'Detalhes da hidratação';

  @override
  String homeWaterSemantics(String total, String goal, int percent) {
    return 'Água: $total de $goal, $percent% da meta.';
  }

  @override
  String get homeWaterMore => 'Outras quantidades de água';

  @override
  String get homeWaterOther => 'Outra quantidade';

  @override
  String get homeWaterUndo => 'Desfazer o último registro de água';

  @override
  String get homeWeightNone => 'Peso: nenhum registro';

  @override
  String homeWeightValue(String weight) {
    return 'Peso: $weight';
  }

  @override
  String get homeWeight => 'Peso';

  @override
  String get homeNoRecord => 'Sem registro';

  @override
  String get homeWeightHint => 'Registre para acompanhar.';

  @override
  String homeWeightChange(String change) {
    return '$change em 30 dias';
  }

  @override
  String homeWeightGoal(String weight) {
    return 'Meta: $weight';
  }

  @override
  String homeUpdatedOn(String date) {
    return 'Atualizado em $date';
  }

  @override
  String get homeLogWeight => 'Registrar peso';

  @override
  String get homeYourMeals => 'Suas refeições';

  @override
  String get homeSeeAll => 'Ver todas';

  @override
  String get homeMealsError => 'Não foi possível carregar suas refeições.';

  @override
  String get homeMealsEmpty => 'Suas refeições do dia aparecem aqui.';

  @override
  String homeMealLogged(String kcal) {
    return 'Registrado · $kcal';
  }

  @override
  String get homeMealPending => 'Que tal registrar?';

  @override
  String get homeCompleteProfile => 'Complete seu perfil';

  @override
  String homeCompleteProfileMessage(String items) {
    return 'Ficou para depois: $items. Com esses dados, metas e sugestões ficam mais precisas.';
  }

  @override
  String get homeCompleteNow => 'Completar agora';

  @override
  String get skippedEssentials => 'dados básicos';

  @override
  String get skippedRoutine => 'alimentação e rotina';

  @override
  String get skippedGuidance => 'orientação profissional';

  @override
  String get skippedMedication => 'medicamento';

  @override
  String get skippedCare => 'preferências de atendimento';

  @override
  String get skippedTargets => 'metas diárias';

  @override
  String get doseMedication => 'Medicação';

  @override
  String get doseFirstHeadline => 'Registre sua primeira aplicação';

  @override
  String get doseFirstCaption =>
      'A contagem para a próxima começa a partir dela.';

  @override
  String get doseLast => 'Última aplicação';

  @override
  String get doseNoFrequency =>
      'Informe a frequência no cadastro para ver a próxima.';

  @override
  String get doseExpected => 'Aplicação prevista';

  @override
  String get doseExpectedCaption =>
      'Já aplicou? Registre para atualizar a contagem.';

  @override
  String get doseNext => 'Próxima aplicação';

  @override
  String get doseCycle => 'Ciclo entre aplicações';

  @override
  String get doseLastShort => 'Última';

  @override
  String get doseEstimatedLevel => 'Nível estimado';

  @override
  String get doseLog => 'Registrar aplicação';

  @override
  String get doseSetupTitle => 'Cadastre seu medicamento';

  @override
  String get doseSetupText => 'Para ver a contagem até a próxima aplicação.';

  @override
  String get missionsTitle => 'Metas de hoje';

  @override
  String get missionsError => 'Não foi possível carregar suas estrelas.';

  @override
  String get missionsMyAchievement => 'Minha conquista de hoje';

  @override
  String missionsLevelStreak(String level, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias seguidos',
      one: '1 dia seguido',
    );
    return 'Nível $level · $_temp0';
  }

  @override
  String get missionsBroken =>
      'Sua sequência terminou. Vamos começar de novo hoje?';

  @override
  String missionsLevelUp(String level) {
    return 'Parabéns! Você conquistou o nível $level!';
  }

  @override
  String get missionsKeepGoing => 'Cada dia de cuidado vale uma conquista!';

  @override
  String get missionsFirstDay => 'Seu primeiro dia começa com um registro.';

  @override
  String get missionsDiamond => 'Diamante conquistado! Continue sua sequência.';

  @override
  String missionsDaysTo(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count dias para $level',
      one: 'Falta 1 dia para $level',
    );
    return '$_temp0';
  }

  @override
  String missionsRecord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorde: $count dias.',
      one: 'Recorde: 1 dia.',
    );
    return '$_temp0 Um dia sem registro reinicia a sequência.';
  }

  @override
  String get levelBeginner => 'Começo';

  @override
  String get levelBronze => 'Bronze';

  @override
  String get levelSilver => 'Prata';

  @override
  String get levelGold => 'Ouro';

  @override
  String get levelDiamond => 'Diamante';

  @override
  String get activityTitle => 'Atividade física';

  @override
  String get activitySetWeeklyGoal => 'Defina sua meta da semana';

  @override
  String activitySessionsWeek(int done, int goal) {
    return '$done / $goal treinos na semana';
  }

  @override
  String activitySessionsWeekSuffix(int goal) {
    return ' / $goal treinos na semana';
  }

  @override
  String activityWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String get activitySetGoalHint =>
      'Academia, corrida, caminhada... Escolha quantas vezes por semana e o horário.';

  @override
  String get activityCreateGoal => 'Criar meta';

  @override
  String activityMovingWeek(String duration) {
    return '$duration em movimento nesta semana';
  }

  @override
  String get activityLogWorkout => 'Registrar treino';

  @override
  String get whenToday => 'hoje';

  @override
  String get whenTomorrow => 'amanhã';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'em $count dias',
      one: 'em 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notificações, $count não lidas',
      one: 'Notificações, 1 não lida',
    );
    return '$_temp0';
  }

  @override
  String get registerHowTitle => 'Como você quer registrar?';

  @override
  String get registerPhoto => 'Tirar foto do prato';

  @override
  String get registerPhotoSub => 'A IA estima alimentos, porções e macros';

  @override
  String get registerGallery => 'Usar foto da galeria';

  @override
  String get registerGallerySub => 'Escolha uma foto que você já tirou';

  @override
  String get registerDescribe => 'Falar ou escrever';

  @override
  String get registerDescribeSub =>
      'Conte o que comeu; a IA estima e você revisa';

  @override
  String get registerSearch => 'Buscar alimentos';

  @override
  String get registerSearchSub =>
      'No banco de alimentos, pelo código de barras ou informando os valores';

  @override
  String get registerEatAgain => 'Comer de novo';

  @override
  String get registerRecent => 'Recentes';

  @override
  String get registerFavorites => 'Favoritas';

  @override
  String get registerAlso => 'Também registrar';

  @override
  String get registerDose => 'Aplicação';

  @override
  String get registerWorkout => 'Treino';

  @override
  String get registerSymptom => 'Sintoma';

  @override
  String get registerWater => 'Água';
}
