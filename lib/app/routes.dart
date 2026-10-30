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
  static const contents = '/contents';
  static const articles = '/contents/articles';
  static String article(String slug) => '/contents/articles/$slug';

  // Assistente: acesso eventual pelo menu de Perfil.
  static const assistant = '/assistant';

  /// Prefixos das abas: telas sob eles abrem com `go` (trocam de aba);
  /// as demais (Perfil, Profissionais, notificações) abrem com `push`.
  static const tabRoots = [home, food, progress, contents, profile];
  static bool isInTabs(String location) =>
      tabRoots.any((r) => location == r || location.startsWith('$r/'));

  // Profissionais: fora das abas, aberto pelo Perfil (uso eventual).
  static const professionals = '/professionals';

  // Perfil e menu geral: quinta aba.
  static const profile = '/profile';

  // Central de notificações: fora das abas, aberta pelo sino no topo.
  static const notifications = '/notifications';

  // Primeira visita guiada (tela cheia). `?review=1`: revisão pela ajuda.
  static const introTour = '/welcome';

  // Telas internas.
  static const water = '/home/water';
  // Atividade física: metas, treinos e eventos.
  static const activity = '/home/activity';
  // Bem-estar (sintomas): parte da Evolução.
  static const symptoms = '/progress/symptoms';
  static const help = '/profile/help';
  static String helpArticle(String slug) => '/profile/help/$slug';
  static const newMeal = '/food/meal';
  static const editMeal = '/food/meal-edit';
  static const repeatMeal = '/food/meal-repeat';
  static const mealPhoto = '/food/photo';
  static const mealText = '/food/text';
  static const photoReview = '/food/photo-review';
  // Revisão de uma refeição a partir de uma receita ("Comi esta receita").
  static const recipeMeal = '/food/meal-from-recipe';
  // Endereço anterior de conteúdos: redireciona para a nova aba.
  static const legacyContents = '/food/contents';
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
  static const signInMethods = '/profile/sign-in-methods';
  static const systemStatus = '/profile/status';
  static const notificationSettings = '/profile/notifications';
  // Endereço antigo da tela de lembretes (redireciona para as configurações).
  static const reminders = '/profile/reminders';
  static const plan = '/profile/plan';
  static const privacy = '/profile/privacy';
  static const shareGrants = '/profile/share-grants';

  /// Rotas acessíveis sem sessão.
  static const public = {login, register, forgotPassword, resetPassword};
}
