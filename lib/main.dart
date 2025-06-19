import 'package:arvo/views/shared/member_xprofile_location_selection_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/app_update_alert.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/firebase_options.dart';
import 'package:arvo/helpers/error_handling/error_handler_widget.dart';
import 'package:arvo/services/ads/ad_service.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_service.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/features/subscription_service.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/services/push_notifications/push_notification_service.dart';
import 'package:arvo/services/tips/tip_service.dart';
import 'package:arvo/theme/dark_theme.dart';
import 'package:arvo/theme/light_theme.dart';
import 'package:arvo/theme/theme_cubit.dart';
import 'package:arvo/views/dashboard/dashboard_view.dart';
import 'package:arvo/views/faqs/faqs_view.dart';
import 'package:arvo/views/log_in_and_registration/log_in_view.dart';
import 'package:arvo/views/log_in_and_registration/lost_password_view.dart';
import 'package:arvo/views/log_in_and_registration/register_view.dart';
import 'package:arvo/views/log_in_and_registration/activate_account_view.dart';
import 'package:arvo/views/member_profile/edit_profile_group_view.dart';
import 'package:arvo/views/member_profile/edit_profile_pictures_view.dart';
import 'package:arvo/views/member_search/member_filters_view.dart';
import 'package:arvo/views/member_search/member_swipe_view.dart';
import 'package:arvo/views/photo_verification/photo_verification_view.dart';
import 'package:arvo/views/shared/member_xprofile_options_selection_view.dart';
import 'package:arvo/views/member_profile/edit_profile_picture_view.dart';
import 'package:arvo/views/member_profile/member_profile_view.dart';
import 'package:arvo/views/perfect_match_quiz/perfect_match_quiz_finish_view.dart';
import 'package:arvo/views/perfect_match_quiz/perfect_match_quiz_start_view.dart';
import 'package:arvo/views/perfect_match_quiz/perfect_match_quiz_view.dart';
import 'package:arvo/views/posts/post_view.dart';
import 'package:arvo/views/settings/blocked_members_view.dart';
import 'package:arvo/views/settings/create_update_server_view.dart';
import 'package:arvo/views/settings/servers_view.dart';
import 'package:arvo/views/settings/settings_view.dart';
import 'package:arvo/views/log_in_and_registration/sms_verification_view.dart';
import 'package:arvo/views/subscription/subscriptions_view.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:app_base/loading/loading_screen.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:upgrader/upgrader.dart';

