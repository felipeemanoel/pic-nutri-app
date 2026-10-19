import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/presentation/meal_photo_page.dart';
import '../features/assistant/presentation/assistant_page.dart';
import '../features/assistant/presentation/chat_page.dart';
import '../features/auth/application/session_controller.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/auth/presentation/sign_in_methods_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/engagement/presentation/engagement_page.dart';
import '../features/food/data/nutrition_models.dart';
import '../features/food/presentation/food_page.dart';
import '../features/food/presentation/meal_editor_page.dart';
import '../features/help/presentation/help_pages.dart';
import '../features/home/presentation/home_page.dart';
import '../features/notifications/presentation/notification_settings_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/plan/presentation/plan_page.dart';
import '../features/planning/presentation/meal_plan_page.dart';
import '../features/planning/presentation/plans_page.dart';
import '../features/planning/presentation/recipes_page.dart';
import '../features/planning/presentation/shopping_list_page.dart';
import '../features/privacy/presentation/privacy_page.dart';
import '../features/professionals/presentation/contact_requests_page.dart';
import '../features/professionals/presentation/professional_detail_page.dart';
import '../features/professionals/presentation/professionals_page.dart';
import '../features/professionals/presentation/share_grants_page.dart';
import '../features/profile/presentation/change_password_page.dart';
import '../features/profile/presentation/edit_profile_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/progress/presentation/progress_page.dart';
import '../features/reports/presentation/reports_page.dart';
import '../features/symptoms/presentation/symptoms_page.dart';
import '../features/system_status/presentation/system_status_page.dart';
import '../features/water/presentation/water_page.dart';
import 'features.dart';
import 'routes.dart';
import 'shell/app_shell.dart';

export 'routes.dart';

/// Decide para onde mandar o usuário conforme o estado da sessão.
/// Função pura, testada isoladamente.
String? redirectFor(AsyncValue<SessionState> session, String location) {
  final state = session.value;

  if (state == null) {
    // Verificando sessão ou API indisponível na abertura.
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  return switch (state) {
    SessionSignedOut() =>
      AppRoutes.public.contains(location) ? null : AppRoutes.login,
    SessionSignedIn(:final account) when !account.onboardingCompleted =>
      location == AppRoutes.onboarding ? null : AppRoutes.onboarding,
    SessionSignedIn() =>
      AppRoutes.public.contains(location) ||
              location == AppRoutes.splash ||
              location == AppRoutes.onboarding
          ? AppRoutes.home
          : null,
  };
}

/// Notifica o GoRouter quando a sessão muda, para reavaliar o redirect.
class _SessionListenable extends ChangeNotifier {
  void changed() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _SessionListenable();
  ref.listen(sessionControllerProvider, (_, _) => listenable.changed());

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) =>
        redirectFor(ref.read(sessionControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) =>
            ResetPasswordPage(email: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      // Perfil e configurações: fora das abas, aberto pelo avatar no topo.
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfilePage(),
          ),
          GoRoute(
            path: 'password',
            builder: (context, state) => const ChangePasswordPage(),
          ),
          GoRoute(
            path: 'sign-in-methods',
            builder: (context, state) => const SignInMethodsPage(),
          ),
          GoRoute(
            path: 'status',
            builder: (context, state) => const SystemStatusPage(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsPage(),
          ),
          GoRoute(
            path: 'reminders',
            redirect: (context, state) => AppRoutes.notificationSettings,
          ),
          GoRoute(path: 'plan', builder: (context, state) => const PlanPage()),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyPage(),
          ),
          if (AppFeatures.medical)
            GoRoute(
              path: 'share-grants',
              builder: (context, state) => const ShareGrantsPage(),
            ),
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpCenterPage(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (context, state) =>
                    HelpArticlePage(slug: state.pathParameters['slug']!),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'water',
                    builder: (context, state) => const WaterPage(),
                  ),
                  GoRoute(
                    path: 'symptoms',
                    builder: (context, state) => const SymptomsPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.food,
                builder: (context, state) => const FoodPage(),
                routes: [
                  GoRoute(
                    path: 'meal',
                    builder: (context, state) => const MealEditorPage(),
                  ),
                  GoRoute(
                    path: 'meal-edit',
                    builder: (context, state) =>
                        MealEditorPage(meal: state.extra as Meal?),
                  ),
                  GoRoute(
                    path: 'photo',
                    builder: (context, state) => const MealPhotoPage(),
                  ),
                  GoRoute(
                    path: 'text',
                    builder: (context, state) =>
                        const MealPhotoPage(textMode: true),
                  ),
                  GoRoute(
                    path: 'plans',
                    builder: (context, state) => const PlansPage(),
                    routes: [
                      GoRoute(
                        path: ':planId',
                        builder: (context, state) => MealPlanPage(
                          planId: state.pathParameters['planId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'shopping',
                            builder: (context, state) => ShoppingListPage(
                              planId: state.pathParameters['planId']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'recipes',
                    builder: (context, state) => const RecipesPage(),
                    routes: [
                      GoRoute(
                        path: ':recipeId',
                        builder: (context, state) => RecipePage(
                          recipeId: int.parse(
                            state.pathParameters['recipeId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'photo-review',
                    builder: (context, state) {
                      final review = state.extra as PhotoReview?;
                      return MealEditorPage(
                        initialItems: review?.items,
                        photoAnalysisId: review?.analysisId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => const ProgressPage(),
                routes: [
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) => const ReportsPage(),
                  ),
                  GoRoute(
                    path: 'habits',
                    builder: (context, state) => const EngagementPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.assistant,
                builder: (context, state) => const AssistantPage(),
                routes: [
                  GoRoute(
                    path: 'chat',
                    builder: (context, state) => switch (state.extra) {
                      final ChatDraft draft => ChatPage(draft: draft.text),
                      final String id => ChatPage(conversationId: id),
                      _ => const ChatPage(),
                    },
                  ),
                ],
              ),
            ],
          ),
          if (AppFeatures.medical)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.professionals,
                  builder: (context, state) => const ProfessionalsPage(),
                  routes: [
                    GoRoute(
                      path: 'requests',
                      builder: (context, state) => const ContactRequestsPage(),
                    ),
                    GoRoute(
                      path: ':professionalId',
                      builder: (context, state) => ProfessionalDetailPage(
                        id: state.pathParameters['professionalId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Página não encontrada.')),
    ),
  );

  ref.onDispose(() {
    router.dispose();
    listenable.dispose();
  });
  return router;
});
