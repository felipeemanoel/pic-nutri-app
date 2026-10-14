/// Caminhos de rota centralizados.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const onboarding = '/onboarding';

  // Abas principais.
  static const home = '/home';
  static const food = '/food';
  static const progress = '/progress';
  static const assistant = '/assistant';
  static const professionals = '/professionals';

  // Perfil: fora das abas, aberto pelo avatar no topo.
  static const profile = '/profile';

  // Telas internas.
  static const water = '/home/water';
  static const symptoms = '/home/symptoms';
  static const help = '/profile/help';
  static String helpArticle(String slug) => '/profile/help/$slug';
  static const newMeal = '/food/meal';
  static const editMeal = '/food/meal-edit';
  static const mealPhoto = '/food/photo';
  static const mealText = '/food/text';
  static const photoReview = '/food/photo-review';
  static const mealPlans = '/food/plans';
  static const recipes = '/food/recipes';
  static String mealPlan(String id) => '/food/plans/$id';
  static String shoppingList(String id) => '/food/plans/$id/shopping';
  static String recipe(int id) => '/food/recipes/$id';
  static const chat = '/assistant/chat';
  static const contactRequests = '/professionals/requests';
  static String professional(String id) => '/professionals/$id';
  static const reports = '/progress/reports';
  static const engagement = '/progress/habits';

  static const editProfile = '/profile/edit';
  static const changePassword = '/profile/password';
  static const systemStatus = '/profile/status';
  static const reminders = '/profile/reminders';
  static const plan = '/profile/plan';
  static const privacy = '/profile/privacy';
  static const shareGrants = '/profile/share-grants';

  /// Rotas acessíveis sem sessão.
  static const public = {login, register, forgotPassword, resetPassword};
}
