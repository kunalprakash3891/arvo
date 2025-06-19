import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/constants/localised_assets.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/ads/ad_service.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/member_delete_request.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_service.dart';
import 'package:arvo/services/development/development_service.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/features/subscription_service.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/services/tips/tip_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:arvo/theme/theme_cubit.dart';
import 'package:arvo/utilities/url_launcher.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/success_dialog.dart';
import 'package:app_base/loading/loading_screen.dart';
import 'package:app_base/theming/theme.dart';
import 'package:nifty_three_bp_app_base/enums/sms_verification_status_type.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final LocalStorageService _localStorageService;
  late final ConnectionService _connectionService;
  late final FeatureService _featureService;
  late final SubscriptionService _subscriptionService;
  late DatabaseSystemSetting _databaseSystemSetting;
  late DatabaseUserSetting _databaseUserSetting;
  late DatabaseServer _databaseServer;
  late Iterable<DatabaseServer> _databaseServers;
  late final AsyncMemoizer _memoizer;
  late final Future<void> _future;
  bool _logOutRequired = false;
  late final ThemeCubit _themeCubit;
  late final TextEditingController _textMessageCountLimitPerThreadController;
  late final TextEditingController _textMaxPendingMessageRepliesController;
  late final TextEditingController _textAdDisplayIntervalController;
  late final String _appVersion;
  late final Member _currentUser;

  @override
  void initState() {
    super.initState();
    _localStorageService = LocalStorageService.arvo();
    _connectionService = ConnectionService.arvo();
    _featureService = FeatureService.arvo();
    _subscriptionService = SubscriptionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _memoizer = AsyncMemoizer();
    _themeCubit = context.read<ThemeCubit>();
    _textMessageCountLimitPerThreadController = TextEditingController();
    _textMaxPendingMessageRepliesController = TextEditingController();
    _textAdDisplayIntervalController = TextEditingController();
    _future = _getSettings();
  }

  @override
  void dispose() {
    _textMessageCountLimitPerThreadController.dispose();
    _textMaxPendingMessageRepliesController.dispose();
    _textAdDisplayIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildErrorScaffold(
            title: const SizedBox.shrink(),
            error: snapshot.error,
          );
        }
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) {
                  return;
                }
                _saveSettings(prompt: true);
              },
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Settings'),
                  leading: IconButton(
                    onPressed: () async {
                      _saveSettings(prompt: true);
                    },
                    icon: Icon(
                      Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _saveSettings();
                      },
                      child: const Text(
                        'Done',
                      ),
                    ),
                  ],
                ),
                body: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: setHeightBetweenWidgets(
                      [
                        _buildLoggingInWidget(),
                        _buildNotificationsWidget(),
                        _buildBlockedMembersListWidget(),
                        _buildThemeSettingsWidget(),
                        _buildAccountWidget(),
                        _buildAboutWidget(),
                        DevelopmentService.arvo().isDevelopment
                            ? _buildDevelopmentWidget()
                            : const SizedBox.shrink(),
                      ],
                      height: 16.0,
                    ),
                  ),
                ),
              ),
            );
          default:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
    );
  }

  Future<void> _getSettings() async {
    _databaseServers = await _localStorageService.getAllServers();

    // Runs once on load, and not on subsequent calls to setState().
    return _memoizer.runOnce(() async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _databaseSystemSetting = await _localStorageService.getSystemSetting();
      _databaseServer =
          await _localStorageService.getServer(_databaseSystemSetting.serverId);
      _databaseUserSetting =
          await _localStorageService.getUserSetting(_currentUser.id);
      _textMessageCountLimitPerThreadController.text =
          _databaseSystemSetting.messageCountLimitPerThread.toString();
      _textMaxPendingMessageRepliesController.text =
          _databaseSystemSetting.maxPendingMessageReplies.toString();
      _textAdDisplayIntervalController.text =
          _databaseSystemSetting.adDisplayInterval.toString();
    });
  }

  Widget _buildLoggingInWidget() {
    return _buildSettingsToggleItemWidget(
      'Remember my log in credentials',
      Switch(
        value: _databaseSystemSetting.rememberLogIn,
        onChanged: (bool value) {
          if (mounted) {
            setState(
              () {
                _databaseSystemSetting.rememberLogIn = value;
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildNotificationsWidget() {
    return _buildSettingsNavigationItemWidget(
      iconData: Platform.isIOS
          ? CupertinoIcons.bell_fill
          : Icons.notifications_rounded,
      title: 'Notifications',
      subTitle: 'Manage app notifications',
      onPressed: () {
        AppSettings.openAppSettings(
          type: AppSettingsType.notification,
        );
      },
    );
  }

  Widget _buildBlockedMembersListWidget() {
    return _buildSettingsNavigationItemWidget(
      iconData: Platform.isIOS
          ? CupertinoIcons.person_crop_circle_fill_badge_exclam
          : Icons.person_off_rounded,
      title: 'Blocked Members',
      subTitle: 'Manage your blocked members',
      onPressed: () {
        Navigator.of(context).pushNamed(
          blockedMembersRoute,
        );
      },
    );
  }

  Widget _buildAccountWidget() {
    return Column(
      children: setHeightBetweenWidgets(
        height: 8.0,
        [
          _buildSectionHeaderWidget(
            'Account',
            Platform.isIOS ? CupertinoIcons.person_fill : Icons.person_rounded,
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5.0,
                  spreadRadius: 1.0,
                  offset: const Offset(1.0, 1.0),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReadOnlyInformationWidget(
                  'Username',
                  _currentUser.userLogin,
                ),
                const SizedBox(height: 8.0),
                _buildReadOnlyInformationWidget(
                  'Email',
                  _connectionService.currentUserEmailAddress,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5.0,
                  spreadRadius: 1.0,
                  offset: const Offset(1.0, 1.0),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    _changePhoneNumber();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 0.0,
                    backgroundColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentUser.smsVerificationStatus ==
                              SmsVerificationStatusType.verified
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Phone\nNumber',
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                                Text(
                                  'Start the SMS verification process\nto update your phone number.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Phone Number',
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                                Text(
                                  'Link your phone number to your account\nthrough SMS verification.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                      Icon(
                        Platform.isIOS
                            ? CupertinoIcons.forward
                            : Icons.arrow_forward_ios_rounded,
                        size: 24.0,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ElevatedButton(
                  onPressed: () async {
                    _changePassword();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 0.0,
                    backgroundColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Password',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          Text(
                            localisedOpenWebsiteToChangePassword,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Icon(
                        Platform.isIOS
                            ? CupertinoIcons.forward
                            : Icons.arrow_forward_ios_rounded,
                        size: 24.0,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                FilledButton(
                  onPressed: () async {
                    _deleteAccount();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kRedColor,
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentWidget() {
    return Column(
      children: [
        _buildSectionHeaderWidget(
          'Development',
          Platform.isIOS
              ? CupertinoIcons.wrench_fill
              : Icons.developer_mode_rounded,
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.all(8.0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5.0,
                spreadRadius: 1.0,
                offset: const Offset(1.0, 1.0),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.exclamationmark_triangle_fill
                        : Icons.warning_rounded,
                    size: 40.0,
                  ),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      'Changing the server will automatically log you out when you leave this page.',
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<DatabaseServer>(
                isExpanded: true,
                value: _databaseServer,
                items: _databaseServers.map<DropdownMenuItem<DatabaseServer>>(
                    (DatabaseServer value) {
                  return DropdownMenuItem<DatabaseServer>(
                    value: value,
                    child: Text(value.url),
                  );
                }).toList(),
                onChanged: (DatabaseServer? newValue) {
                  if (newValue != null) {
                    if (mounted) {
                      setState(
                        () {
                          _databaseServer = newValue;
                          _logOutRequired = _databaseServer.id !=
                              _databaseSystemSetting.serverId;
                        },
                      );
                    }
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Server',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  _awaitReturnFromServersView(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 0.0,
                  backgroundColor: Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Servers',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Text(
                          'Edit available servers',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.forward
                          : Icons.arrow_forward_ios_rounded,
                      size: 24.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        _buildSettingsToggleItemWidget(
          'Show demo users',
          Switch(
            value: _databaseSystemSetting.showDemoUsers,
            onChanged: (bool value) {
              if (mounted) {
                setState(
                  () {
                    _databaseSystemSetting.showDemoUsers = value;
                  },
                );
              }
            },
          ),
        ),
        const SizedBox(height: 16.0),
        _buildSettingsToggleItemWidget(
          'Show contributors',
          Switch(
            value: _databaseSystemSetting.showContributors,
            onChanged: (bool value) {
              if (mounted) {
                setState(
                  () {
                    _databaseSystemSetting.showContributors = value;
                  },
                );
              }
            },
          ),
        ),
        const SizedBox(height: 16.0),
        _buildSettingsToggleItemWidget(
          'Bypass Store',
          Switch(
            value: _databaseSystemSetting.bypassStore,
            onChanged: (bool value) {
              if (mounted) {
                setState(
                  () {
                    _databaseSystemSetting.bypassStore = value;
                  },
                );
              }
            },
          ),
        ),
        const SizedBox(height: 16.0),
        _buildSettingsNumericItemWidget(
            'Messages per Thread', _textMessageCountLimitPerThreadController),
        const SizedBox(height: 16.0),
        _buildSettingsNumericItemWidget('Maximum Pending Message Replies',
            _textMaxPendingMessageRepliesController),
        const SizedBox(height: 16.0),
        _buildSettingsNumericItemWidget(
            'Ad Display Interval (Minutes)', _textAdDisplayIntervalController),
        const SizedBox(height: 16.0),
        _buildFeaturesWidget(),
      ],
    );
  }

  Future<void> _changePhoneNumber() async {
    final saved = await _saveSettings(prompt: true);
    if (saved && mounted) {
      context.read<AuthBloc>().add(
            AuthEventShouldVerifyLoggedInSms(currentUser: _currentUser),
          );
    }
  }

  Future<void> _changePassword() async {
    await browseToUrl(
      context: context,
      _connectionService.serverUrl! + lostPasswordURL,
    );
  }

  Widget _buildSectionHeaderWidget(String title, IconData iconData) {
    return Row(
      children: [
        Icon(
          iconData,
          size: 24.0,
        ),
        const SizedBox(width: 8.0),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildSettingsNavigationItemWidget(
      {IconData? iconData,
      required String title,
      required String subTitle,
      Function()? onPressed}) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
        ),
        child: Row(
          children: [
            if (iconData != null)
              Icon(
                iconData,
                size: 24.0,
              ),
            const SizedBox(
              width: 16.0,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Text(
                    subTitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.forward
                  : Icons.arrow_forward_ios_rounded,
              size: 24.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsToggleItemWidget(String title, Switch toggleSwitch) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          toggleSwitch,
        ],
      ),
    );
  }

  Widget _buildSettingsNumericItemWidget(
      String title, TextEditingController textEditingController) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            controller: textEditingController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyInformationWidget(String title, String? text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (text != null)
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
      ],
    );
  }

  Widget _buildThemeSettingsWidget() {
    return GestureDetector(
      onTap: _featureService.featureThemeControl
          ? null
          : () {
              Navigator.of(context).pushNamed(subscriptionsViewRoute);
            },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5.0,
              spreadRadius: 1.0,
              offset: const Offset(1.0, 1.0),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  _featureService.featureThemeControl
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                              color: kBaseColour,
                              borderRadius: BorderRadius.circular(8.0)),
                          child: const Text(
                            'Premium',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeModeMap.keys.firstWhere((key) =>
                  themeModeMap[key] ==
                  _databaseUserSetting.featureSelectedTheme),
              onChanged: _featureService.featureThemeControl
                  ? (ThemeMode? value) {
                      if (mounted) {
                        setState(() {
                          _setTheme(value!);
                        });
                      }
                    }
                  : null,
              title: Row(
                children: [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.sun_max_fill
                        : Icons.light_mode_rounded,
                    size: 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Light',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeModeMap.keys.firstWhere((key) =>
                  themeModeMap[key] ==
                  _databaseUserSetting.featureSelectedTheme),
              onChanged: _featureService.featureThemeControl
                  ? (ThemeMode? value) {
                      if (mounted) {
                        setState(() {
                          _setTheme(value!);
                        });
                      }
                    }
                  : null,
              title: Row(
                children: [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.moon_fill
                        : Icons.dark_mode_rounded,
                    size: 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Dark',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeModeMap.keys.firstWhere((key) =>
                  themeModeMap[key] ==
                  _databaseUserSetting.featureSelectedTheme),
              onChanged: _featureService.featureThemeControl
                  ? (ThemeMode? value) {
                      if (mounted) {
                        setState(() {
                          _setTheme(value!);
                        });
                      }
                    }
                  : null,
              title: Row(
                children: [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.settings
                        : Icons.manage_accounts_rounded,
                    size: 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'System',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setTheme(ThemeMode themeMode) {
    _themeCubit.updateTheme(themeMode);
    _databaseUserSetting.featureSelectedTheme = themeModeMap[themeMode]!;
  }

  Widget _buildFeaturesWidget() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: setHeightBetweenWidgets(
          [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  "Enable 'Bypass Store' to access these settings. Changes will be applied immediately on save.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(),
              ],
            ),
            Row(
              children: setWidthBetweenWidgets(
                [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.exclamationmark_triangle
                        : Icons.warning_amber_rounded,
                    size: 40.0,
                  ),
                  Flexible(
                    child: Text(
                      'These settings are user and server specific (i.e. if you are switching servers and/or users, you may need to re-apply these changes).',
                      maxLines: 3,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                width: 8.0,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Hide Subscription Ads',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                Switch(
                  value: _databaseUserSetting.featureAdFree,
                  onChanged: _databaseSystemSetting.bypassStore
                      ? (bool value) {
                          if (mounted) {
                            setState(
                              () {
                                _databaseUserSetting.featureAdFree = value;
                              },
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Theme Control',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                Switch(
                  value: _databaseUserSetting.featureThemeControl,
                  onChanged: _databaseSystemSetting.bypassStore
                      ? (bool value) {
                          if (mounted) {
                            setState(
                              () {
                                _databaseUserSetting.featureThemeControl =
                                    value;
                              },
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Profile Photo Search',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                Switch(
                  value: _databaseUserSetting.featurePhotoTypeSearch,
                  onChanged: _databaseSystemSetting.bypassStore
                      ? (bool value) {
                          if (mounted) {
                            setState(
                              () {
                                _databaseUserSetting.featurePhotoTypeSearch =
                                    value;
                              },
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Match Insight',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                Switch(
                  value: _databaseUserSetting.featureMatchInsight,
                  onChanged: _databaseSystemSetting.bypassStore
                      ? (bool value) {
                          if (mounted) {
                            setState(
                              () {
                                _databaseUserSetting.featureMatchInsight =
                                    value;
                              },
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Member Online Indicator',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                Switch(
                  value: _databaseUserSetting.featureMemberOnlineIndicator,
                  onChanged: _databaseSystemSetting.bypassStore
                      ? (bool value) {
                          if (mounted) {
                            setState(
                              () {
                                _databaseUserSetting
                                    .featureMemberOnlineIndicator = value;
                              },
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Custom Message Openers',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                Switch(
                  value: _databaseUserSetting.featureCustomOpeners,
                  onChanged: _databaseSystemSetting.bypassStore
                      ? (bool value) {
                          if (mounted) {
                            setState(
                              () {
                                _databaseUserSetting.featureCustomOpeners =
                                    value;
                              },
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Favourited Me',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                Switch(
                  value: _databaseUserSetting.featureFavouritedMe,
                  onChanged: _databaseSystemSetting.bypassStore
                      ? (bool value) {
                          if (mounted) {
                            setState(
                              () {
                                _databaseUserSetting.featureFavouritedMe =
                                    value;
                              },
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
          height: 8.0,
        ),
      ),
    );
  }

  Widget _buildAboutWidget() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Column(
        children: setHeightBetweenWidgets(
          [
            const SizedBox(
              height: 72.0,
              child: Image(
                image: AssetImage(
                  logoGradientText,
                ),
                fit: BoxFit.cover,
              ),
            ),
            Text(
              localisedAboutText,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontFamily: 'Overpass'),
            ),
            Text(
              "Version $_appVersion",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            OutlinedButton(
              onPressed: () async {
                await browseToUrl(
                  context: context,
                  _connectionService.serverUrl! + contactUsURL,
                );
              },
              child: const Text(
                'Send us a suggestion or report a bug',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          height: 4.0,
        ),
      ),
    );
  }

  Future<bool> _saveSettings({bool prompt = false}) async {
    try {
      bool canSave = await _settingsChanged();

      if (prompt && mounted && canSave) {
        canSave = await showConfirmDialog(
            context: context, content: 'Would you like to save your changes?');
      }

      if (canSave) {
        if (mounted) {
          LoadingScreen().show(
            context: context,
            text: 'Saving...',
          );
        }

        final textMessageCountLimitPerThread =
            int.tryParse(_textMessageCountLimitPerThreadController.text);
        if (textMessageCountLimitPerThread == null ||
            (textMessageCountLimitPerThread < 1)) {
          throw Exception(
              "Invalid value for 'Messages per Thread', must be 1 or greater.");
        }

        final textMaxPendingMessageReplies =
            int.tryParse(_textMaxPendingMessageRepliesController.text);
        if (textMaxPendingMessageReplies == null ||
            (textMaxPendingMessageReplies < 1)) {
          throw Exception(
              "Invalid value for 'Maximum Pending Message Replies', must be 1 or greater.");
        }

        final textAdDisplayInterval =
            int.tryParse(_textAdDisplayIntervalController.text);
        if (textAdDisplayInterval == null || (textAdDisplayInterval < 1)) {
          throw Exception(
              "Invalid value for 'Ad Display Interval', must be 1 or greater.");
        }

        _databaseSystemSetting.serverId = _databaseServer.id;
        if (!_databaseSystemSetting.rememberLogIn) {
          _databaseSystemSetting.logInUserName = '';
          _databaseSystemSetting.logInPassword = '';
        }
        _databaseSystemSetting.messageCountLimitPerThread =
            int.parse(_textMessageCountLimitPerThreadController.text);
        _databaseSystemSetting.maxPendingMessageReplies =
            int.parse(_textMaxPendingMessageRepliesController.text);
        _databaseSystemSetting.adDisplayInterval =
            int.parse(_textAdDisplayIntervalController.text);
        await _localStorageService.updateSystemSetting(_databaseSystemSetting);
        _connectionService.serverUrl = _databaseServer.url;
        _featureService.featureSelectedTheme =
            _databaseUserSetting.featureSelectedTheme;
        await _localStorageService.updateUserSetting(_databaseUserSetting);
        if (_logOutRequired) {
          if (mounted) {
            LoadingScreen().hide();
          }
          if (mounted) {
            context.read<AuthBloc>().add(
                  const AuthEventLogOut(),
                );
          }
        } else {
          // Only reload if not logging out, since logging in will
          // cause a reload anyway.
          // Reload Feature Service parameters.
          await FeatureService.arvo().loadSystemParameters();
          // Reload Subscription.
          await SubscriptionService.arvo().restorePurchases();
          // Reload Ad Service parameters.
          await AdService.arvo().loadSystemParameters();
          // Reload Tip Service parameters.
          await TipService.arvo().loadSystemParameters();
          // Reload Member Directory Service parameters.
          await MemberDirectoryService.arvo().loadSystemParameters();
          // Reload Messaging Handler Service parameters.
          await MessagingHandlerService.arvo().loadSystemParameters();
        }
        if (mounted) {
          LoadingScreen().hide();
        }
        if (mounted) {
          Navigator.of(context).pop();
          // Show snackbar.
          const snackBar = SnackBar(
            content: Text("Settings applied."),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        await _revertSettings();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      return true;
    } on Exception catch (e) {
      if (mounted) {
        LoadingScreen().hide();
      }
      if (mounted) {
        await processException(context: context, exception: e);
      }
      return false;
    }
  }

  Future<bool> _settingsChanged() async {
    final textMessageCountLimitPerThread =
        int.tryParse(_textMessageCountLimitPerThreadController.text);
    if (textMessageCountLimitPerThread !=
        _databaseSystemSetting.messageCountLimitPerThread) {
      return true;
    }

    final textMaxPendingMessageReplies =
        int.tryParse(_textMaxPendingMessageRepliesController.text);
    if (textMaxPendingMessageReplies !=
        _databaseSystemSetting.maxPendingMessageReplies) {
      return true;
    }

    final textAdDisplayInterval =
        int.tryParse(_textAdDisplayIntervalController.text);
    if (textAdDisplayInterval != _databaseSystemSetting.adDisplayInterval) {
      return true;
    }

    _databaseSystemSetting.serverId = _databaseServer.id;

    final databaseSystemSetting = await _localStorageService.getSystemSetting();

    final databaseUserSetting =
        await _localStorageService.getUserSetting(_currentUser.id);

    final systemSettingsChanged =
        databaseSystemSetting != _databaseSystemSetting;
    final userSettingsChanged = databaseUserSetting != _databaseUserSetting;

    return systemSettingsChanged || userSettingsChanged;
  }

  // Reverts any applied changes.
  Future<void> _revertSettings() async {
    var databaseUserSetting =
        await _localStorageService.getUserSetting(_currentUser.id);

    if (databaseUserSetting.featureSelectedTheme !=
        _databaseUserSetting.featureSelectedTheme) {
      _themeCubit.updateTheme(themeModeMap.keys.firstWhere(
          (key) =>
              themeModeMap[key] == databaseUserSetting.featureSelectedTheme,
          orElse: () => ThemeMode.light));
    }
  }

  Future<void> _deleteAccount() async {
    try {
      String confirmationMessage =
          'Are you sure you want to delete your account?\n\n'
          'Deleting your account deletes all data associated with your account, including your profile, favourites and messages.\n\n';

      if (_subscriptionService.purchases.isNotEmpty) {
        confirmationMessage +=
            "Please note that deleting your account does not cancel your subscription. ";

        if (Platform.isIOS) {
          confirmationMessage +=
              "Use the Apple App Store app to cancel your subscription if it is no longer required.\n\n";
        } else {
          confirmationMessage +=
              "Use the Google Play Store app to cancel your subscription if it is no longer required.\n\n";
        }
      }

      confirmationMessage += 'This action cannot be undone.';

      if (await showConfirmDialog(
          context: context, content: confirmationMessage)) {
        if (mounted) {
          if (await showConfirmDialog(
              context: context,
              content: 'Your account is about to be permanently deleted.',
              title: 'Confirm Delete',
              confirmText: 'Delete',
              cancelText: 'Cancel')) {
            if (mounted) {
              LoadingScreen().show(
                context: context,
                text: 'Deleting...',
              );
            }
            // Delete the account.
            await _connectionService.deleteUserAccount(MemberDeleteRequest());
            // Delete local settings.
            await _localStorageService.deleteUserSetting(_currentUser.id);
            _databaseSystemSetting.logInUserName = '';
            _databaseSystemSetting.logInPassword = '';
            await _localStorageService
                .updateSystemSetting(_databaseSystemSetting);
            if (mounted) {
              LoadingScreen().hide();
            }
            if (mounted) {
              await showSuccessDialog(
                  context, localisedAccountDeletedGoodbyeMessage,
                  title: 'Account Deleted');
            }
            if (mounted) {
              context.read<AuthBloc>().add(
                    const AuthEventLogOut(),
                  );
              Navigator.of(context).pop();
            }
          }
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        LoadingScreen().hide();
      }
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  void _awaitReturnFromServersView(BuildContext context) async {
    // Navigate to view and wait for it to return.
    // Pass the current server to prevent it from being modified
    // while we are connected to it.
    await Navigator.of(context).pushNamed(
      serversRoute,
      arguments: _databaseServer,
    );
    // Update this page on return.
    await _getSettings();
    if (mounted) {
      setState(
        () {},
      );
    }
  }
}