/// Production Preparation Checklist
/// ☐ Increment version number in pubspec.yaml
/// Example: version: 20.0.4+204 will become 20.0.5+205
/// ☐ Disable development features by setting "isDevelopment = false;" in
/// arvo_development_provider.dart
/// ☐ Comment out the line "await Upgrader.clearSavedSettings();" in the main()
/// function below
/// ☐ Update the minimum version information in the description section of both the
/// Google Play Store and Apple App Store
/// Google - [Minimum supported app version: 20.0.15]
///  Apple - [:mav: 20.0.15]
/// ☐ For the Google Play Store, make sure the version does not contain any
/// text, otherwise the update detection code will not pick it up. The version
/// displayed on the store should be in the following format: 215 (20.0.15)

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Upgrader.
  // Only call clearSavedSettings() during testing to reset internal values.
  //await Upgrader.clearSavedSettings(); // Remove this for release builds.

  // Initialise HydratedBloc.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getTemporaryDirectory(),
  );

  // Initialise Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialise ThemeCubit.
  final themeCubit = ThemeCubit();

  // Initialise services.
  DatabaseSystemSetting systemSetting =
      await LocalStorageService.arvo().getSystemSetting();
  DatabaseServer serverUrl =
      await LocalStorageService.arvo().getServer(systemSetting.serverId);
  ConnectionService.arvo().initalise(serverUrl.url);
  PushNotificationService.firebase().initalise(
    ConnectionService.arvo(),
    LocalStorageService.arvo(),
  );
  FeatureService.arvo().initalise(
    ConnectionService.arvo(),
    LocalStorageService.arvo(),
    themeCubit,
  );
  SubscriptionService.arvo().initalise(
    ConnectionService.arvo(),
    LocalStorageService.arvo(),
    FeatureService.arvo(),
  );
  AdService.arvo().initalise(
    FeatureService.arvo(),
    LocalStorageService.arvo(),
  );
  TipService.arvo().initalise(
    ConnectionService.arvo(),
    LocalStorageService.arvo(),
  );
  MemberDirectoryService.arvo().initalise(
    ConnectionService.arvo(),
    LocalStorageService.arvo(),
    FeatureService.arvo(),
  );
  MessagingHandlerService.arvo().initalise(
    ConnectionService.arvo(),
    LocalStorageService.arvo(),
    MemberDirectoryService.arvo(),
    PushNotificationService.firebase(),
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => themeCubit,
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            ConnectionService.arvo(),
            LocalStorageService.arvo(),
            PushNotificationService.firebase(),
            themeCubit,
          ),
        ),
      ],
      child: const App(),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialise the AuthBloc.
    context.read<AuthBloc>().add(const AuthEventInitialise());
    return BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
      if (state.isLoading) {
        LoadingScreen().show(
          context: context,
          text: state.loadingText ?? 'Please wait..',
        );
      } else {
        LoadingScreen().hide();
      }
    }, builder: (context, state) {
      if (state is AuthStateLoggedIn) {
        return const DashboardView();
      } else if (state is AuthStateNeedsActivation) {
        return const ActivateAccountView();
      } else if (state is AuthStateLoggedOut) {
        return const LogInView();
      } else if (state is AuthStateLostPassword) {
        return const LostPasswordView();
      } else if (state is AuthStateVerifying) {
        return SmsVerificationView(member: state.currentUser);
      } else if (state is AuthStateRegistering) {
        return const RegisterView();
      } else {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    });
  }
}

class App extends StatelessWidget {
  const App({
    super.key,
  });

  ThemeData _getTheme(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:

        /// Checks system brightness when user selects system theme mode.
        final brightness =
            SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.light ? lightTheme : darkTheme;
      case ThemeMode.light:
        return lightTheme;

      case ThemeMode.dark:
        return darkTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, state) {
        return MaterialApp(
          title: 'arvo',
          theme: _getTheme(state),
          navigatorKey: navigatorKey,
          // Note: The ErrorHandlerWidget is responsible for catching all top level
          // application errors.
          home: /*AppUpdateAlert( TODO: Uncomment this after package name has been updated.
            child:*/
              const ErrorHandlerWidget(
            child: HomePage(),
            //),
          ),
          routes: {
            editProfilePictureRoute: (context) =>
                const EditProfilePictureView(),
            editProfilePicturesRoute: (context) =>
                const EditProfilePicturesView(),
            settingsRoute: (context) => const SettingsView(),
            viewProfileRoute: (context) => const MemberProfileView(),
            blockedMembersRoute: (context) => const BlockedMembersView(),
            viewPostRoute: (context) => const PostView(),
            serversRoute: (context) => const ServersView(),
            createOrUpdateServerRoute: (context) =>
                const CreateUpdateServerView(),
            perfectMatchQuizStartRoute: (context) =>
                const PerfectMatchQuizStartView(),
            perfectMatchQuizRoute: (context) => const PerfectMatchQuizView(),
            perfectMatchQuizFinishRoute: (context) =>
                const PerfectMatchQuizFinishView(),
            memberFiltersViewRoute: (context) => const MemberFiltersView(),
            memberXProfileOptionsSelectionViewRoute: (context) =>
                const MemberXProfileOptionsSelectionView(),
            editProfileGroupViewRoute: (context) =>
                const EditProfileGroupView(),
            memberSwipeViewRoute: (context) => const MemberSwipeView(),
            subscriptionsViewRoute: (context) => const SubscriptionsView(),
            faqsViewRoute: (context) => const FAQsView(),
            photoVerificationViewRoute: (context) =>
                const PhotoVerificationView(),
            selectLocationViewRoute: (context) =>
                const MemberXProfileLocationSelectionView(),
          },
        );
      },
    );
  }
}
