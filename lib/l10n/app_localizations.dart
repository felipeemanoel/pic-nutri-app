import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// Título da seção/folha de idioma
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// Título da folha de seleção
  ///
  /// In pt, this message translates to:
  /// **'Escolha o idioma do app'**
  String get languageChooseTitle;

  /// Subtítulo da folha de seleção
  ///
  /// In pt, this message translates to:
  /// **'Você pode mudar quando quiser em Perfil › Idioma.'**
  String get languageChooseSubtitle;

  /// Opção que segue o idioma do sistema
  ///
  /// In pt, this message translates to:
  /// **'Usar o idioma do aparelho'**
  String get languageFollowDevice;

  /// Aviso em idiomas ainda não concluídos
  ///
  /// In pt, this message translates to:
  /// **'Tradução em andamento'**
  String get languageInProgress;

  /// Rótulo/tooltip do botão de idioma
  ///
  /// In pt, this message translates to:
  /// **'Mudar idioma'**
  String get languageChange;

  /// Ação curta ao lado do idioma atual
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get languageChangeShort;

  /// Frase abaixo da marca nas telas de conta
  ///
  /// In pt, this message translates to:
  /// **'Um espaço para cuidar de você.'**
  String get authTagline;

  /// Rodapé das telas de conta
  ///
  /// In pt, this message translates to:
  /// **'Sua evolução, no seu ritmo.'**
  String get authFooter;

  /// Título da primeira tela do cadastro
  ///
  /// In pt, this message translates to:
  /// **'Vamos montar o seu plano'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Responda algumas perguntas rápidas e o PicNutri se ajusta a você. Leva cerca de 2 minutos.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingWelcomePhotoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registre por foto'**
  String get onboardingWelcomePhotoTitle;

  /// No description provided for @onboardingWelcomePhotoText.
  ///
  /// In pt, this message translates to:
  /// **'Fotografe o prato e veja calorias e macros estimados.'**
  String get onboardingWelcomePhotoText;

  /// No description provided for @onboardingWelcomeGoalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas feitas para você'**
  String get onboardingWelcomeGoalsTitle;

  /// No description provided for @onboardingWelcomeGoalsText.
  ///
  /// In pt, this message translates to:
  /// **'Calorias, proteína e água calculadas com os seus dados.'**
  String get onboardingWelcomeGoalsText;

  /// No description provided for @onboardingWelcomeProgressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Veja a sua evolução'**
  String get onboardingWelcomeProgressTitle;

  /// No description provided for @onboardingWelcomeProgressText.
  ///
  /// In pt, this message translates to:
  /// **'Peso, medidas e hábitos em gráficos simples.'**
  String get onboardingWelcomeProgressText;

  /// Botão da primeira tela do cadastro
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get actionStart;

  /// Botão da última tela do cadastro
  ///
  /// In pt, this message translates to:
  /// **'Começar a usar'**
  String get actionStartUsing;

  /// No description provided for @actionContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get actionContinue;

  /// Título da aba Perfil
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileSectionAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionPreferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get profileSectionPreferences;

  /// No description provided for @profileSectionHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get profileSectionHelp;

  /// No description provided for @profileGoals.
  ///
  /// In pt, this message translates to:
  /// **'Perfil, objetivo e metas'**
  String get profileGoals;

  /// Meta de água no resumo do perfil
  ///
  /// In pt, this message translates to:
  /// **'Água {amount}'**
  String profileWater(String amount);

  /// Assinatura (plano pago)
  ///
  /// In pt, this message translates to:
  /// **'Meu plano'**
  String get profileMyPlan;

  /// No description provided for @profileProfessionals.
  ///
  /// In pt, this message translates to:
  /// **'Profissionais'**
  String get profileProfessionals;

  /// No description provided for @profileProfessionalsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Encontre nutricionistas e educadores físicos'**
  String get profileProfessionalsSubtitle;

  /// No description provided for @profileTrackMedication.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhar medicamento'**
  String get profileTrackMedication;

  /// No description provided for @profileTrackMedicationSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Registre aplicações prescritas e sintomas na Evolução'**
  String get profileTrackMedicationSubtitle;

  /// No description provided for @profileSignInMethods.
  ///
  /// In pt, this message translates to:
  /// **'Formas de acesso'**
  String get profileSignInMethods;

  /// No description provided for @profileSignInMethodsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Senha, Google, Facebook e Apple'**
  String get profileSignInMethodsSubtitle;

  /// No description provided for @profilePrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade e dados'**
  String get profilePrivacy;

  /// No description provided for @profilePrivacySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Autorizações, exportação e exclusão da conta'**
  String get profilePrivacySubtitle;

  /// No description provided for @profileNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações e lembretes'**
  String get profileNotifications;

  /// No description provided for @profileNotificationsOn.
  ///
  /// In pt, this message translates to:
  /// **'Ativadas neste aparelho'**
  String get profileNotificationsOn;

  /// No description provided for @profileNotificationsOff.
  ///
  /// In pt, this message translates to:
  /// **'Desativadas neste aparelho'**
  String get profileNotificationsOff;

  /// No description provided for @profileTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get profileTheme;

  /// No description provided for @themeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @profileAssistant.
  ///
  /// In pt, this message translates to:
  /// **'Assistente'**
  String get profileAssistant;

  /// No description provided for @profileAssistantSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Consulte seus registros e tire dúvidas sobre o app'**
  String get profileAssistantSubtitle;

  /// No description provided for @profileHelpCenter.
  ///
  /// In pt, this message translates to:
  /// **'Central de ajuda'**
  String get profileHelpCenter;

  /// No description provided for @profileHelpCenterSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Perguntas frequentes e orientações de uso'**
  String get profileHelpCenterSubtitle;

  /// No description provided for @profileServerStatusDev.
  ///
  /// In pt, this message translates to:
  /// **'Status do servidor (desenvolvimento)'**
  String get profileServerStatusDev;

  /// No description provided for @profileLogout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta?'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você precisará entrar novamente neste aparelho.'**
  String get profileLogoutConfirmMessage;

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navFood.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get navFood;

  /// No description provided for @navProgress.
  ///
  /// In pt, this message translates to:
  /// **'Evolução'**
  String get navProgress;

  /// No description provided for @navContent.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo'**
  String get navContent;

  /// No description provided for @actionRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get actionRetry;

  /// No description provided for @nutrientCarbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidratos'**
  String get nutrientCarbs;

  /// No description provided for @nutrientProtein.
  ///
  /// In pt, this message translates to:
  /// **'Proteínas'**
  String get nutrientProtein;

  /// No description provided for @nutrientFat.
  ///
  /// In pt, this message translates to:
  /// **'Gorduras'**
  String get nutrientFat;

  /// No description provided for @mealBreakfast.
  ///
  /// In pt, this message translates to:
  /// **'Café da manhã'**
  String get mealBreakfast;

  /// No description provided for @mealMorningSnack.
  ///
  /// In pt, this message translates to:
  /// **'Lanche da manhã'**
  String get mealMorningSnack;

  /// No description provided for @mealLunch.
  ///
  /// In pt, this message translates to:
  /// **'Almoço'**
  String get mealLunch;

  /// No description provided for @mealAfternoonSnack.
  ///
  /// In pt, this message translates to:
  /// **'Lanche da tarde'**
  String get mealAfternoonSnack;

  /// No description provided for @mealDinner.
  ///
  /// In pt, this message translates to:
  /// **'Jantar'**
  String get mealDinner;

  /// No description provided for @mealSupper.
  ///
  /// In pt, this message translates to:
  /// **'Ceia'**
  String get mealSupper;

  /// No description provided for @mealOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get mealOther;

  /// No description provided for @relToday.
  ///
  /// In pt, this message translates to:
  /// **'hoje, {time}'**
  String relToday(String time);

  /// No description provided for @relTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'amanhã, {time}'**
  String relTomorrow(String time);

  /// No description provided for @relYesterday.
  ///
  /// In pt, this message translates to:
  /// **'ontem, {time}'**
  String relYesterday(String time);

  /// No description provided for @homeRegister.
  ///
  /// In pt, this message translates to:
  /// **'Registrar'**
  String get homeRegister;

  /// No description provided for @homeGoodMorning.
  ///
  /// In pt, this message translates to:
  /// **'Bom dia'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Boa tarde'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In pt, this message translates to:
  /// **'Boa noite'**
  String get homeGoodEvening;

  /// No description provided for @homeGreetingName.
  ///
  /// In pt, this message translates to:
  /// **'{greeting}, {name}'**
  String homeGreetingName(String greeting, String name);

  /// No description provided for @homeTagline.
  ///
  /// In pt, this message translates to:
  /// **'Cada pequeno cuidado conta.'**
  String get homeTagline;

  /// No description provided for @homeQuickPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Fotografar prato'**
  String get homeQuickPhoto;

  /// No description provided for @homeQuickMeal.
  ///
  /// In pt, this message translates to:
  /// **'Refeição'**
  String get homeQuickMeal;

  /// No description provided for @homeQuickWater.
  ///
  /// In pt, this message translates to:
  /// **'Beber água'**
  String get homeQuickWater;

  /// No description provided for @homeYourProgress.
  ///
  /// In pt, this message translates to:
  /// **'Sua evolução'**
  String get homeYourProgress;

  /// No description provided for @homeProgressEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe seu peso e suas fotos'**
  String get homeProgressEmpty;

  /// No description provided for @homeCurrentWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso atual: {weight}'**
  String homeCurrentWeight(String weight);

  /// No description provided for @homeNextWater.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount} de água'**
  String homeNextWater(String amount);

  /// No description provided for @homeNextWaterMessage.
  ///
  /// In pt, this message translates to:
  /// **'Um copo de cada vez já ajuda.'**
  String get homeNextWaterMessage;

  /// No description provided for @homeLogWater.
  ///
  /// In pt, this message translates to:
  /// **'Registrar água'**
  String get homeLogWater;

  /// No description provided for @homeNextProtein.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount} de proteínas'**
  String homeNextProtein(String amount);

  /// No description provided for @homeNextProteinMessage.
  ///
  /// In pt, this message translates to:
  /// **'Veja ideias de receitas com boas fontes de proteína.'**
  String get homeNextProteinMessage;

  /// No description provided for @homeSeeRecipes.
  ///
  /// In pt, this message translates to:
  /// **'Ver receitas'**
  String get homeSeeRecipes;

  /// No description provided for @homeSetGoalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Defina suas metas'**
  String get homeSetGoalsTitle;

  /// No description provided for @homeSetGoalsMessage.
  ///
  /// In pt, this message translates to:
  /// **'Com metas de água e proteínas, o app mostra o que falta a cada dia.'**
  String get homeSetGoalsMessage;

  /// No description provided for @homeSetGoalsAction.
  ///
  /// In pt, this message translates to:
  /// **'Definir metas'**
  String get homeSetGoalsAction;

  /// No description provided for @homeGoalsReached.
  ///
  /// In pt, this message translates to:
  /// **'Metas de água e proteínas alcançadas'**
  String get homeGoalsReached;

  /// No description provided for @homeGoalsReachedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Cada cuidado conta. Continue no seu ritmo.'**
  String get homeGoalsReachedMessage;

  /// No description provided for @homeMealsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 refeição} other{{count} refeições}}'**
  String homeMealsCount(int count);

  /// No description provided for @homeDayBalance.
  ///
  /// In pt, this message translates to:
  /// **'Seu dia em equilíbrio'**
  String get homeDayBalance;

  /// No description provided for @homeKcalOfGoal.
  ///
  /// In pt, this message translates to:
  /// **'{kcal} de {goal}'**
  String homeKcalOfGoal(String kcal, String goal);

  /// No description provided for @homeKcalLogged.
  ///
  /// In pt, this message translates to:
  /// **'{kcal} registradas'**
  String homeKcalLogged(String kcal);

  /// No description provided for @homeOfGoal.
  ///
  /// In pt, this message translates to:
  /// **'de {goal}'**
  String homeOfGoal(String goal);

  /// No description provided for @homeKcalLoggedShort.
  ///
  /// In pt, this message translates to:
  /// **'kcal registradas'**
  String get homeKcalLoggedShort;

  /// No description provided for @homeNoMealsDay.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma refeição registrada neste dia.'**
  String get homeNoMealsDay;

  /// No description provided for @homeSetYourGoal.
  ///
  /// In pt, this message translates to:
  /// **'Defina sua meta'**
  String get homeSetYourGoal;

  /// No description provided for @homeAboveGoal.
  ///
  /// In pt, this message translates to:
  /// **' acima da meta'**
  String get homeAboveGoal;

  /// No description provided for @homeToGoal.
  ///
  /// In pt, this message translates to:
  /// **' para sua meta'**
  String get homeToGoal;

  /// No description provided for @homeMacroSemanticsGoal.
  ///
  /// In pt, this message translates to:
  /// **'{name}: {grams} de {goal} gramas'**
  String homeMacroSemanticsGoal(String name, String grams, String goal);

  /// No description provided for @homeMacroSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{name}: {grams} gramas'**
  String homeMacroSemantics(String name, String grams);

  /// No description provided for @homeWaterAdded.
  ///
  /// In pt, this message translates to:
  /// **'+{ml} ml registrados.'**
  String homeWaterAdded(int ml);

  /// No description provided for @homeWaterNoneToday.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro de água hoje.'**
  String get homeWaterNoneToday;

  /// No description provided for @homeWaterRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Registro de {amount} removido.'**
  String homeWaterRemoved(String amount);

  /// No description provided for @homeHydration.
  ///
  /// In pt, this message translates to:
  /// **'Hidratação'**
  String get homeHydration;

  /// No description provided for @homeHydrationDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da hidratação'**
  String get homeHydrationDetails;

  /// No description provided for @homeWaterSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Água: {total} de {goal}, {percent}% da meta.'**
  String homeWaterSemantics(String total, String goal, int percent);

  /// No description provided for @homeWaterMore.
  ///
  /// In pt, this message translates to:
  /// **'Outras quantidades de água'**
  String get homeWaterMore;

  /// No description provided for @homeWaterOther.
  ///
  /// In pt, this message translates to:
  /// **'Outra quantidade'**
  String get homeWaterOther;

  /// No description provided for @homeWaterUndo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer o último registro de água'**
  String get homeWaterUndo;

  /// No description provided for @homeWeightNone.
  ///
  /// In pt, this message translates to:
  /// **'Peso: nenhum registro'**
  String get homeWeightNone;

  /// No description provided for @homeWeightValue.
  ///
  /// In pt, this message translates to:
  /// **'Peso: {weight}'**
  String homeWeightValue(String weight);

  /// No description provided for @homeWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get homeWeight;

  /// No description provided for @homeNoRecord.
  ///
  /// In pt, this message translates to:
  /// **'Sem registro'**
  String get homeNoRecord;

  /// No description provided for @homeWeightHint.
  ///
  /// In pt, this message translates to:
  /// **'Registre para acompanhar.'**
  String get homeWeightHint;

  /// No description provided for @homeWeightChange.
  ///
  /// In pt, this message translates to:
  /// **'{change} em 30 dias'**
  String homeWeightChange(String change);

  /// No description provided for @homeWeightGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta: {weight}'**
  String homeWeightGoal(String weight);

  /// No description provided for @homeUpdatedOn.
  ///
  /// In pt, this message translates to:
  /// **'Atualizado em {date}'**
  String homeUpdatedOn(String date);

  /// No description provided for @homeLogWeight.
  ///
  /// In pt, this message translates to:
  /// **'Registrar peso'**
  String get homeLogWeight;

  /// No description provided for @homeYourMeals.
  ///
  /// In pt, this message translates to:
  /// **'Suas refeições'**
  String get homeYourMeals;

  /// No description provided for @homeSeeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas'**
  String get homeSeeAll;

  /// No description provided for @homeMealsError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar suas refeições.'**
  String get homeMealsError;

  /// No description provided for @homeMealsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Suas refeições do dia aparecem aqui.'**
  String get homeMealsEmpty;

  /// No description provided for @homeMealLogged.
  ///
  /// In pt, this message translates to:
  /// **'Registrado · {kcal}'**
  String homeMealLogged(String kcal);

  /// No description provided for @homeMealPending.
  ///
  /// In pt, this message translates to:
  /// **'Que tal registrar?'**
  String get homeMealPending;

  /// No description provided for @homeCompleteProfile.
  ///
  /// In pt, this message translates to:
  /// **'Complete seu perfil'**
  String get homeCompleteProfile;

  /// No description provided for @homeCompleteProfileMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ficou para depois: {items}. Com esses dados, metas e sugestões ficam mais precisas.'**
  String homeCompleteProfileMessage(String items);

  /// No description provided for @homeCompleteNow.
  ///
  /// In pt, this message translates to:
  /// **'Completar agora'**
  String get homeCompleteNow;

  /// No description provided for @skippedEssentials.
  ///
  /// In pt, this message translates to:
  /// **'dados básicos'**
  String get skippedEssentials;

  /// No description provided for @skippedRoutine.
  ///
  /// In pt, this message translates to:
  /// **'alimentação e rotina'**
  String get skippedRoutine;

  /// No description provided for @skippedGuidance.
  ///
  /// In pt, this message translates to:
  /// **'orientação profissional'**
  String get skippedGuidance;

  /// No description provided for @skippedMedication.
  ///
  /// In pt, this message translates to:
  /// **'medicamento'**
  String get skippedMedication;

  /// No description provided for @skippedCare.
  ///
  /// In pt, this message translates to:
  /// **'preferências de atendimento'**
  String get skippedCare;

  /// No description provided for @skippedTargets.
  ///
  /// In pt, this message translates to:
  /// **'metas diárias'**
  String get skippedTargets;

  /// No description provided for @doseMedication.
  ///
  /// In pt, this message translates to:
  /// **'Medicação'**
  String get doseMedication;

  /// No description provided for @doseFirstHeadline.
  ///
  /// In pt, this message translates to:
  /// **'Registre sua primeira aplicação'**
  String get doseFirstHeadline;

  /// No description provided for @doseFirstCaption.
  ///
  /// In pt, this message translates to:
  /// **'A contagem para a próxima começa a partir dela.'**
  String get doseFirstCaption;

  /// No description provided for @doseLast.
  ///
  /// In pt, this message translates to:
  /// **'Última aplicação'**
  String get doseLast;

  /// No description provided for @doseNoFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Informe a frequência no cadastro para ver a próxima.'**
  String get doseNoFrequency;

  /// No description provided for @doseExpected.
  ///
  /// In pt, this message translates to:
  /// **'Aplicação prevista'**
  String get doseExpected;

  /// No description provided for @doseExpectedCaption.
  ///
  /// In pt, this message translates to:
  /// **'Já aplicou? Registre para atualizar a contagem.'**
  String get doseExpectedCaption;

  /// No description provided for @doseNext.
  ///
  /// In pt, this message translates to:
  /// **'Próxima aplicação'**
  String get doseNext;

  /// No description provided for @doseCycle.
  ///
  /// In pt, this message translates to:
  /// **'Ciclo entre aplicações'**
  String get doseCycle;

  /// No description provided for @doseLastShort.
  ///
  /// In pt, this message translates to:
  /// **'Última'**
  String get doseLastShort;

  /// No description provided for @doseEstimatedLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível estimado'**
  String get doseEstimatedLevel;

  /// No description provided for @doseLog.
  ///
  /// In pt, this message translates to:
  /// **'Registrar aplicação'**
  String get doseLog;

  /// No description provided for @doseSetupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre seu medicamento'**
  String get doseSetupTitle;

  /// No description provided for @doseSetupText.
  ///
  /// In pt, this message translates to:
  /// **'Para ver a contagem até a próxima aplicação.'**
  String get doseSetupText;

  /// No description provided for @missionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas de hoje'**
  String get missionsTitle;

  /// No description provided for @missionsError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar suas estrelas.'**
  String get missionsError;

  /// No description provided for @missionsMyAchievement.
  ///
  /// In pt, this message translates to:
  /// **'Minha conquista de hoje'**
  String get missionsMyAchievement;

  /// No description provided for @missionsLevelStreak.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level} · {count, plural, =1{1 dia seguido} other{{count} dias seguidos}}'**
  String missionsLevelStreak(String level, int count);

  /// No description provided for @missionsBroken.
  ///
  /// In pt, this message translates to:
  /// **'Sua sequência terminou. Vamos começar de novo hoje?'**
  String get missionsBroken;

  /// No description provided for @missionsLevelUp.
  ///
  /// In pt, this message translates to:
  /// **'Parabéns! Você conquistou o nível {level}!'**
  String missionsLevelUp(String level);

  /// No description provided for @missionsKeepGoing.
  ///
  /// In pt, this message translates to:
  /// **'Cada dia de cuidado vale uma conquista!'**
  String get missionsKeepGoing;

  /// No description provided for @missionsFirstDay.
  ///
  /// In pt, this message translates to:
  /// **'Seu primeiro dia começa com um registro.'**
  String get missionsFirstDay;

  /// No description provided for @missionsDiamond.
  ///
  /// In pt, this message translates to:
  /// **'Diamante conquistado! Continue sua sequência.'**
  String get missionsDiamond;

  /// No description provided for @missionsDaysTo.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Falta 1 dia para {level}} other{Faltam {count} dias para {level}}}'**
  String missionsDaysTo(int count, String level);

  /// No description provided for @missionsRecord.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Recorde: 1 dia.} other{Recorde: {count} dias.}} Um dia sem registro reinicia a sequência.'**
  String missionsRecord(int count);

  /// No description provided for @levelBeginner.
  ///
  /// In pt, this message translates to:
  /// **'Começo'**
  String get levelBeginner;

  /// No description provided for @levelBronze.
  ///
  /// In pt, this message translates to:
  /// **'Bronze'**
  String get levelBronze;

  /// No description provided for @levelSilver.
  ///
  /// In pt, this message translates to:
  /// **'Prata'**
  String get levelSilver;

  /// No description provided for @levelGold.
  ///
  /// In pt, this message translates to:
  /// **'Ouro'**
  String get levelGold;

  /// No description provided for @levelDiamond.
  ///
  /// In pt, this message translates to:
  /// **'Diamante'**
  String get levelDiamond;

  /// No description provided for @activityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividade física'**
  String get activityTitle;

  /// No description provided for @activitySetWeeklyGoal.
  ///
  /// In pt, this message translates to:
  /// **'Defina sua meta da semana'**
  String get activitySetWeeklyGoal;

  /// No description provided for @activitySessionsWeek.
  ///
  /// In pt, this message translates to:
  /// **'{done} / {goal} treinos na semana'**
  String activitySessionsWeek(int done, int goal);

  /// No description provided for @activitySessionsWeekSuffix.
  ///
  /// In pt, this message translates to:
  /// **' / {goal} treinos na semana'**
  String activitySessionsWeekSuffix(int goal);

  /// No description provided for @activityWeeks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 semana} other{{count} semanas}}'**
  String activityWeeks(int count);

  /// No description provided for @activitySetGoalHint.
  ///
  /// In pt, this message translates to:
  /// **'Academia, corrida, caminhada... Escolha quantas vezes por semana e o horário.'**
  String get activitySetGoalHint;

  /// No description provided for @activityCreateGoal.
  ///
  /// In pt, this message translates to:
  /// **'Criar meta'**
  String get activityCreateGoal;

  /// No description provided for @activityMovingWeek.
  ///
  /// In pt, this message translates to:
  /// **'{duration} em movimento nesta semana'**
  String activityMovingWeek(String duration);

  /// No description provided for @activityLogWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Registrar treino'**
  String get activityLogWorkout;

  /// No description provided for @whenToday.
  ///
  /// In pt, this message translates to:
  /// **'hoje'**
  String get whenToday;

  /// No description provided for @whenTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'amanhã'**
  String get whenTomorrow;

  /// No description provided for @whenInDays.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{em 1 dia} other{em {count} dias}}'**
  String whenInDays(int count);

  /// No description provided for @notificationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationsTitle;

  /// No description provided for @notificationsUnread.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Notificações, 1 não lida} other{Notificações, {count} não lidas}}'**
  String notificationsUnread(int count);

  /// No description provided for @registerHowTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como você quer registrar?'**
  String get registerHowTitle;

  /// No description provided for @registerPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto do prato'**
  String get registerPhoto;

  /// No description provided for @registerPhotoSub.
  ///
  /// In pt, this message translates to:
  /// **'A IA estima alimentos, porções e macros'**
  String get registerPhotoSub;

  /// No description provided for @registerGallery.
  ///
  /// In pt, this message translates to:
  /// **'Usar foto da galeria'**
  String get registerGallery;

  /// No description provided for @registerGallerySub.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma foto que você já tirou'**
  String get registerGallerySub;

  /// No description provided for @registerDescribe.
  ///
  /// In pt, this message translates to:
  /// **'Falar ou escrever'**
  String get registerDescribe;

  /// No description provided for @registerDescribeSub.
  ///
  /// In pt, this message translates to:
  /// **'Conte o que comeu; a IA estima e você revisa'**
  String get registerDescribeSub;

  /// No description provided for @registerSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar alimentos'**
  String get registerSearch;

  /// No description provided for @registerSearchSub.
  ///
  /// In pt, this message translates to:
  /// **'No banco de alimentos, pelo código de barras ou informando os valores'**
  String get registerSearchSub;

  /// No description provided for @registerEatAgain.
  ///
  /// In pt, this message translates to:
  /// **'Comer de novo'**
  String get registerEatAgain;

  /// No description provided for @registerRecent.
  ///
  /// In pt, this message translates to:
  /// **'Recentes'**
  String get registerRecent;

  /// No description provided for @registerFavorites.
  ///
  /// In pt, this message translates to:
  /// **'Favoritas'**
  String get registerFavorites;

  /// No description provided for @registerAlso.
  ///
  /// In pt, this message translates to:
  /// **'Também registrar'**
  String get registerAlso;

  /// No description provided for @registerDose.
  ///
  /// In pt, this message translates to:
  /// **'Aplicação'**
  String get registerDose;

  /// No description provided for @registerWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get registerWorkout;

  /// No description provided for @registerSymptom.
  ///
  /// In pt, this message translates to:
  /// **'Sintoma'**
  String get registerSymptom;

  /// No description provided for @registerWater.
  ///
  /// In pt, this message translates to:
  /// **'Água'**
  String get registerWater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
