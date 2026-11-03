// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get languageTitle => '言語';

  @override
  String get languageChooseTitle => 'アプリの言語を選択';

  @override
  String get languageChooseSubtitle => '「プロフィール › 言語」からいつでも変更できます。';

  @override
  String get languageFollowDevice => '端末の言語を使用';

  @override
  String get languageInProgress => '翻訳中';

  @override
  String get languageChange => '言語を変更';

  @override
  String get languageChangeShort => '変更';

  @override
  String get authTagline => '自分を大切にするための場所。';

  @override
  String get authFooter => 'あなたのペースで、あなたの成長を。';

  @override
  String get onboardingWelcomeTitle => 'あなたのプランを作りましょう';

  @override
  String get onboardingWelcomeSubtitle =>
      'いくつかの簡単な質問に答えると、PicNutri があなたに合わせて調整します。所要時間は約2分です。';

  @override
  String get onboardingWelcomePhotoTitle => '写真で記録';

  @override
  String get onboardingWelcomePhotoText => 'お皿を撮影して、推定カロリーと栄養素を確認。';

  @override
  String get onboardingWelcomeGoalsTitle => 'あなたに合わせた目標';

  @override
  String get onboardingWelcomeGoalsText => 'カロリー、たんぱく質、水分をあなたのデータから計算。';

  @override
  String get onboardingWelcomeProgressTitle => '成長を確認';

  @override
  String get onboardingWelcomeProgressText => '体重・サイズ・習慣をシンプルなグラフで。';

  @override
  String get actionStart => 'はじめる';

  @override
  String get actionStartUsing => '使い始める';

  @override
  String get actionContinue => '続ける';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get profileSectionAccount => 'アカウント';

  @override
  String get profileSectionPreferences => '設定';

  @override
  String get profileSectionHelp => 'ヘルプ';

  @override
  String get profileGoals => 'プロフィール・目的・目標';

  @override
  String profileWater(String amount) {
    return '水分 $amount';
  }

  @override
  String get profileMyPlan => 'マイプラン';

  @override
  String get profileProfessionals => '専門家';

  @override
  String get profileProfessionalsSubtitle => '管理栄養士や運動指導者を探す';

  @override
  String get profileTrackMedication => '薬を記録';

  @override
  String get profileTrackMedicationSubtitle => '処方された投与と症状を「経過」に記録';

  @override
  String get profileSignInMethods => 'ログイン方法';

  @override
  String get profileSignInMethodsSubtitle => 'パスワード、Google、Facebook、Apple';

  @override
  String get profilePrivacy => 'プライバシーとデータ';

  @override
  String get profilePrivacySubtitle => '同意、エクスポート、アカウント削除';

  @override
  String get profileNotifications => '通知とリマインダー';

  @override
  String get profileNotificationsOn => 'この端末でオン';

  @override
  String get profileNotificationsOff => 'この端末でオフ';

  @override
  String get profileTheme => 'テーマ';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get profileAssistant => 'アシスタント';

  @override
  String get profileAssistantSubtitle => '記録を確認し、アプリについて質問できます';

  @override
  String get profileHelpCenter => 'ヘルプセンター';

  @override
  String get profileHelpCenterSubtitle => 'よくある質問と使い方ガイド';

  @override
  String get profileServerStatusDev => 'サーバーの状態（開発）';

  @override
  String get profileLogout => 'ログアウト';

  @override
  String get profileLogoutConfirmTitle => 'ログアウトしますか？';

  @override
  String get profileLogoutConfirmMessage => 'この端末で再度ログインが必要になります。';

  @override
  String get navHome => 'ホーム';

  @override
  String get navFood => '食事';

  @override
  String get navProgress => '経過';

  @override
  String get navContent => 'コンテンツ';

  @override
  String get actionRetry => '再試行';

  @override
  String get nutrientCarbs => '炭水化物';

  @override
  String get nutrientProtein => 'たんぱく質';

  @override
  String get nutrientFat => '脂質';

  @override
  String get mealBreakfast => '朝食';

  @override
  String get mealMorningSnack => '午前の間食';

  @override
  String get mealLunch => '昼食';

  @override
  String get mealAfternoonSnack => '午後の間食';

  @override
  String get mealDinner => '夕食';

  @override
  String get mealSupper => '夜食';

  @override
  String get mealOther => 'その他';

  @override
  String relToday(String time) {
    return '今日 $time';
  }

  @override
  String relTomorrow(String time) {
    return '明日 $time';
  }

  @override
  String relYesterday(String time) {
    return '昨日 $time';
  }

  @override
  String get homeRegister => '記録';

  @override
  String get homeGoodMorning => 'おはようございます';

  @override
  String get homeGoodAfternoon => 'こんにちは';

  @override
  String get homeGoodEvening => 'こんばんは';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$nameさん、$greeting';
  }

  @override
  String get homeTagline => '小さなケアの積み重ねが大切です。';

  @override
  String get homeQuickPhoto => 'お皿を撮影';

  @override
  String get homeQuickMeal => '食事';

  @override
  String get homeQuickWater => '水を飲む';

  @override
  String get homeYourProgress => 'あなたの経過';

  @override
  String get homeProgressEmpty => '体重と写真を記録しましょう';

  @override
  String homeCurrentWeight(String weight) {
    return '現在の体重：$weight';
  }

  @override
  String homeNextWater(String amount) {
    return '水分はあと $amount';
  }

  @override
  String get homeNextWaterMessage => '1杯ずつでも効果があります。';

  @override
  String get homeLogWater => '水分を記録';

  @override
  String homeNextProtein(String amount) {
    return 'たんぱく質はあと $amount';
  }

  @override
  String get homeNextProteinMessage => '良質なたんぱく質を含むレシピを見てみましょう。';

  @override
  String get homeSeeRecipes => 'レシピを見る';

  @override
  String get homeSetGoalsTitle => '目標を設定しましょう';

  @override
  String get homeSetGoalsMessage => '水分とたんぱく質の目標を設定すると、毎日あとどれだけ必要かが表示されます。';

  @override
  String get homeSetGoalsAction => '目標を設定';

  @override
  String get homeGoalsReached => '水分とたんぱく質の目標を達成';

  @override
  String get homeGoalsReachedMessage => '一つひとつのケアが大切です。自分のペースで続けましょう。';

  @override
  String homeMealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 食',
    );
    return '$_temp0';
  }

  @override
  String get homeDayBalance => '今日のバランス';

  @override
  String homeKcalOfGoal(String kcal, String goal) {
    return '$kcal / $goal';
  }

  @override
  String homeKcalLogged(String kcal) {
    return '$kcal 記録済み';
  }

  @override
  String homeOfGoal(String goal) {
    return '/ $goal';
  }

  @override
  String get homeKcalLoggedShort => 'kcal 記録済み';

  @override
  String get homeNoMealsDay => 'この日の食事の記録はありません。';

  @override
  String get homeSetYourGoal => '目標を設定';

  @override
  String get homeAboveGoal => ' 目標超過';

  @override
  String get homeToGoal => ' 目標まで';

  @override
  String homeMacroSemanticsGoal(String name, String grams, String goal) {
    return '$name：$grams / $goal グラム';
  }

  @override
  String homeMacroSemantics(String name, String grams) {
    return '$name：$grams グラム';
  }

  @override
  String homeWaterAdded(int ml) {
    return '+$ml ml を記録しました。';
  }

  @override
  String get homeWaterNoneToday => '今日の水分記録はありません。';

  @override
  String homeWaterRemoved(String amount) {
    return '$amount の記録を削除しました。';
  }

  @override
  String get homeHydration => '水分補給';

  @override
  String get homeHydrationDetails => '水分補給の詳細';

  @override
  String homeWaterSemantics(String total, String goal, int percent) {
    return '水分：$total / $goal、目標の $percent%。';
  }

  @override
  String get homeWaterMore => 'その他の量';

  @override
  String get homeWaterOther => '別の量';

  @override
  String get homeWaterUndo => '最後の水分記録を取り消す';

  @override
  String get homeWeightNone => '体重：記録なし';

  @override
  String homeWeightValue(String weight) {
    return '体重：$weight';
  }

  @override
  String get homeWeight => '体重';

  @override
  String get homeNoRecord => '記録なし';

  @override
  String get homeWeightHint => '記録して経過を確認しましょう。';

  @override
  String homeWeightChange(String change) {
    return '30日間で $change';
  }

  @override
  String homeWeightGoal(String weight) {
    return '目標：$weight';
  }

  @override
  String homeUpdatedOn(String date) {
    return '$date 更新';
  }

  @override
  String get homeLogWeight => '体重を記録';

  @override
  String get homeYourMeals => 'あなたの食事';

  @override
  String get homeSeeAll => 'すべて見る';

  @override
  String get homeMealsError => '食事を読み込めませんでした。';

  @override
  String get homeMealsEmpty => 'その日の食事がここに表示されます。';

  @override
  String homeMealLogged(String kcal) {
    return '記録済み · $kcal';
  }

  @override
  String get homeMealPending => '記録しますか？';

  @override
  String get homeCompleteProfile => 'プロフィールを完成させましょう';

  @override
  String homeCompleteProfileMessage(String items) {
    return '後回しにした項目：$items。入力すると目標や提案がより正確になります。';
  }

  @override
  String get homeCompleteNow => '今すぐ入力';

  @override
  String get skippedEssentials => '基本情報';

  @override
  String get skippedRoutine => '食事と生活リズム';

  @override
  String get skippedGuidance => '専門家の指導';

  @override
  String get skippedMedication => '薬';

  @override
  String get skippedCare => 'サポートの希望';

  @override
  String get skippedTargets => '1日の目標';

  @override
  String get doseMedication => '服薬';

  @override
  String get doseFirstHeadline => '最初の投与を記録しましょう';

  @override
  String get doseFirstCaption => '次回までのカウントはここから始まります。';

  @override
  String get doseLast => '前回の投与';

  @override
  String get doseNoFrequency => '次回を表示するには、頻度を登録してください。';

  @override
  String get doseExpected => '予定の投与';

  @override
  String get doseExpectedCaption => '投与済みですか？記録するとカウントが更新されます。';

  @override
  String get doseNext => '次回の投与';

  @override
  String get doseCycle => '投与間隔';

  @override
  String get doseLastShort => '前回';

  @override
  String get doseEstimatedLevel => '推定レベル';

  @override
  String get doseLog => '投与を記録';

  @override
  String get doseSetupTitle => '薬を登録しましょう';

  @override
  String get doseSetupText => '次回の投与までのカウントを表示するためです。';

  @override
  String get missionsTitle => '今日の目標';

  @override
  String get missionsError => 'スターを読み込めませんでした。';

  @override
  String get missionsMyAchievement => '今日の達成';

  @override
  String missionsLevelStreak(String level, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日連続',
    );
    return 'レベル $level · $_temp0';
  }

  @override
  String get missionsBroken => '連続記録が途切れました。今日からまた始めましょう。';

  @override
  String missionsLevelUp(String level) {
    return 'おめでとうございます！$level レベルに到達しました！';
  }

  @override
  String get missionsKeepGoing => 'ケアした毎日が達成になります！';

  @override
  String get missionsFirstDay => '最初の1日は1件の記録から始まります。';

  @override
  String get missionsDiamond => 'ダイヤモンド達成！連続記録を続けましょう。';

  @override
  String missionsDaysTo(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$level まであと $count 日',
    );
    return '$_temp0';
  }

  @override
  String missionsRecord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最高記録：$count日。',
    );
    return '$_temp0記録しない日があると連続記録はリセットされます。';
  }

  @override
  String get levelBeginner => 'スタート';

  @override
  String get levelBronze => 'ブロンズ';

  @override
  String get levelSilver => 'シルバー';

  @override
  String get levelGold => 'ゴールド';

  @override
  String get levelDiamond => 'ダイヤモンド';

  @override
  String get activityTitle => '運動';

  @override
  String get activitySetWeeklyGoal => '今週の目標を設定';

  @override
  String activitySessionsWeek(int done, int goal) {
    return '今週のトレーニング $done / $goal 回';
  }

  @override
  String activitySessionsWeekSuffix(int goal) {
    return ' / $goal 回（今週）';
  }

  @override
  String activityWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count週',
    );
    return '$_temp0';
  }

  @override
  String get activitySetGoalHint => 'ジム、ランニング、ウォーキング…週に何回、何時に行うか選びましょう。';

  @override
  String get activityCreateGoal => '目標を作成';

  @override
  String activityMovingWeek(String duration) {
    return '今週の運動時間 $duration';
  }

  @override
  String get activityLogWorkout => 'トレーニングを記録';

  @override
  String get whenToday => '今日';

  @override
  String get whenTomorrow => '明日';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日後',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => '通知';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '通知、未読 $count 件',
    );
    return '$_temp0';
  }

  @override
  String get registerHowTitle => 'どの方法で記録しますか？';

  @override
  String get registerPhoto => 'お皿を撮影';

  @override
  String get registerPhotoSub => 'AIが食品・量・栄養素を推定します';

  @override
  String get registerGallery => 'ギャラリーの写真を使う';

  @override
  String get registerGallerySub => '撮影済みの写真を選びます';

  @override
  String get registerDescribe => '話す・入力する';

  @override
  String get registerDescribeSub => '食べたものを伝えると、AIが推定し、あなたが確認します';

  @override
  String get registerSearch => '食品を検索';

  @override
  String get registerSearchSub => '食品データベース、バーコード、または数値の入力で';

  @override
  String get registerEatAgain => 'もう一度食べる';

  @override
  String get registerRecent => '最近';

  @override
  String get registerFavorites => 'お気に入り';

  @override
  String get registerAlso => 'その他の記録';

  @override
  String get registerDose => '投与';

  @override
  String get registerWorkout => 'トレーニング';

  @override
  String get registerSymptom => '症状';

  @override
  String get registerWater => '水分';
}
