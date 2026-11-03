// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageChooseTitle => 'Wähle die App-Sprache';

  @override
  String get languageChooseSubtitle =>
      'Du kannst sie jederzeit unter Profil › Sprache ändern.';

  @override
  String get languageFollowDevice => 'Gerätesprache verwenden';

  @override
  String get languageInProgress => 'Übersetzung in Arbeit';

  @override
  String get languageChange => 'Sprache ändern';

  @override
  String get languageChangeShort => 'Ändern';

  @override
  String get authTagline => 'Ein Ort, um auf dich zu achten.';

  @override
  String get authFooter => 'Dein Fortschritt, in deinem Tempo.';

  @override
  String get onboardingWelcomeTitle => 'Lass uns deinen Plan erstellen';

  @override
  String get onboardingWelcomeSubtitle =>
      'Beantworte ein paar kurze Fragen und PicNutri passt sich an dich an. Das dauert etwa 2 Minuten.';

  @override
  String get onboardingWelcomePhotoTitle => 'Per Foto erfassen';

  @override
  String get onboardingWelcomePhotoText =>
      'Fotografiere deinen Teller und sieh geschätzte Kalorien und Makros.';

  @override
  String get onboardingWelcomeGoalsTitle => 'Ziele, die zu dir passen';

  @override
  String get onboardingWelcomeGoalsText =>
      'Kalorien, Protein und Wasser, berechnet aus deinen Daten.';

  @override
  String get onboardingWelcomeProgressTitle => 'Sieh deinen Fortschritt';

  @override
  String get onboardingWelcomeProgressText =>
      'Gewicht, Maße und Gewohnheiten in einfachen Diagrammen.';

  @override
  String get actionStart => 'Los geht\'s';

  @override
  String get actionStartUsing => 'Jetzt starten';

  @override
  String get actionContinue => 'Weiter';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSectionAccount => 'Konto';

  @override
  String get profileSectionPreferences => 'Einstellungen';

  @override
  String get profileSectionHelp => 'Hilfe';

  @override
  String get profileGoals => 'Profil, Ziel und Vorgaben';

  @override
  String profileWater(String amount) {
    return 'Wasser $amount';
  }

  @override
  String get profileMyPlan => 'Mein Tarif';

  @override
  String get profileProfessionals => 'Fachleute';

  @override
  String get profileProfessionalsSubtitle =>
      'Finde Ernährungsberater und Fitnessprofis';

  @override
  String get profileTrackMedication => 'Medikament verfolgen';

  @override
  String get profileTrackMedicationSubtitle =>
      'Erfasse verschriebene Anwendungen und Symptome unter Fortschritt';

  @override
  String get profileSignInMethods => 'Anmeldemethoden';

  @override
  String get profileSignInMethodsSubtitle =>
      'Passwort, Google, Facebook und Apple';

  @override
  String get profilePrivacy => 'Datenschutz und Daten';

  @override
  String get profilePrivacySubtitle =>
      'Einwilligungen, Export und Kontolöschung';

  @override
  String get profileNotifications => 'Benachrichtigungen und Erinnerungen';

  @override
  String get profileNotificationsOn => 'Auf diesem Gerät aktiviert';

  @override
  String get profileNotificationsOff => 'Auf diesem Gerät deaktiviert';

  @override
  String get profileTheme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get profileAssistant => 'Assistent';

  @override
  String get profileAssistantSubtitle =>
      'Sieh deine Einträge ein und stelle Fragen zur App';

  @override
  String get profileHelpCenter => 'Hilfe-Center';

  @override
  String get profileHelpCenterSubtitle => 'Häufige Fragen und Anleitungen';

  @override
  String get profileServerStatusDev => 'Serverstatus (Entwicklung)';

  @override
  String get profileLogout => 'Abmelden';

  @override
  String get profileLogoutConfirmTitle => 'Abmelden?';

  @override
  String get profileLogoutConfirmMessage =>
      'Du musst dich auf diesem Gerät erneut anmelden.';

  @override
  String get navHome => 'Start';

  @override
  String get navFood => 'Ernährung';

  @override
  String get navProgress => 'Fortschritt';

  @override
  String get navContent => 'Inhalte';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get nutrientCarbs => 'Kohlenhydrate';

  @override
  String get nutrientProtein => 'Eiweiß';

  @override
  String get nutrientFat => 'Fett';

  @override
  String get mealBreakfast => 'Frühstück';

  @override
  String get mealMorningSnack => 'Vormittagssnack';

  @override
  String get mealLunch => 'Mittagessen';

  @override
  String get mealAfternoonSnack => 'Nachmittagssnack';

  @override
  String get mealDinner => 'Abendessen';

  @override
  String get mealSupper => 'Spätmahlzeit';

  @override
  String get mealOther => 'Sonstiges';

  @override
  String relToday(String time) {
    return 'heute, $time';
  }

  @override
  String relTomorrow(String time) {
    return 'morgen, $time';
  }

  @override
  String relYesterday(String time) {
    return 'gestern, $time';
  }

  @override
  String get homeRegister => 'Erfassen';

  @override
  String get homeGoodMorning => 'Guten Morgen';

  @override
  String get homeGoodAfternoon => 'Guten Tag';

  @override
  String get homeGoodEvening => 'Guten Abend';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeTagline => 'Jede kleine Fürsorge zählt.';

  @override
  String get homeQuickPhoto => 'Teller fotografieren';

  @override
  String get homeQuickMeal => 'Mahlzeit';

  @override
  String get homeQuickWater => 'Wasser trinken';

  @override
  String get homeYourProgress => 'Dein Fortschritt';

  @override
  String get homeProgressEmpty => 'Verfolge dein Gewicht und deine Fotos';

  @override
  String homeCurrentWeight(String weight) {
    return 'Aktuelles Gewicht: $weight';
  }

  @override
  String homeNextWater(String amount) {
    return 'Noch $amount Wasser';
  }

  @override
  String get homeNextWaterMessage => 'Ein Glas nach dem anderen hilft schon.';

  @override
  String get homeLogWater => 'Wasser erfassen';

  @override
  String homeNextProtein(String amount) {
    return 'Noch $amount Eiweiß';
  }

  @override
  String get homeNextProteinMessage =>
      'Entdecke Rezeptideen mit guten Eiweißquellen.';

  @override
  String get homeSeeRecipes => 'Rezepte ansehen';

  @override
  String get homeSetGoalsTitle => 'Lege deine Ziele fest';

  @override
  String get homeSetGoalsMessage =>
      'Mit Wasser- und Eiweißzielen zeigt die App, was dir jeden Tag noch fehlt.';

  @override
  String get homeSetGoalsAction => 'Ziele festlegen';

  @override
  String get homeGoalsReached => 'Wasser- und Eiweißziele erreicht';

  @override
  String get homeGoalsReachedMessage =>
      'Jede Fürsorge zählt. Mach in deinem Tempo weiter.';

  @override
  String homeMealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mahlzeiten',
      one: '1 Mahlzeit',
    );
    return '$_temp0';
  }

  @override
  String get homeDayBalance => 'Dein Tag im Gleichgewicht';

  @override
  String homeKcalOfGoal(String kcal, String goal) {
    return '$kcal von $goal';
  }

  @override
  String homeKcalLogged(String kcal) {
    return '$kcal erfasst';
  }

  @override
  String homeOfGoal(String goal) {
    return 'von $goal';
  }

  @override
  String get homeKcalLoggedShort => 'kcal erfasst';

  @override
  String get homeNoMealsDay => 'An diesem Tag wurde keine Mahlzeit erfasst.';

  @override
  String get homeSetYourGoal => 'Lege dein Ziel fest';

  @override
  String get homeAboveGoal => ' über dem Ziel';

  @override
  String get homeToGoal => ' bis zum Ziel';

  @override
  String homeMacroSemanticsGoal(String name, String grams, String goal) {
    return '$name: $grams von $goal Gramm';
  }

  @override
  String homeMacroSemantics(String name, String grams) {
    return '$name: $grams Gramm';
  }

  @override
  String homeWaterAdded(int ml) {
    return '+$ml ml erfasst.';
  }

  @override
  String get homeWaterNoneToday => 'Heute noch kein Wasser erfasst.';

  @override
  String homeWaterRemoved(String amount) {
    return 'Eintrag über $amount entfernt.';
  }

  @override
  String get homeHydration => 'Flüssigkeit';

  @override
  String get homeHydrationDetails => 'Details zur Flüssigkeit';

  @override
  String homeWaterSemantics(String total, String goal, int percent) {
    return 'Wasser: $total von $goal, $percent % des Ziels.';
  }

  @override
  String get homeWaterMore => 'Andere Wassermengen';

  @override
  String get homeWaterOther => 'Andere Menge';

  @override
  String get homeWaterUndo => 'Letzten Wassereintrag rückgängig machen';

  @override
  String get homeWeightNone => 'Gewicht: kein Eintrag';

  @override
  String homeWeightValue(String weight) {
    return 'Gewicht: $weight';
  }

  @override
  String get homeWeight => 'Gewicht';

  @override
  String get homeNoRecord => 'Kein Eintrag';

  @override
  String get homeWeightHint => 'Erfasse es, um es zu verfolgen.';

  @override
  String homeWeightChange(String change) {
    return '$change in 30 Tagen';
  }

  @override
  String homeWeightGoal(String weight) {
    return 'Ziel: $weight';
  }

  @override
  String homeUpdatedOn(String date) {
    return 'Aktualisiert am $date';
  }

  @override
  String get homeLogWeight => 'Gewicht erfassen';

  @override
  String get homeYourMeals => 'Deine Mahlzeiten';

  @override
  String get homeSeeAll => 'Alle ansehen';

  @override
  String get homeMealsError => 'Deine Mahlzeiten konnten nicht geladen werden.';

  @override
  String get homeMealsEmpty => 'Deine Mahlzeiten des Tages erscheinen hier.';

  @override
  String homeMealLogged(String kcal) {
    return 'Erfasst · $kcal';
  }

  @override
  String get homeMealPending => 'Jetzt erfassen?';

  @override
  String get homeCompleteProfile => 'Vervollständige dein Profil';

  @override
  String homeCompleteProfileMessage(String items) {
    return 'Für später aufgehoben: $items. Mit diesen Angaben werden Ziele und Vorschläge genauer.';
  }

  @override
  String get homeCompleteNow => 'Jetzt vervollständigen';

  @override
  String get skippedEssentials => 'Grunddaten';

  @override
  String get skippedRoutine => 'Ernährung und Alltag';

  @override
  String get skippedGuidance => 'fachliche Begleitung';

  @override
  String get skippedMedication => 'Medikament';

  @override
  String get skippedCare => 'Betreuungswünsche';

  @override
  String get skippedTargets => 'Tagesziele';

  @override
  String get doseMedication => 'Medikation';

  @override
  String get doseFirstHeadline => 'Erfasse deine erste Anwendung';

  @override
  String get doseFirstCaption =>
      'Der Countdown bis zur nächsten beginnt ab dann.';

  @override
  String get doseLast => 'Letzte Anwendung';

  @override
  String get doseNoFrequency =>
      'Gib die Häufigkeit an, um die nächste zu sehen.';

  @override
  String get doseExpected => 'Anwendung fällig';

  @override
  String get doseExpectedCaption =>
      'Schon angewendet? Erfasse es, um den Countdown zu aktualisieren.';

  @override
  String get doseNext => 'Nächste Anwendung';

  @override
  String get doseCycle => 'Zyklus zwischen Anwendungen';

  @override
  String get doseLastShort => 'Letzte';

  @override
  String get doseEstimatedLevel => 'Geschätzter Spiegel';

  @override
  String get doseLog => 'Anwendung erfassen';

  @override
  String get doseSetupTitle => 'Füge dein Medikament hinzu';

  @override
  String get doseSetupText =>
      'Um den Countdown bis zur nächsten Anwendung zu sehen.';

  @override
  String get missionsTitle => 'Ziele für heute';

  @override
  String get missionsError => 'Deine Sterne konnten nicht geladen werden.';

  @override
  String get missionsMyAchievement => 'Mein Erfolg heute';

  @override
  String missionsLevelStreak(String level, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage in Folge',
      one: '1 Tag in Folge',
    );
    return 'Stufe $level · $_temp0';
  }

  @override
  String get missionsBroken =>
      'Deine Serie ist vorbei. Fangen wir heute neu an?';

  @override
  String missionsLevelUp(String level) {
    return 'Glückwunsch! Du hast die Stufe $level erreicht!';
  }

  @override
  String get missionsKeepGoing => 'Jeder Tag mit Fürsorge ist ein Erfolg!';

  @override
  String get missionsFirstDay => 'Dein erster Tag beginnt mit einem Eintrag.';

  @override
  String get missionsDiamond => 'Diamant erreicht! Setz deine Serie fort.';

  @override
  String missionsDaysTo(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Tage bis $level',
      one: 'Noch 1 Tag bis $level',
    );
    return '$_temp0';
  }

  @override
  String missionsRecord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rekord: $count Tage.',
      one: 'Rekord: 1 Tag.',
    );
    return '$_temp0 Ein Tag ohne Eintrag setzt die Serie zurück.';
  }

  @override
  String get levelBeginner => 'Einstieg';

  @override
  String get levelBronze => 'Bronze';

  @override
  String get levelSilver => 'Silber';

  @override
  String get levelGold => 'Gold';

  @override
  String get levelDiamond => 'Diamant';

  @override
  String get activityTitle => 'Bewegung';

  @override
  String get activitySetWeeklyGoal => 'Lege dein Wochenziel fest';

  @override
  String activitySessionsWeek(int done, int goal) {
    return '$done / $goal Trainings diese Woche';
  }

  @override
  String activitySessionsWeekSuffix(int goal) {
    return ' / $goal Trainings diese Woche';
  }

  @override
  String activityWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wochen',
      one: '1 Woche',
    );
    return '$_temp0';
  }

  @override
  String get activitySetGoalHint =>
      'Fitnessstudio, Laufen, Spazieren... Wähle, wie oft pro Woche und wann.';

  @override
  String get activityCreateGoal => 'Ziel erstellen';

  @override
  String activityMovingWeek(String duration) {
    return '$duration in Bewegung diese Woche';
  }

  @override
  String get activityLogWorkout => 'Training erfassen';

  @override
  String get whenToday => 'heute';

  @override
  String get whenTomorrow => 'morgen';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count Tagen',
      one: 'in 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Benachrichtigungen, $count ungelesen',
      one: 'Benachrichtigungen, 1 ungelesen',
    );
    return '$_temp0';
  }

  @override
  String get registerHowTitle => 'Wie möchtest du es erfassen?';

  @override
  String get registerPhoto => 'Teller fotografieren';

  @override
  String get registerPhotoSub =>
      'Die KI schätzt Lebensmittel, Portionen und Makros';

  @override
  String get registerGallery => 'Foto aus der Galerie verwenden';

  @override
  String get registerGallerySub => 'Wähle ein Foto, das du schon gemacht hast';

  @override
  String get registerDescribe => 'Sprechen oder schreiben';

  @override
  String get registerDescribeSub =>
      'Erzähl, was du gegessen hast; die KI schätzt und du prüfst';

  @override
  String get registerSearch => 'Lebensmittel suchen';

  @override
  String get registerSearchSub =>
      'In der Lebensmitteldatenbank, per Barcode oder mit eigenen Werten';

  @override
  String get registerEatAgain => 'Nochmal essen';

  @override
  String get registerRecent => 'Zuletzt';

  @override
  String get registerFavorites => 'Favoriten';

  @override
  String get registerAlso => 'Außerdem erfassen';

  @override
  String get registerDose => 'Anwendung';

  @override
  String get registerWorkout => 'Training';

  @override
  String get registerSymptom => 'Symptom';

  @override
  String get registerWater => 'Wasser';
}
