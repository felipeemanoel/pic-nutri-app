// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageChooseTitle => 'Elige el idioma de la app';

  @override
  String get languageChooseSubtitle =>
      'Puedes cambiarlo cuando quieras en Perfil › Idioma.';

  @override
  String get languageFollowDevice => 'Usar el idioma del dispositivo';

  @override
  String get languageInProgress => 'Traducción en curso';

  @override
  String get languageChange => 'Cambiar idioma';

  @override
  String get languageChangeShort => 'Cambiar';

  @override
  String get authTagline => 'Un espacio para cuidarte.';

  @override
  String get authFooter => 'Tu evolución, a tu ritmo.';

  @override
  String get onboardingWelcomeTitle => 'Vamos a armar tu plan';

  @override
  String get onboardingWelcomeSubtitle =>
      'Responde unas preguntas rápidas y PicNutri se adapta a ti. Toma unos 2 minutos.';

  @override
  String get onboardingWelcomePhotoTitle => 'Registra con una foto';

  @override
  String get onboardingWelcomePhotoText =>
      'Fotografía tu plato y ve las calorías y macros estimadas.';

  @override
  String get onboardingWelcomeGoalsTitle => 'Metas hechas para ti';

  @override
  String get onboardingWelcomeGoalsText =>
      'Calorías, proteína y agua calculadas con tus datos.';

  @override
  String get onboardingWelcomeProgressTitle => 'Mira tu evolución';

  @override
  String get onboardingWelcomeProgressText =>
      'Peso, medidas y hábitos en gráficos sencillos.';

  @override
  String get actionStart => 'Empezar';

  @override
  String get actionStartUsing => 'Empezar a usar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSectionAccount => 'Cuenta';

  @override
  String get profileSectionPreferences => 'Preferencias';

  @override
  String get profileSectionHelp => 'Ayuda';

  @override
  String get profileGoals => 'Perfil, objetivo y metas';

  @override
  String profileWater(String amount) {
    return 'Agua $amount';
  }

  @override
  String get profileMyPlan => 'Mi plan';

  @override
  String get profileProfessionals => 'Profesionales';

  @override
  String get profileProfessionalsSubtitle =>
      'Encuentra nutricionistas y profesionales de educación física';

  @override
  String get profileTrackMedication => 'Seguir medicamento';

  @override
  String get profileTrackMedicationSubtitle =>
      'Registra aplicaciones prescritas y síntomas en Evolución';

  @override
  String get profileSignInMethods => 'Formas de acceso';

  @override
  String get profileSignInMethodsSubtitle =>
      'Contraseña, Google, Facebook y Apple';

  @override
  String get profilePrivacy => 'Privacidad y datos';

  @override
  String get profilePrivacySubtitle =>
      'Autorizaciones, exportación y eliminación de la cuenta';

  @override
  String get profileNotifications => 'Notificaciones y recordatorios';

  @override
  String get profileNotificationsOn => 'Activadas en este dispositivo';

  @override
  String get profileNotificationsOff => 'Desactivadas en este dispositivo';

  @override
  String get profileTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get profileAssistant => 'Asistente';

  @override
  String get profileAssistantSubtitle =>
      'Consulta tus registros y resuelve dudas sobre la app';

  @override
  String get profileHelpCenter => 'Centro de ayuda';

  @override
  String get profileHelpCenterSubtitle => 'Preguntas frecuentes y guías de uso';

  @override
  String get profileServerStatusDev => 'Estado del servidor (desarrollo)';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get profileLogoutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get profileLogoutConfirmMessage =>
      'Tendrás que volver a iniciar sesión en este dispositivo.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navFood => 'Alimentación';

  @override
  String get navProgress => 'Evolución';

  @override
  String get navContent => 'Contenido';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get nutrientCarbs => 'Carbohidratos';

  @override
  String get nutrientProtein => 'Proteínas';

  @override
  String get nutrientFat => 'Grasas';

  @override
  String get mealBreakfast => 'Desayuno';

  @override
  String get mealMorningSnack => 'Merienda de la mañana';

  @override
  String get mealLunch => 'Almuerzo';

  @override
  String get mealAfternoonSnack => 'Merienda';

  @override
  String get mealDinner => 'Cena';

  @override
  String get mealSupper => 'Recena';

  @override
  String get mealOther => 'Otro';

  @override
  String relToday(String time) {
    return 'hoy, $time';
  }

  @override
  String relTomorrow(String time) {
    return 'mañana, $time';
  }

  @override
  String relYesterday(String time) {
    return 'ayer, $time';
  }

  @override
  String get homeRegister => 'Registrar';

  @override
  String get homeGoodMorning => 'Buenos días';

  @override
  String get homeGoodAfternoon => 'Buenas tardes';

  @override
  String get homeGoodEvening => 'Buenas noches';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeTagline => 'Cada pequeño cuidado cuenta.';

  @override
  String get homeQuickPhoto => 'Fotografiar plato';

  @override
  String get homeQuickMeal => 'Comida';

  @override
  String get homeQuickWater => 'Beber agua';

  @override
  String get homeYourProgress => 'Tu evolución';

  @override
  String get homeProgressEmpty => 'Sigue tu peso y tus fotos';

  @override
  String homeCurrentWeight(String weight) {
    return 'Peso actual: $weight';
  }

  @override
  String homeNextWater(String amount) {
    return 'Faltan $amount de agua';
  }

  @override
  String get homeNextWaterMessage => 'Un vaso a la vez ya ayuda.';

  @override
  String get homeLogWater => 'Registrar agua';

  @override
  String homeNextProtein(String amount) {
    return 'Faltan $amount de proteínas';
  }

  @override
  String get homeNextProteinMessage =>
      'Mira ideas de recetas con buenas fuentes de proteína.';

  @override
  String get homeSeeRecipes => 'Ver recetas';

  @override
  String get homeSetGoalsTitle => 'Define tus metas';

  @override
  String get homeSetGoalsMessage =>
      'Con metas de agua y proteínas, la app muestra lo que falta cada día.';

  @override
  String get homeSetGoalsAction => 'Definir metas';

  @override
  String get homeGoalsReached => 'Metas de agua y proteínas alcanzadas';

  @override
  String get homeGoalsReachedMessage =>
      'Cada cuidado cuenta. Sigue a tu ritmo.';

  @override
  String homeMealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comidas',
      one: '1 comida',
    );
    return '$_temp0';
  }

  @override
  String get homeDayBalance => 'Tu día en equilibrio';

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
  String get homeNoMealsDay => 'Ninguna comida registrada este día.';

  @override
  String get homeSetYourGoal => 'Define tu meta';

  @override
  String get homeAboveGoal => ' por encima de la meta';

  @override
  String get homeToGoal => ' para tu meta';

  @override
  String homeMacroSemanticsGoal(String name, String grams, String goal) {
    return '$name: $grams de $goal gramos';
  }

  @override
  String homeMacroSemantics(String name, String grams) {
    return '$name: $grams gramos';
  }

  @override
  String homeWaterAdded(int ml) {
    return '+$ml ml registrados.';
  }

  @override
  String get homeWaterNoneToday => 'Ningún registro de agua hoy.';

  @override
  String homeWaterRemoved(String amount) {
    return 'Registro de $amount eliminado.';
  }

  @override
  String get homeHydration => 'Hidratación';

  @override
  String get homeHydrationDetails => 'Detalles de hidratación';

  @override
  String homeWaterSemantics(String total, String goal, int percent) {
    return 'Agua: $total de $goal, $percent% de la meta.';
  }

  @override
  String get homeWaterMore => 'Otras cantidades de agua';

  @override
  String get homeWaterOther => 'Otra cantidad';

  @override
  String get homeWaterUndo => 'Deshacer el último registro de agua';

  @override
  String get homeWeightNone => 'Peso: sin registros';

  @override
  String homeWeightValue(String weight) {
    return 'Peso: $weight';
  }

  @override
  String get homeWeight => 'Peso';

  @override
  String get homeNoRecord => 'Sin registro';

  @override
  String get homeWeightHint => 'Regístralo para hacer seguimiento.';

  @override
  String homeWeightChange(String change) {
    return '$change en 30 días';
  }

  @override
  String homeWeightGoal(String weight) {
    return 'Meta: $weight';
  }

  @override
  String homeUpdatedOn(String date) {
    return 'Actualizado el $date';
  }

  @override
  String get homeLogWeight => 'Registrar peso';

  @override
  String get homeYourMeals => 'Tus comidas';

  @override
  String get homeSeeAll => 'Ver todas';

  @override
  String get homeMealsError => 'No se pudieron cargar tus comidas.';

  @override
  String get homeMealsEmpty => 'Tus comidas del día aparecen aquí.';

  @override
  String homeMealLogged(String kcal) {
    return 'Registrado · $kcal';
  }

  @override
  String get homeMealPending => '¿Lo registras?';

  @override
  String get homeCompleteProfile => 'Completa tu perfil';

  @override
  String homeCompleteProfileMessage(String items) {
    return 'Quedó pendiente: $items. Con estos datos, las metas y sugerencias son más precisas.';
  }

  @override
  String get homeCompleteNow => 'Completar ahora';

  @override
  String get skippedEssentials => 'datos básicos';

  @override
  String get skippedRoutine => 'alimentación y rutina';

  @override
  String get skippedGuidance => 'orientación profesional';

  @override
  String get skippedMedication => 'medicamento';

  @override
  String get skippedCare => 'preferencias de atención';

  @override
  String get skippedTargets => 'metas diarias';

  @override
  String get doseMedication => 'Medicación';

  @override
  String get doseFirstHeadline => 'Registra tu primera aplicación';

  @override
  String get doseFirstCaption =>
      'La cuenta para la próxima empieza desde ella.';

  @override
  String get doseLast => 'Última aplicación';

  @override
  String get doseNoFrequency =>
      'Indica la frecuencia en el registro para ver la próxima.';

  @override
  String get doseExpected => 'Aplicación prevista';

  @override
  String get doseExpectedCaption =>
      '¿Ya la aplicaste? Regístrala para actualizar la cuenta.';

  @override
  String get doseNext => 'Próxima aplicación';

  @override
  String get doseCycle => 'Ciclo entre aplicaciones';

  @override
  String get doseLastShort => 'Última';

  @override
  String get doseEstimatedLevel => 'Nivel estimado';

  @override
  String get doseLog => 'Registrar aplicación';

  @override
  String get doseSetupTitle => 'Registra tu medicamento';

  @override
  String get doseSetupText => 'Para ver la cuenta hasta la próxima aplicación.';

  @override
  String get missionsTitle => 'Metas de hoy';

  @override
  String get missionsError => 'No se pudieron cargar tus estrellas.';

  @override
  String get missionsMyAchievement => 'Mi logro de hoy';

  @override
  String missionsLevelStreak(String level, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días seguidos',
      one: '1 día seguido',
    );
    return 'Nivel $level · $_temp0';
  }

  @override
  String get missionsBroken => 'Tu racha terminó. ¿Empezamos de nuevo hoy?';

  @override
  String missionsLevelUp(String level) {
    return '¡Felicidades! ¡Alcanzaste el nivel $level!';
  }

  @override
  String get missionsKeepGoing => '¡Cada día de cuidado vale un logro!';

  @override
  String get missionsFirstDay => 'Tu primer día empieza con un registro.';

  @override
  String get missionsDiamond => '¡Diamante conseguido! Sigue con tu racha.';

  @override
  String missionsDaysTo(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan $count días para $level',
      one: 'Falta 1 día para $level',
    );
    return '$_temp0';
  }

  @override
  String missionsRecord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Récord: $count días.',
      one: 'Récord: 1 día.',
    );
    return '$_temp0 Un día sin registros reinicia la racha.';
  }

  @override
  String get levelBeginner => 'Inicio';

  @override
  String get levelBronze => 'Bronce';

  @override
  String get levelSilver => 'Plata';

  @override
  String get levelGold => 'Oro';

  @override
  String get levelDiamond => 'Diamante';

  @override
  String get activityTitle => 'Actividad física';

  @override
  String get activitySetWeeklyGoal => 'Define tu meta semanal';

  @override
  String activitySessionsWeek(int done, int goal) {
    return '$done / $goal entrenamientos en la semana';
  }

  @override
  String activitySessionsWeekSuffix(int goal) {
    return ' / $goal entrenamientos en la semana';
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
      'Gimnasio, correr, caminar... Elige cuántas veces por semana y el horario.';

  @override
  String get activityCreateGoal => 'Crear meta';

  @override
  String activityMovingWeek(String duration) {
    return '$duration en movimiento esta semana';
  }

  @override
  String get activityLogWorkout => 'Registrar entrenamiento';

  @override
  String get whenToday => 'hoy';

  @override
  String get whenTomorrow => 'mañana';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en $count días',
      one: 'en 1 día',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notificaciones, $count sin leer',
      one: 'Notificaciones, 1 sin leer',
    );
    return '$_temp0';
  }

  @override
  String get registerHowTitle => '¿Cómo quieres registrarlo?';

  @override
  String get registerPhoto => 'Tomar foto del plato';

  @override
  String get registerPhotoSub => 'La IA estima alimentos, porciones y macros';

  @override
  String get registerGallery => 'Usar foto de la galería';

  @override
  String get registerGallerySub => 'Elige una foto que ya tomaste';

  @override
  String get registerDescribe => 'Hablar o escribir';

  @override
  String get registerDescribeSub =>
      'Cuenta lo que comiste; la IA estima y tú revisas';

  @override
  String get registerSearch => 'Buscar alimentos';

  @override
  String get registerSearchSub =>
      'En la base de alimentos, por código de barras o ingresando los valores';

  @override
  String get registerEatAgain => 'Comer de nuevo';

  @override
  String get registerRecent => 'Recientes';

  @override
  String get registerFavorites => 'Favoritas';

  @override
  String get registerAlso => 'También registrar';

  @override
  String get registerDose => 'Aplicación';

  @override
  String get registerWorkout => 'Entrenamiento';

  @override
  String get registerSymptom => 'Síntoma';

  @override
  String get registerWater => 'Agua';
}
