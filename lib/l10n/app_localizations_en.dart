// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageTitle => 'Language';

  @override
  String get languageChooseTitle => 'Choose the app language';

  @override
  String get languageChooseSubtitle =>
      'You can change it anytime in Profile › Language.';

  @override
  String get languageFollowDevice => 'Use device language';

  @override
  String get languageInProgress => 'Translation in progress';

  @override
  String get languageChange => 'Change language';

  @override
  String get languageChangeShort => 'Change';

  @override
  String get authTagline => 'A space to take care of yourself.';

  @override
  String get authFooter => 'Your progress, at your pace.';

  @override
  String get onboardingWelcomeTitle => 'Let\'s build your plan';

  @override
  String get onboardingWelcomeSubtitle =>
      'Answer a few quick questions and PicNutri adapts to you. It takes about 2 minutes.';

  @override
  String get onboardingWelcomePhotoTitle => 'Log by photo';

  @override
  String get onboardingWelcomePhotoText =>
      'Snap your plate and see estimated calories and macros.';

  @override
  String get onboardingWelcomeGoalsTitle => 'Goals made for you';

  @override
  String get onboardingWelcomeGoalsText =>
      'Calories, protein and water calculated from your data.';

  @override
  String get onboardingWelcomeProgressTitle => 'See your progress';

  @override
  String get onboardingWelcomeProgressText =>
      'Weight, measurements and habits in simple charts.';

  @override
  String get actionStart => 'Get started';

  @override
  String get actionStartUsing => 'Start using';

  @override
  String get actionContinue => 'Continue';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileSectionHelp => 'Help';

  @override
  String get profileGoals => 'Profile, goal and targets';

  @override
  String profileWater(String amount) {
    return 'Water $amount';
  }

  @override
  String get profileMyPlan => 'My plan';

  @override
  String get profileProfessionals => 'Professionals';

  @override
  String get profileProfessionalsSubtitle =>
      'Find dietitians and fitness professionals';

  @override
  String get profileTrackMedication => 'Track medication';

  @override
  String get profileTrackMedicationSubtitle =>
      'Log prescribed doses and symptoms in Progress';

  @override
  String get profileSignInMethods => 'Sign-in methods';

  @override
  String get profileSignInMethodsSubtitle =>
      'Password, Google, Facebook and Apple';

  @override
  String get profilePrivacy => 'Privacy and data';

  @override
  String get profilePrivacySubtitle =>
      'Permissions, export and account deletion';

  @override
  String get profileNotifications => 'Notifications and reminders';

  @override
  String get profileNotificationsOn => 'On for this device';

  @override
  String get profileNotificationsOff => 'Off for this device';

  @override
  String get profileTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get profileAssistant => 'Assistant';

  @override
  String get profileAssistantSubtitle =>
      'Check your logs and ask questions about the app';

  @override
  String get profileHelpCenter => 'Help center';

  @override
  String get profileHelpCenterSubtitle => 'FAQs and how-to guides';

  @override
  String get profileServerStatusDev => 'Server status (development)';

  @override
  String get profileLogout => 'Sign out';

  @override
  String get profileLogoutConfirmTitle => 'Sign out?';

  @override
  String get profileLogoutConfirmMessage =>
      'You\'ll need to sign in again on this device.';

  @override
  String get navHome => 'Home';

  @override
  String get navFood => 'Food';

  @override
  String get navProgress => 'Progress';

  @override
  String get navContent => 'Content';

  @override
  String get actionRetry => 'Try again';

  @override
  String get nutrientCarbs => 'Carbs';

  @override
  String get nutrientProtein => 'Protein';

  @override
  String get nutrientFat => 'Fat';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealMorningSnack => 'Morning snack';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealAfternoonSnack => 'Afternoon snack';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSupper => 'Late snack';

  @override
  String get mealOther => 'Other';

  @override
  String relToday(String time) {
    return 'today, $time';
  }

  @override
  String relTomorrow(String time) {
    return 'tomorrow, $time';
  }

  @override
  String relYesterday(String time) {
    return 'yesterday, $time';
  }

  @override
  String get homeRegister => 'Log';

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeGoodAfternoon => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeTagline => 'Every bit of care counts.';

  @override
  String get homeQuickPhoto => 'Snap your plate';

  @override
  String get homeQuickMeal => 'Meal';

  @override
  String get homeQuickWater => 'Drink water';

  @override
  String get homeYourProgress => 'Your progress';

  @override
  String get homeProgressEmpty => 'Track your weight and photos';

  @override
  String homeCurrentWeight(String weight) {
    return 'Current weight: $weight';
  }

  @override
  String homeNextWater(String amount) {
    return '$amount of water to go';
  }

  @override
  String get homeNextWaterMessage => 'One glass at a time helps.';

  @override
  String get homeLogWater => 'Log water';

  @override
  String homeNextProtein(String amount) {
    return '$amount of protein to go';
  }

  @override
  String get homeNextProteinMessage =>
      'See recipe ideas with good protein sources.';

  @override
  String get homeSeeRecipes => 'See recipes';

  @override
  String get homeSetGoalsTitle => 'Set your goals';

  @override
  String get homeSetGoalsMessage =>
      'With water and protein goals, the app shows what\'s left each day.';

  @override
  String get homeSetGoalsAction => 'Set goals';

  @override
  String get homeGoalsReached => 'Water and protein goals reached';

  @override
  String get homeGoalsReachedMessage =>
      'Every bit of care counts. Keep going at your pace.';

  @override
  String homeMealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meals',
      one: '1 meal',
    );
    return '$_temp0';
  }

  @override
  String get homeDayBalance => 'Your day in balance';

  @override
  String homeKcalOfGoal(String kcal, String goal) {
    return '$kcal of $goal';
  }

  @override
  String homeKcalLogged(String kcal) {
    return '$kcal logged';
  }

  @override
  String homeOfGoal(String goal) {
    return 'of $goal';
  }

  @override
  String get homeKcalLoggedShort => 'kcal logged';

  @override
  String get homeNoMealsDay => 'No meals logged on this day.';

  @override
  String get homeSetYourGoal => 'Set your goal';

  @override
  String get homeAboveGoal => ' over goal';

  @override
  String get homeToGoal => ' to your goal';

  @override
  String homeMacroSemanticsGoal(String name, String grams, String goal) {
    return '$name: $grams of $goal grams';
  }

  @override
  String homeMacroSemantics(String name, String grams) {
    return '$name: $grams grams';
  }

  @override
  String homeWaterAdded(int ml) {
    return '+$ml ml logged.';
  }

  @override
  String get homeWaterNoneToday => 'No water logged today.';

  @override
  String homeWaterRemoved(String amount) {
    return '$amount entry removed.';
  }

  @override
  String get homeHydration => 'Hydration';

  @override
  String get homeHydrationDetails => 'Hydration details';

  @override
  String homeWaterSemantics(String total, String goal, int percent) {
    return 'Water: $total of $goal, $percent% of goal.';
  }

  @override
  String get homeWaterMore => 'Other water amounts';

  @override
  String get homeWaterOther => 'Other amount';

  @override
  String get homeWaterUndo => 'Undo last water entry';

  @override
  String get homeWeightNone => 'Weight: no entries';

  @override
  String homeWeightValue(String weight) {
    return 'Weight: $weight';
  }

  @override
  String get homeWeight => 'Weight';

  @override
  String get homeNoRecord => 'No entry';

  @override
  String get homeWeightHint => 'Log it to track your progress.';

  @override
  String homeWeightChange(String change) {
    return '$change in 30 days';
  }

  @override
  String homeWeightGoal(String weight) {
    return 'Goal: $weight';
  }

  @override
  String homeUpdatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String get homeLogWeight => 'Log weight';

  @override
  String get homeYourMeals => 'Your meals';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeMealsError => 'Couldn\'t load your meals.';

  @override
  String get homeMealsEmpty => 'Your meals for the day show up here.';

  @override
  String homeMealLogged(String kcal) {
    return 'Logged · $kcal';
  }

  @override
  String get homeMealPending => 'Want to log it?';

  @override
  String get homeCompleteProfile => 'Complete your profile';

  @override
  String homeCompleteProfileMessage(String items) {
    return 'Left for later: $items. With this information, goals and suggestions are more accurate.';
  }

  @override
  String get homeCompleteNow => 'Complete now';

  @override
  String get skippedEssentials => 'basic details';

  @override
  String get skippedRoutine => 'eating and routine';

  @override
  String get skippedGuidance => 'professional guidance';

  @override
  String get skippedMedication => 'medication';

  @override
  String get skippedCare => 'care preferences';

  @override
  String get skippedTargets => 'daily targets';

  @override
  String get doseMedication => 'Medication';

  @override
  String get doseFirstHeadline => 'Log your first dose';

  @override
  String get doseFirstCaption =>
      'The countdown to the next one starts from it.';

  @override
  String get doseLast => 'Last dose';

  @override
  String get doseNoFrequency =>
      'Add the frequency to your medication to see the next one.';

  @override
  String get doseExpected => 'Dose due';

  @override
  String get doseExpectedCaption =>
      'Already taken? Log it to update the countdown.';

  @override
  String get doseNext => 'Next dose';

  @override
  String get doseCycle => 'Cycle between doses';

  @override
  String get doseLastShort => 'Last';

  @override
  String get doseEstimatedLevel => 'Estimated level';

  @override
  String get doseLog => 'Log dose';

  @override
  String get doseSetupTitle => 'Add your medication';

  @override
  String get doseSetupText => 'To see the countdown to your next dose.';

  @override
  String get missionsTitle => 'Today\'s goals';

  @override
  String get missionsError => 'Couldn\'t load your stars.';

  @override
  String get missionsMyAchievement => 'My achievement today';

  @override
  String missionsLevelStreak(String level, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return 'Level $level · $_temp0';
  }

  @override
  String get missionsBroken => 'Your streak ended. Shall we start again today?';

  @override
  String missionsLevelUp(String level) {
    return 'Congrats! You reached the $level level!';
  }

  @override
  String get missionsKeepGoing => 'Every day of care earns an achievement!';

  @override
  String get missionsFirstDay => 'Your first day starts with one entry.';

  @override
  String get missionsDiamond => 'Diamond reached! Keep your streak going.';

  @override
  String missionsDaysTo(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days to $level',
      one: '1 day to $level',
    );
    return '$_temp0';
  }

  @override
  String missionsRecord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Best: $count days.',
      one: 'Best: 1 day.',
    );
    return '$_temp0 A day without entries resets the streak.';
  }

  @override
  String get levelBeginner => 'Starter';

  @override
  String get levelBronze => 'Bronze';

  @override
  String get levelSilver => 'Silver';

  @override
  String get levelGold => 'Gold';

  @override
  String get levelDiamond => 'Diamond';

  @override
  String get activityTitle => 'Physical activity';

  @override
  String get activitySetWeeklyGoal => 'Set your weekly goal';

  @override
  String activitySessionsWeek(int done, int goal) {
    return '$done / $goal workouts this week';
  }

  @override
  String activitySessionsWeekSuffix(int goal) {
    return ' / $goal workouts this week';
  }

  @override
  String activityWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get activitySetGoalHint =>
      'Gym, running, walking... Choose how many times a week and when.';

  @override
  String get activityCreateGoal => 'Create goal';

  @override
  String activityMovingWeek(String duration) {
    return '$duration active this week';
  }

  @override
  String get activityLogWorkout => 'Log workout';

  @override
  String get whenToday => 'today';

  @override
  String get whenTomorrow => 'tomorrow';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
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
      other: 'Notifications, $count unread',
      one: 'Notifications, 1 unread',
    );
    return '$_temp0';
  }

  @override
  String get registerHowTitle => 'How do you want to log it?';

  @override
  String get registerPhoto => 'Take a photo of your plate';

  @override
  String get registerPhotoSub => 'AI estimates foods, portions and macros';

  @override
  String get registerGallery => 'Use a photo from gallery';

  @override
  String get registerGallerySub => 'Pick a photo you already took';

  @override
  String get registerDescribe => 'Speak or type';

  @override
  String get registerDescribeSub =>
      'Tell us what you ate; AI estimates and you review';

  @override
  String get registerSearch => 'Search foods';

  @override
  String get registerSearchSub =>
      'In the food database, by barcode or by entering values';

  @override
  String get registerEatAgain => 'Eat again';

  @override
  String get registerRecent => 'Recent';

  @override
  String get registerFavorites => 'Favorites';

  @override
  String get registerAlso => 'Also log';

  @override
  String get registerDose => 'Dose';

  @override
  String get registerWorkout => 'Workout';

  @override
  String get registerSymptom => 'Symptom';

  @override
  String get registerWater => 'Water';
}
