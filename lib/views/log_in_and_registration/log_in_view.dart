import 'dart:async';
import 'dart:io';

import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/theme/theme_cubit.dart';
import 'package:arvo/views/log_in_and_registration/background_gradient.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/constants/localised_assets.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/views/animation/fade_animation.dart';
import 'package:nifty_three_bp_app_base/enums/menu_action.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_service.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:nifty_three_bp_app_base/views/widgets/logo_tagline_widget.dart';

class LogInView extends StatefulWidget {
  const LogInView({super.key});

  @override
  State<LogInView> createState() => _LogInViewState();
}

class _LogInViewState extends State<LogInView> {
  DatabaseSystemSetting? _systemSetting;
  late final TextEditingController _username;
  late final TextEditingController _password;
  bool _showPassword = false;
  bool rememberUser = false;
  late final GlobalKey<FormState> _formKey;
  bool _autoValidate = false;
  ProcessedException? _error;
  late final Future _future;
  bool _isLogInVisible = false;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController();
    _password = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _future = _loadSystemSettings();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        _error = await processBlocException(
            context: context, state: state, showDialog: false);
        if (_error != null) {
          if (mounted) {
            setState(() {});
          }
        }
      },
      child: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return buildErrorScaffold(error: snapshot.error);
          }
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Scaffold(
                appBar: AppBar(
                  iconTheme: const IconThemeData(color: Colors.white),
                  backgroundColor: Colors.transparent,
                  actions: [
                    PopupMenuButton<LogInMenuAction>(
                      onSelected: (value) {
                        switch (value) {
                          case LogInMenuAction.contactUs:
                            context.read<AuthBloc>().add(
                                  const AuthEventContactUs(),
                                );
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem<LogInMenuAction>(
                            value: LogInMenuAction.contactUs,
                            child: Text('Contact Us'),
                          ),
                        ];
                      },
                    )
                  ],
                ),
                extendBodyBehindAppBar: true,
                body: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: ValueListenableBuilder(
                    valueListenable: context.read<ThemeCubit>().selectedTheme,
                    builder: (context, value, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: getBackgroundGradientColours(
                                FeatureService.arvo().featureSelectedTheme,
                                context),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            const Positioned(
                              top: 48.0,
                              right: -8.0,
                              child: Image(
                                image: AssetImage(gumTreeBranch),
                                height: 96.0,
                              ),
                            ),
                            const Positioned(
                              bottom: -24.0,
                              child: Image(
                                image: AssetImage(emuBush),
                                height: 120.0,
                              ),
                            ),
                            Center(
                              child: SingleChildScrollView(
                                child: Form(
                                  key: _formKey,
                                  autovalidateMode: _autoValidate
                                      ? AutovalidateMode.onUserInteraction
                                      : AutovalidateMode.disabled,
                                  child: Column(
                                    children: [
                                      FadeAnimation(
                                        0.8,
                                        SizedBox(
                                            width: 320.0,
                                            child: buildLogoTaglineWidget(
                                              logo,
                                              tagline,
                                            )),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(32.0),
                                        child: Column(
                                          children: [
                                            FadeAnimation(
                                              1.6,
                                              _isLogInVisible
                                                  ? _buildLogInWidget()
                                                  : _buildWelcomeWidget(),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      ),
    );
  }

  Widget _buildWelcomeWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _error != null
              ? buildErrorWidget(
                  message: _error.toString(),
                )
              : const SizedBox.shrink(),
          _error != null
              ? const SizedBox(
                  height: 8.0,
                )
              : const SizedBox.shrink(),
          Text(
            "Welcome",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            'Are you a new user?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(
            height: 8.0,
          ),
          FilledButton(
            onPressed: () {
              _register();
            },
            child: const Text(
              'Create Account',
            ),
          ),
          const SizedBox(
            height: 16.0,
          ),
          Text(
            'Do you have an existing account?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(
            height: 8.0,
          ),
          OutlinedButton(
            onPressed: () {
              if (mounted) {
                setState(
                  () {
                    _isLogInVisible = true;
                  },
                );
              }
            },
            child: const Text(
              'Log In',
            ),
          ),
          const SizedBox(
            height: 8.0,
          ),
        ],
      ),
    );
  }

  Widget _buildLogInWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _error != null
              ? buildErrorWidget(
                  message: _error.toString(),
                )
              : const SizedBox.shrink(),
          _error != null
              ? const SizedBox(
                  height: 8.0,
                )
              : const SizedBox.shrink(),
          Text(
            "Log In",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(
            height: 16.0,
          ),
          TextFormField(
            style: Theme.of(context).textTheme.titleMedium,
            controller: _username,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email cannot be empty.';
              }
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
          ),
          const SizedBox(
            height: 16.0,
          ),
          TextFormField(
            style: Theme.of(context).textTheme.titleMedium,
            controller: _password,
            obscureText: !_showPassword,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_showPassword
                    ? Platform.isIOS
                        ? CupertinoIcons.eye_fill
                        : Icons.visibility_off_rounded
                    : Platform.isIOS
                        ? CupertinoIcons.eye_slash_fill
                        : Icons.visibility_rounded),
                onPressed: () {
                  if (mounted) {
                    setState(
                      () {
                        _showPassword = !_showPassword;
                      },
                    );
                  }
                },
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password cannot be empty.';
              }
              return null;
            },
            onFieldSubmitted: (value) async {
              _logIn();
            },
          ),
          const SizedBox(
            height: 16.0,
          ),
          FilledButton(
            onPressed: _logIn,
            child: const Text(
              'Log In',
            ),
          ),
          const SizedBox(
            height: 8.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(
                        const AuthEventLostPassword(),
                      );
                },
                child: const Text("Lost your password?"),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _register();
                  },
                  child: const Text(
                    "Don't have an account? Register here",
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void _register() {
    context.read<AuthBloc>().add(
          const AuthEventShouldVerifySms(),
        );
  }

  Future<void> _logIn() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final username = _username.text;
      final password = _password.text;
      context.read<AuthBloc>().add(
            AuthEventLogIn(
              username,
              password,
            ),
          );
    } else {
      if (mounted) {
        setState(
          () {
            _autoValidate = true;
          },
        );
      }
    }
  }

  Future<void> _loadSystemSettings() async {
    await LocalStorageService.arvo().getSystemSetting().then((result) async {
      _systemSetting = result;
      if (_systemSetting != null) {
        _isLogInVisible = _systemSetting!.hasRegistered;
        if (_systemSetting!.rememberLogIn) {
          _username.text = _systemSetting!.logInUserName;
          _password.text = _systemSetting!.logInPassword;
          // Automatic log in.
          if (_systemSetting!.logInUserName.isNotEmpty &&
              _systemSetting!.logInPassword.isNotEmpty &&
              _systemSetting!.logInToken.isNotEmpty) {
            // User has logged in before, and hasn't logged out so
            // log them in again.
            if (mounted) {
              context.read<AuthBloc>().add(
                    AuthEventLogIn(
                      _username.text,
                      _password.text,
                    ),
                  );
            }
          }
        }
      }
    });
  }
}
