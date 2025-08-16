import 'dart:io';

import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/views/shared/background_gradient.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/constants/localised_assets.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:nifty_three_bp_app_base/views/widgets/logo_tagline_widget.dart';
import 'package:app_base/dialogs/password_reset_email_sent_dialog.dart';
import 'package:app_base/extensions/string_extensions.dart';

class LostPasswordView extends StatefulWidget {
  const LostPasswordView({super.key});

  @override
  State<LostPasswordView> createState() => _LostPasswordViewState();
}

class _LostPasswordViewState extends State<LostPasswordView> {
  late final TextEditingController _emailAddress;
  late final GlobalKey<FormState> _formKey;
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _emailAddress = TextEditingController();
  }

  @override
  void dispose() {
    _emailAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateLostPassword) {
          if (state.hasSentEmail) {
            _emailAddress.clear();
            await showPasswordResetSentDialog(context);
            if (context.mounted) {
              context.read<AuthBloc>().add(
                    const AuthEventLogOut(),
                  );
            }
          } else {
            processBlocException(context: context, state: state);
          }
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          _exit();
        },
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: _exit,
              icon:
                  Icon(Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: getBackgroundGradientColours(
                      FeatureService.arvo().featureSelectedTheme, context),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    top: 56.0,
                    right: -8.0,
                    child: Image(
                      image: AssetImage(gumTreeBranch),
                      height: 112.0,
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
                            SizedBox(
                              width: 320.0,
                              child: buildLogoTaglineWidget(
                                logo,
                                tagline,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Lost Password",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    const SizedBox(
                                      height: 16.0,
                                    ),
                                    const Text(
                                      "Enter your email below to receive a link to reset your password.",
                                    ),
                                    const SizedBox(
                                      height: 16.0,
                                    ),
                                    TextFormField(
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                      keyboardType: TextInputType.emailAddress,
                                      autofocus: true,
                                      autocorrect: false,
                                      controller: _emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email Address',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Email Address cannot be empty.';
                                        }
                                        if (!value.isValidEmail()) {
                                          return 'Please enter a valid email address.';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (value) async {
                                        _sendPasswordResetEmail();
                                      },
                                    ),
                                    const SizedBox(
                                      height: 16.0,
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        _sendPasswordResetEmail();
                                      },
                                      child: const Text(
                                        'Send password reset email',
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8.0,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: _exit,
                                          child: const Text(
                                            'Back to Log In page',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailAddress.text;
      context.read<AuthBloc>().add(AuthEventLostPassword(email: email));
      if (mounted) {
        setState(
          () {
            _autoValidate = false;
          },
        );
      }
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

  void _exit() {
    context.read<AuthBloc>().add(
          const AuthEventLogOut(),
        );
  }
}
