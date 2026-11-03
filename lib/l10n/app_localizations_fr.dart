// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageChooseTitle => 'Choisissez la langue de l\'app';

  @override
  String get languageChooseSubtitle =>
      'Vous pouvez la modifier à tout moment dans Profil › Langue.';

  @override
  String get languageFollowDevice => 'Utiliser la langue de l\'appareil';

  @override
  String get languageInProgress => 'Traduction en cours';

  @override
  String get languageChange => 'Changer de langue';

  @override
  String get languageChangeShort => 'Modifier';

  @override
  String get authTagline => 'Un espace pour prendre soin de vous.';

  @override
  String get authFooter => 'Votre progression, à votre rythme.';

  @override
  String get onboardingWelcomeTitle => 'Construisons votre plan';

  @override
  String get onboardingWelcomeSubtitle =>
      'Répondez à quelques questions rapides et PicNutri s\'adapte à vous. Cela prend environ 2 minutes.';

  @override
  String get onboardingWelcomePhotoTitle => 'Enregistrez en photo';

  @override
  String get onboardingWelcomePhotoText =>
      'Photographiez votre assiette et voyez les calories et macros estimées.';

  @override
  String get onboardingWelcomeGoalsTitle => 'Des objectifs faits pour vous';

  @override
  String get onboardingWelcomeGoalsText =>
      'Calories, protéines et eau calculées à partir de vos données.';

  @override
  String get onboardingWelcomeProgressTitle => 'Suivez votre progression';

  @override
  String get onboardingWelcomeProgressText =>
      'Poids, mensurations et habitudes en graphiques simples.';

  @override
  String get actionStart => 'Commencer';

  @override
  String get actionStartUsing => 'Commencer à utiliser';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileSectionPreferences => 'Préférences';

  @override
  String get profileSectionHelp => 'Aide';

  @override
  String get profileGoals => 'Profil, objectif et cibles';

  @override
  String profileWater(String amount) {
    return 'Eau $amount';
  }

  @override
  String get profileMyPlan => 'Mon abonnement';

  @override
  String get profileProfessionals => 'Professionnels';

  @override
  String get profileProfessionalsSubtitle =>
      'Trouvez des diététiciens et des coachs sportifs';

  @override
  String get profileTrackMedication => 'Suivre un médicament';

  @override
  String get profileTrackMedicationSubtitle =>
      'Enregistrez les prises prescrites et les symptômes dans Progression';

  @override
  String get profileSignInMethods => 'Modes de connexion';

  @override
  String get profileSignInMethodsSubtitle =>
      'Mot de passe, Google, Facebook et Apple';

  @override
  String get profilePrivacy => 'Confidentialité et données';

  @override
  String get profilePrivacySubtitle =>
      'Autorisations, export et suppression du compte';

  @override
  String get profileNotifications => 'Notifications et rappels';

  @override
  String get profileNotificationsOn => 'Activées sur cet appareil';

  @override
  String get profileNotificationsOff => 'Désactivées sur cet appareil';

  @override
  String get profileTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get profileAssistant => 'Assistant';

  @override
  String get profileAssistantSubtitle =>
      'Consultez vos données et posez vos questions sur l\'app';

  @override
  String get profileHelpCenter => 'Centre d\'aide';

  @override
  String get profileHelpCenterSubtitle =>
      'Questions fréquentes et guides d\'utilisation';

  @override
  String get profileServerStatusDev => 'État du serveur (développement)';

  @override
  String get profileLogout => 'Se déconnecter';

  @override
  String get profileLogoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get profileLogoutConfirmMessage =>
      'Vous devrez vous reconnecter sur cet appareil.';

  @override
  String get navHome => 'Accueil';

  @override
  String get navFood => 'Alimentation';

  @override
  String get navProgress => 'Progression';

  @override
  String get navContent => 'Contenu';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get nutrientCarbs => 'Glucides';

  @override
  String get nutrientProtein => 'Protéines';

  @override
  String get nutrientFat => 'Lipides';

  @override
  String get mealBreakfast => 'Petit-déjeuner';

  @override
  String get mealMorningSnack => 'Collation du matin';

  @override
  String get mealLunch => 'Déjeuner';

  @override
  String get mealAfternoonSnack => 'Goûter';

  @override
  String get mealDinner => 'Dîner';

  @override
  String get mealSupper => 'Collation du soir';

  @override
  String get mealOther => 'Autre';

  @override
  String relToday(String time) {
    return 'aujourd\'hui, $time';
  }

  @override
  String relTomorrow(String time) {
    return 'demain, $time';
  }

  @override
  String relYesterday(String time) {
    return 'hier, $time';
  }

  @override
  String get homeRegister => 'Ajouter';

  @override
  String get homeGoodMorning => 'Bonjour';

  @override
  String get homeGoodAfternoon => 'Bon après-midi';

  @override
  String get homeGoodEvening => 'Bonsoir';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeTagline => 'Chaque petit geste compte.';

  @override
  String get homeQuickPhoto => 'Photographier l\'assiette';

  @override
  String get homeQuickMeal => 'Repas';

  @override
  String get homeQuickWater => 'Boire de l\'eau';

  @override
  String get homeYourProgress => 'Votre progression';

  @override
  String get homeProgressEmpty => 'Suivez votre poids et vos photos';

  @override
  String homeCurrentWeight(String weight) {
    return 'Poids actuel : $weight';
  }

  @override
  String homeNextWater(String amount) {
    return 'Encore $amount d\'eau';
  }

  @override
  String get homeNextWaterMessage => 'Un verre à la fois, ça aide déjà.';

  @override
  String get homeLogWater => 'Ajouter de l\'eau';

  @override
  String homeNextProtein(String amount) {
    return 'Encore $amount de protéines';
  }

  @override
  String get homeNextProteinMessage =>
      'Découvrez des idées de recettes riches en protéines.';

  @override
  String get homeSeeRecipes => 'Voir les recettes';

  @override
  String get homeSetGoalsTitle => 'Définissez vos objectifs';

  @override
  String get homeSetGoalsMessage =>
      'Avec des objectifs d\'eau et de protéines, l\'app indique ce qu\'il reste chaque jour.';

  @override
  String get homeSetGoalsAction => 'Définir les objectifs';

  @override
  String get homeGoalsReached => 'Objectifs d\'eau et de protéines atteints';

  @override
  String get homeGoalsReachedMessage =>
      'Chaque geste compte. Continuez à votre rythme.';

  @override
  String homeMealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repas',
      one: '1 repas',
    );
    return '$_temp0';
  }

  @override
  String get homeDayBalance => 'Votre journée en équilibre';

  @override
  String homeKcalOfGoal(String kcal, String goal) {
    return '$kcal sur $goal';
  }

  @override
  String homeKcalLogged(String kcal) {
    return '$kcal enregistrées';
  }

  @override
  String homeOfGoal(String goal) {
    return 'sur $goal';
  }

  @override
  String get homeKcalLoggedShort => 'kcal enregistrées';

  @override
  String get homeNoMealsDay => 'Aucun repas enregistré ce jour-là.';

  @override
  String get homeSetYourGoal => 'Définissez votre objectif';

  @override
  String get homeAboveGoal => ' au-dessus de l\'objectif';

  @override
  String get homeToGoal => ' avant l\'objectif';

  @override
  String homeMacroSemanticsGoal(String name, String grams, String goal) {
    return '$name : $grams sur $goal grammes';
  }

  @override
  String homeMacroSemantics(String name, String grams) {
    return '$name : $grams grammes';
  }

  @override
  String homeWaterAdded(int ml) {
    return '+$ml ml enregistrés.';
  }

  @override
  String get homeWaterNoneToday => 'Aucune eau enregistrée aujourd\'hui.';

  @override
  String homeWaterRemoved(String amount) {
    return 'Entrée de $amount supprimée.';
  }

  @override
  String get homeHydration => 'Hydratation';

  @override
  String get homeHydrationDetails => 'Détails de l\'hydratation';

  @override
  String homeWaterSemantics(String total, String goal, int percent) {
    return 'Eau : $total sur $goal, $percent % de l\'objectif.';
  }

  @override
  String get homeWaterMore => 'Autres quantités d\'eau';

  @override
  String get homeWaterOther => 'Autre quantité';

  @override
  String get homeWaterUndo => 'Annuler la dernière entrée d\'eau';

  @override
  String get homeWeightNone => 'Poids : aucune donnée';

  @override
  String homeWeightValue(String weight) {
    return 'Poids : $weight';
  }

  @override
  String get homeWeight => 'Poids';

  @override
  String get homeNoRecord => 'Aucune donnée';

  @override
  String get homeWeightHint => 'Enregistrez-le pour suivre votre évolution.';

  @override
  String homeWeightChange(String change) {
    return '$change en 30 jours';
  }

  @override
  String homeWeightGoal(String weight) {
    return 'Objectif : $weight';
  }

  @override
  String homeUpdatedOn(String date) {
    return 'Mis à jour le $date';
  }

  @override
  String get homeLogWeight => 'Ajouter le poids';

  @override
  String get homeYourMeals => 'Vos repas';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String get homeMealsError => 'Impossible de charger vos repas.';

  @override
  String get homeMealsEmpty => 'Vos repas du jour s\'affichent ici.';

  @override
  String homeMealLogged(String kcal) {
    return 'Enregistré · $kcal';
  }

  @override
  String get homeMealPending => 'On l\'enregistre ?';

  @override
  String get homeCompleteProfile => 'Complétez votre profil';

  @override
  String homeCompleteProfileMessage(String items) {
    return 'Laissé pour plus tard : $items. Avec ces informations, objectifs et suggestions sont plus précis.';
  }

  @override
  String get homeCompleteNow => 'Compléter maintenant';

  @override
  String get skippedEssentials => 'informations de base';

  @override
  String get skippedRoutine => 'alimentation et routine';

  @override
  String get skippedGuidance => 'suivi professionnel';

  @override
  String get skippedMedication => 'médicament';

  @override
  String get skippedCare => 'préférences de suivi';

  @override
  String get skippedTargets => 'objectifs quotidiens';

  @override
  String get doseMedication => 'Traitement';

  @override
  String get doseFirstHeadline => 'Enregistrez votre première prise';

  @override
  String get doseFirstCaption =>
      'Le compte à rebours jusqu\'à la prochaine commence à partir de celle-ci.';

  @override
  String get doseLast => 'Dernière prise';

  @override
  String get doseNoFrequency =>
      'Indiquez la fréquence pour voir la prochaine prise.';

  @override
  String get doseExpected => 'Prise prévue';

  @override
  String get doseExpectedCaption =>
      'Déjà prise ? Enregistrez-la pour mettre à jour le compte à rebours.';

  @override
  String get doseNext => 'Prochaine prise';

  @override
  String get doseCycle => 'Cycle entre les prises';

  @override
  String get doseLastShort => 'Dernière';

  @override
  String get doseEstimatedLevel => 'Niveau estimé';

  @override
  String get doseLog => 'Enregistrer une prise';

  @override
  String get doseSetupTitle => 'Ajoutez votre médicament';

  @override
  String get doseSetupText =>
      'Pour voir le compte à rebours jusqu\'à la prochaine prise.';

  @override
  String get missionsTitle => 'Objectifs du jour';

  @override
  String get missionsError => 'Impossible de charger vos étoiles.';

  @override
  String get missionsMyAchievement => 'Ma réussite du jour';

  @override
  String missionsLevelStreak(String level, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours d\'affilée',
      one: '1 jour d\'affilée',
    );
    return 'Niveau $level · $_temp0';
  }

  @override
  String get missionsBroken =>
      'Votre série s\'est arrêtée. On recommence aujourd\'hui ?';

  @override
  String missionsLevelUp(String level) {
    return 'Bravo ! Vous avez atteint le niveau $level !';
  }

  @override
  String get missionsKeepGoing =>
      'Chaque jour de soin compte comme une réussite !';

  @override
  String get missionsFirstDay =>
      'Votre premier jour commence par un enregistrement.';

  @override
  String get missionsDiamond => 'Diamant obtenu ! Continuez votre série.';

  @override
  String missionsDaysTo(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Plus que $count jours avant $level',
      one: 'Plus qu\'1 jour avant $level',
    );
    return '$_temp0';
  }

  @override
  String missionsRecord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Record : $count jours.',
      one: 'Record : 1 jour.',
    );
    return '$_temp0 Un jour sans enregistrement remet la série à zéro.';
  }

  @override
  String get levelBeginner => 'Débutant';

  @override
  String get levelBronze => 'Bronze';

  @override
  String get levelSilver => 'Argent';

  @override
  String get levelGold => 'Or';

  @override
  String get levelDiamond => 'Diamant';

  @override
  String get activityTitle => 'Activité physique';

  @override
  String get activitySetWeeklyGoal => 'Définissez votre objectif de la semaine';

  @override
  String activitySessionsWeek(int done, int goal) {
    return '$done / $goal séances cette semaine';
  }

  @override
  String activitySessionsWeekSuffix(int goal) {
    return ' / $goal séances cette semaine';
  }

  @override
  String activityWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '1 semaine',
    );
    return '$_temp0';
  }

  @override
  String get activitySetGoalHint =>
      'Salle, course, marche... Choisissez combien de fois par semaine et à quelle heure.';

  @override
  String get activityCreateGoal => 'Créer un objectif';

  @override
  String activityMovingWeek(String duration) {
    return '$duration en mouvement cette semaine';
  }

  @override
  String get activityLogWorkout => 'Enregistrer une séance';

  @override
  String get whenToday => 'aujourd\'hui';

  @override
  String get whenTomorrow => 'demain';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count jours',
      one: 'dans 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count non lues',
      one: 'Notifications, 1 non lue',
    );
    return '$_temp0';
  }

  @override
  String get registerHowTitle => 'Comment voulez-vous l\'enregistrer ?';

  @override
  String get registerPhoto => 'Prendre l\'assiette en photo';

  @override
  String get registerPhotoSub =>
      'L\'IA estime les aliments, portions et macros';

  @override
  String get registerGallery => 'Utiliser une photo de la galerie';

  @override
  String get registerGallerySub => 'Choisissez une photo déjà prise';

  @override
  String get registerDescribe => 'Dire ou écrire';

  @override
  String get registerDescribeSub =>
      'Dites ce que vous avez mangé ; l\'IA estime et vous vérifiez';

  @override
  String get registerSearch => 'Rechercher des aliments';

  @override
  String get registerSearchSub =>
      'Dans la base d\'aliments, par code-barres ou en saisissant les valeurs';

  @override
  String get registerEatAgain => 'Manger à nouveau';

  @override
  String get registerRecent => 'Récents';

  @override
  String get registerFavorites => 'Favoris';

  @override
  String get registerAlso => 'Enregistrer aussi';

  @override
  String get registerDose => 'Prise';

  @override
  String get registerWorkout => 'Séance';

  @override
  String get registerSymptom => 'Symptôme';

  @override
  String get registerWater => 'Eau';
}
