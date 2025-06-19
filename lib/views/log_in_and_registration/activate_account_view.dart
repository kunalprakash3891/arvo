import 'dart:io';

import 'package:arvo/theme/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/constants/localised_assets.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:nifty_three_bp_app_base/views/widgets/logo_tagline_widget.dart';

class ActivateAccountView extends StatefulWidget {
  const ActivateAccountView({super.key});

  @override
  State<ActivateAccountView> createState() => _ActivateAccountViewState();
}

class _ActivateAccountViewState extends State<ActivateAccountView> {
  String? _username;
  String? _password;
  late final TextEditingController _activationKey;
  late final GlobalKey<FormState> _formKey;
  bool _autoValidate = false;
  ProcessedException? _error;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _activationKey = TextEditingController();
  }

  @override
  void dispose() {
    _activationKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    // Bloc should be in this state, read the credentials so it can
    // be used to sign in automatically after activation.
    if (authBloc.state is AuthStateNeedsActivation) {
      final state = authBloc.state as AuthStateNeedsActivation;
      _username = state.username;
      _password = state.password;
    } else {
      throw Exception('Invalid activation credentials.');
    }

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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kBaseGradientStart,
                    kBaseGradientEnd,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Center(
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
                                  "Activate Account",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(
                                  height: 16.0,
                                ),
                                Text(
                                  "You're almost there!\n\nCheck your email for a code to activate your account, and then copy and paste it below.",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(
                                  height: 16.0,
                                ),
                                TextFormField(
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  controller: _activationKey,
                                  autofocus: true,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                      labelText: 'Activation Code'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Activation code cannot be empty.';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (value) async {
                                    _activate();
                                  },
                                ),
                                const SizedBox(
                                  height: 16.0,
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    _activate();
                                  },
                                  child: const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 8.0,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _activate() async {
    if (_formKey.currentState!.validate()) {
      final activationKey = _activationKey.text.trim();
      context.read<AuthBloc>().add(
            AuthEventActivateAccount(
              _username!,
              _password!,
              activationKey,
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

  void _exit() {
    context.read<AuthBloc>().add(
          const AuthEventLogOut(),
        );
  }
}
