// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get languageTitle => '语言';

  @override
  String get languageChooseTitle => '选择应用语言';

  @override
  String get languageChooseSubtitle => '你可以随时在“个人资料 › 语言”中更改。';

  @override
  String get languageFollowDevice => '使用设备语言';

  @override
  String get languageInProgress => '翻译进行中';

  @override
  String get languageChange => '更改语言';

  @override
  String get languageChangeShort => '更改';

  @override
  String get authTagline => '一个照顾自己的空间。';

  @override
  String get authFooter => '按你的节奏，见证你的进步。';

  @override
  String get onboardingWelcomeTitle => '来制定你的计划吧';

  @override
  String get onboardingWelcomeSubtitle =>
      '回答几个简单的问题，PicNutri 就会为你量身调整。大约需要 2 分钟。';

  @override
  String get onboardingWelcomePhotoTitle => '拍照记录';

  @override
  String get onboardingWelcomePhotoText => '拍下餐盘，查看估算的热量和宏量营养素。';

  @override
  String get onboardingWelcomeGoalsTitle => '为你定制的目标';

  @override
  String get onboardingWelcomeGoalsText => '根据你的数据计算热量、蛋白质和饮水量。';

  @override
  String get onboardingWelcomeProgressTitle => '查看你的进展';

  @override
  String get onboardingWelcomeProgressText => '用简单的图表呈现体重、围度和习惯。';

  @override
  String get actionStart => '开始';

  @override
  String get actionStartUsing => '开始使用';

  @override
  String get actionContinue => '继续';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileSectionAccount => '账户';

  @override
  String get profileSectionPreferences => '偏好设置';

  @override
  String get profileSectionHelp => '帮助';

  @override
  String get profileGoals => '个人资料、目标与指标';

  @override
  String profileWater(String amount) {
    return '饮水 $amount';
  }

  @override
  String get profileMyPlan => '我的方案';

  @override
  String get profileProfessionals => '专业人士';

  @override
  String get profileProfessionalsSubtitle => '寻找营养师和健身专业人士';

  @override
  String get profileTrackMedication => '记录用药';

  @override
  String get profileTrackMedicationSubtitle => '在“进展”中记录处方用药和症状';

  @override
  String get profileSignInMethods => '登录方式';

  @override
  String get profileSignInMethodsSubtitle => '密码、Google、Facebook 和 Apple';

  @override
  String get profilePrivacy => '隐私与数据';

  @override
  String get profilePrivacySubtitle => '授权、导出和删除账户';

  @override
  String get profileNotifications => '通知与提醒';

  @override
  String get profileNotificationsOn => '已在此设备上开启';

  @override
  String get profileNotificationsOff => '已在此设备上关闭';

  @override
  String get profileTheme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get profileAssistant => '助手';

  @override
  String get profileAssistantSubtitle => '查看你的记录并咨询应用相关问题';

  @override
  String get profileHelpCenter => '帮助中心';

  @override
  String get profileHelpCenterSubtitle => '常见问题与使用指南';

  @override
  String get profileServerStatusDev => '服务器状态（开发）';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileLogoutConfirmTitle => '要退出登录吗？';

  @override
  String get profileLogoutConfirmMessage => '你需要在此设备上重新登录。';

  @override
  String get navHome => '首页';

  @override
  String get navFood => '饮食';

  @override
  String get navProgress => '进展';

  @override
  String get navContent => '内容';

  @override
  String get actionRetry => '重试';

  @override
  String get nutrientCarbs => '碳水化合物';

  @override
  String get nutrientProtein => '蛋白质';

  @override
  String get nutrientFat => '脂肪';

  @override
  String get mealBreakfast => '早餐';

  @override
  String get mealMorningSnack => '上午加餐';

  @override
  String get mealLunch => '午餐';

  @override
  String get mealAfternoonSnack => '下午加餐';

  @override
  String get mealDinner => '晚餐';

  @override
  String get mealSupper => '夜宵';

  @override
  String get mealOther => '其他';

  @override
  String relToday(String time) {
    return '今天 $time';
  }

  @override
  String relTomorrow(String time) {
    return '明天 $time';
  }

  @override
  String relYesterday(String time) {
    return '昨天 $time';
  }

  @override
  String get homeRegister => '记录';

  @override
  String get homeGoodMorning => '早上好';

  @override
  String get homeGoodAfternoon => '下午好';

  @override
  String get homeGoodEvening => '晚上好';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting，$name';
  }

  @override
  String get homeTagline => '每一份小小的用心都很重要。';

  @override
  String get homeQuickPhoto => '拍下餐盘';

  @override
  String get homeQuickMeal => '餐食';

  @override
  String get homeQuickWater => '喝水';

  @override
  String get homeYourProgress => '你的进展';

  @override
  String get homeProgressEmpty => '记录你的体重和照片';

  @override
  String homeCurrentWeight(String weight) {
    return '当前体重：$weight';
  }

  @override
  String homeNextWater(String amount) {
    return '还差 $amount 饮水';
  }

  @override
  String get homeNextWaterMessage => '一次一杯就很有帮助。';

  @override
  String get homeLogWater => '记录饮水';

  @override
  String homeNextProtein(String amount) {
    return '还差 $amount 蛋白质';
  }

  @override
  String get homeNextProteinMessage => '查看富含优质蛋白质的食谱灵感。';

  @override
  String get homeSeeRecipes => '查看食谱';

  @override
  String get homeSetGoalsTitle => '设定你的目标';

  @override
  String get homeSetGoalsMessage => '设定饮水和蛋白质目标后，应用会显示每天还差多少。';

  @override
  String get homeSetGoalsAction => '设定目标';

  @override
  String get homeGoalsReached => '饮水和蛋白质目标已达成';

  @override
  String get homeGoalsReachedMessage => '每一份用心都很重要。按自己的节奏继续吧。';

  @override
  String homeMealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 餐',
    );
    return '$_temp0';
  }

  @override
  String get homeDayBalance => '你今天的均衡情况';

  @override
  String homeKcalOfGoal(String kcal, String goal) {
    return '$kcal / $goal';
  }

  @override
  String homeKcalLogged(String kcal) {
    return '已记录 $kcal';
  }

  @override
  String homeOfGoal(String goal) {
    return '/ $goal';
  }

  @override
  String get homeKcalLoggedShort => 'kcal 已记录';

  @override
  String get homeNoMealsDay => '这一天没有记录餐食。';

  @override
  String get homeSetYourGoal => '设定你的目标';

  @override
  String get homeAboveGoal => ' 超出目标';

  @override
  String get homeToGoal => ' 距离目标';

  @override
  String homeMacroSemanticsGoal(String name, String grams, String goal) {
    return '$name：$grams / $goal 克';
  }

  @override
  String homeMacroSemantics(String name, String grams) {
    return '$name：$grams 克';
  }

  @override
  String homeWaterAdded(int ml) {
    return '已记录 +$ml ml。';
  }

  @override
  String get homeWaterNoneToday => '今天还没有饮水记录。';

  @override
  String homeWaterRemoved(String amount) {
    return '已删除 $amount 的记录。';
  }

  @override
  String get homeHydration => '饮水';

  @override
  String get homeHydrationDetails => '饮水详情';

  @override
  String homeWaterSemantics(String total, String goal, int percent) {
    return '饮水：$total / $goal，完成目标的 $percent%。';
  }

  @override
  String get homeWaterMore => '其他饮水量';

  @override
  String get homeWaterOther => '其他数量';

  @override
  String get homeWaterUndo => '撤销上一次饮水记录';

  @override
  String get homeWeightNone => '体重：暂无记录';

  @override
  String homeWeightValue(String weight) {
    return '体重：$weight';
  }

  @override
  String get homeWeight => '体重';

  @override
  String get homeNoRecord => '暂无记录';

  @override
  String get homeWeightHint => '记录下来以便追踪。';

  @override
  String homeWeightChange(String change) {
    return '30 天内 $change';
  }

  @override
  String homeWeightGoal(String weight) {
    return '目标：$weight';
  }

  @override
  String homeUpdatedOn(String date) {
    return '更新于 $date';
  }

  @override
  String get homeLogWeight => '记录体重';

  @override
  String get homeYourMeals => '你的餐食';

  @override
  String get homeSeeAll => '查看全部';

  @override
  String get homeMealsError => '无法加载你的餐食。';

  @override
  String get homeMealsEmpty => '你当天的餐食会显示在这里。';

  @override
  String homeMealLogged(String kcal) {
    return '已记录 · $kcal';
  }

  @override
  String get homeMealPending => '要记录一下吗？';

  @override
  String get homeCompleteProfile => '完善你的资料';

  @override
  String homeCompleteProfileMessage(String items) {
    return '待完成：$items。补充这些信息后，目标和建议会更准确。';
  }

  @override
  String get homeCompleteNow => '立即完善';

  @override
  String get skippedEssentials => '基本信息';

  @override
  String get skippedRoutine => '饮食与作息';

  @override
  String get skippedGuidance => '专业指导';

  @override
  String get skippedMedication => '药物';

  @override
  String get skippedCare => '服务偏好';

  @override
  String get skippedTargets => '每日目标';

  @override
  String get doseMedication => '用药';

  @override
  String get doseFirstHeadline => '记录你的第一次用药';

  @override
  String get doseFirstCaption => '下一次的倒计时将从这次开始。';

  @override
  String get doseLast => '上次用药';

  @override
  String get doseNoFrequency => '在药物信息中填写频率即可查看下一次。';

  @override
  String get doseExpected => '预定用药';

  @override
  String get doseExpectedCaption => '已经用过了？记录一下以更新倒计时。';

  @override
  String get doseNext => '下次用药';

  @override
  String get doseCycle => '两次用药之间的周期';

  @override
  String get doseLastShort => '上次';

  @override
  String get doseEstimatedLevel => '估计水平';

  @override
  String get doseLog => '记录用药';

  @override
  String get doseSetupTitle => '添加你的药物';

  @override
  String get doseSetupText => '以便查看距下次用药的倒计时。';

  @override
  String get missionsTitle => '今日目标';

  @override
  String get missionsError => '无法加载你的星星。';

  @override
  String get missionsMyAchievement => '我今天的成就';

  @override
  String missionsLevelStreak(String level, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连续 $count 天',
    );
    return '等级 $level · $_temp0';
  }

  @override
  String get missionsBroken => '你的连续记录中断了。今天重新开始吧？';

  @override
  String missionsLevelUp(String level) {
    return '恭喜！你达到了 $level 等级！';
  }

  @override
  String get missionsKeepGoing => '每一天的用心都值得一份成就！';

  @override
  String get missionsFirstDay => '你的第一天从一条记录开始。';

  @override
  String get missionsDiamond => '已获得钻石！继续保持连续记录。';

  @override
  String missionsDaysTo(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '距离 $level 还有 $count 天',
    );
    return '$_temp0';
  }

  @override
  String missionsRecord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最高纪录：$count 天。',
    );
    return '$_temp0一天不记录，连续记录就会重新开始。';
  }

  @override
  String get levelBeginner => '起步';

  @override
  String get levelBronze => '青铜';

  @override
  String get levelSilver => '白银';

  @override
  String get levelGold => '黄金';

  @override
  String get levelDiamond => '钻石';

  @override
  String get activityTitle => '体育活动';

  @override
  String get activitySetWeeklyGoal => '设定你的每周目标';

  @override
  String activitySessionsWeek(int done, int goal) {
    return '本周训练 $done / $goal 次';
  }

  @override
  String activitySessionsWeekSuffix(int goal) {
    return ' / $goal 次本周训练';
  }

  @override
  String activityWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 周',
    );
    return '$_temp0';
  }

  @override
  String get activitySetGoalHint => '健身、跑步、步行……选择每周几次以及时间。';

  @override
  String get activityCreateGoal => '创建目标';

  @override
  String activityMovingWeek(String duration) {
    return '本周运动 $duration';
  }

  @override
  String get activityLogWorkout => '记录训练';

  @override
  String get whenToday => '今天';

  @override
  String get whenTomorrow => '明天';

  @override
  String whenInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天后',
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
      other: '通知，$count 条未读',
    );
    return '$_temp0';
  }

  @override
  String get registerHowTitle => '你想怎么记录？';

  @override
  String get registerPhoto => '拍摄餐盘';

  @override
  String get registerPhotoSub => 'AI 估算食物、份量和宏量营养素';

  @override
  String get registerGallery => '使用相册照片';

  @override
  String get registerGallerySub => '选择一张已拍的照片';

  @override
  String get registerDescribe => '说出或输入';

  @override
  String get registerDescribeSub => '说说你吃了什么，AI 估算后由你确认';

  @override
  String get registerSearch => '搜索食物';

  @override
  String get registerSearchSub => '在食物库中搜索、扫描条形码或手动输入数值';

  @override
  String get registerEatAgain => '再吃一次';

  @override
  String get registerRecent => '最近';

  @override
  String get registerFavorites => '收藏';

  @override
  String get registerAlso => '还可以记录';

  @override
  String get registerDose => '用药';

  @override
  String get registerWorkout => '训练';

  @override
  String get registerSymptom => '症状';

  @override
  String get registerWater => '饮水';
}
