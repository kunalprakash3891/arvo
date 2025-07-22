import 'dart:async';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/dialogs/generic_dialog.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:country_picker/country_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:arvo/theme/palette.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:arvo/views/log_in_and_registration/pick_country_code.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/sms_verification.dart';
import 'package:nifty_three_bp_app_base/enums/sms_verification_status_type.dart';
import 'package:pinput/pinput.dart';

class SmsVerificationView extends StatefulWidget {
  final Member? member;

  const SmsVerificationView({this.member, super.key});

  @override
  State<SmsVerificationView> createState() => _SmsVerificationViewState();
}

class _SmsVerificationViewState extends State<SmsVerificationView> {
  late final Member? _member;
  late final TextEditingController _phoneNumberTextEditingController;
  late final FocusNode _phoneNumberFocusNode;
  late final FocusNode _smsCodeFocusNode;
  late final GlobalKey<FormState> _formKey;
  bool _autoValidate = false;
  bool _isVerifying = false;
  int? _requestId;
  late Country? _selectedCountry;
  final int _resendWaitTimeSeconds = 30;
  late final ValueNotifier<int> _timerTick;
  Timer? _timer;
  String? _deviceId;
  String? _phoneNumber;
  late final Future _future;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _phoneNumberTextEditingController = TextEditingController();
    _phoneNumberFocusNode = FocusNode();
    _smsCodeFocusNode = FocusNode();
    _formKey = GlobalKey<FormState>();
    _selectedCountry = Country.tryParse(
        WidgetsBinding.instance.platformDispatcher.locale.countryCode ??
            defaultCountryCode);
    _timerTick = ValueNotifier(0);
    _future = _initialiseDeviceId();
  }

  @override
  void dispose() {
    _phoneNumberTextEditingController.dispose();
    _phoneNumberFocusNode.dispose();
    _smsCodeFocusNode.dispose();
    _timerTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCountry == null) {
      throw Exception('Could not parse device country.');
    }

    Widget title = _member == null
        ? const Text('Register')
        : _member.smsVerificationStatus == SmsVerificationStatusType.none
            ? const Text('Add Phone Number')
            : const Text('Update Phone Number');
    return BlocListener<AuthBloc, AuthState>(
      listener: _processAuthState,
      child: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) {
                  return;
                }
                if (mounted) {
                  _exit();
                }
              },
              child: buildErrorScaffold(
                title: title,
                leading: IconButton(
                    onPressed: () {
                      _exit();
                    },
                    icon: Icon(Platform.isIOS
                        ? CupertinoIcons.xmark
                        : Icons.close_rounded)),
                error: snapshot.error,
              ),
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
                  _exit();
                },
                child: Scaffold(
                  appBar: AppBar(
                    title: title,
                    leading: IconButton(
                      onPressed: () async {
                        _exit();
                      },
                      icon: Icon(
                        Platform.isIOS
                            ? CupertinoIcons.xmark
                            : Icons.close_rounded,
                      ),
                    ),
                  ),
                  body: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autoValidate
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _isVerifying
                                ? _buildSmsCodeEntryWidget()
                                : _buildPhoneNumberEntryWidget()
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildPhoneNumberEntryWidget() {
    return Column(
      children: setHeightBetweenWidgets(
        height: 16.0,
        [
          Text(
            _member == null
                ? "Could we have your phone number?"
                : _member.smsVerificationStatus ==
                        SmsVerificationStatusType.none
                    ? "Could we have your phone number?"
                    : "Could we have your new phone number?",
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const Text(
              "We'd like to send you an SMS code to verify your device."),
          TextFormField(
            style: Theme.of(context).textTheme.titleMedium,
            controller: _phoneNumberTextEditingController,
            focusNode: _phoneNumberFocusNode,
            onTap: () {
              if (_phoneNumberFocusNode.hasFocus) {
                _phoneNumberFocusNode.unfocus();
              } else {
                _phoneNumberFocusNode.requestFocus();
              }
            },
            decoration: InputDecoration(
              hintText: 'Phone Number',
              prefixIcon: _buildCountryCodePickerWidget(context),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number cannot be empty.';
              } else if (value.length < 4) {
                // Minimum length is 4 for Saint Helena (Format: +290 XXXX) and Niue (Format: +683 XXXX).
                return 'Phone number is too short.';
              }
              return null;
            },
            onFieldSubmitted: (value) async {
              _sendSMSCode();
            },
            textInputAction: TextInputAction.send,
            keyboardType: TextInputType.number,
            onChanged: (value) {},
            onEditingComplete: () {},
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 12,
          ),
          FilledButton(
            onPressed: () {
              _sendSMSCode();
            },
            child: const Text(
              'Send SMS Code',
            ),
          ),
          const Text(
              "Arvo only uses phone numbers to check that all sign ups are real humans."),
        ],
      ),
    );
  }

  Widget _buildSmsCodeEntryWidget() {
    return Column(
      children: setHeightBetweenWidgets(
        height: 16.0,
        [
          Text(
            "We've sent you an SMS code.",
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const Text(
              "Check your SMS messages for a 6-digit code, then enter it below. The code may take a few seconds to arrive."),
          _buildPinputWidget(),
          ValueListenableBuilder(
            valueListenable: _timerTick,
            builder: (context, value, child) {
              return value == 0
                  ? FilledButton(
                      onPressed: () async {
                        _sendSMSCode();
                      },
                      child: const Text(
                        'Resend Code',
                      ),
                    )
                  : FilledButton(
                      onPressed: null,
                      child: Text(
                        'Resend Code ($value)',
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountryCodePickerWidget(BuildContext context) {
    final selectedCountry = _selectedCountry!;
    final phoneCode = selectedCountry.phoneCode;
    final flagEmoji = selectedCountry.flagEmoji;
    return TextButton(
      onPressed: () {
        pickCountryCode(
            context: context,
            favourites: const [
              'AU',
              'NZ',
            ],
            onSelect: (selectedCountry) {
              _selectedCountry = selectedCountry;
              if (mounted) {
                setState(() {});
              }
            });
      },
      child: Text(
        '$flagEmoji +$phoneCode',
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context)
                .inputDecorationTheme
                .focusedBorder!
                .borderSide
                .color),
      ),
    );
  }

  Widget _buildPinputWidget() {
    final defaultPinTheme = PinTheme(
      width: 56.0,
      height: 56.0,
      textStyle: Theme.of(context).textTheme.titleLarge,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.inverseSurface,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: kBaseColour),
      borderRadius: BorderRadius.circular(8.0),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
    );

    return Pinput(
      length: 6,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      showCursor: true,
      focusNode: _smsCodeFocusNode,
      onTap: () {
        if (_smsCodeFocusNode.hasFocus) {
          _smsCodeFocusNode.unfocus();
        } else {
          _smsCodeFocusNode.requestFocus();
        }
      },
      onCompleted: (code) async {
        _verifySMSCode(code);
      },
    );
  }

  Future _initialiseDeviceId() async {
    _deviceId = await _getDeviceId();
  }

  void _processAuthState(BuildContext context, AuthState state) async {
    if (state.exception != null) {
      await processBlocException(context: context, state: state);
    } else {
      if (state is AuthStateVerifying) {
        if (state.verified) {
          if (_member != null) {
            // Member is in context.
            if (state.verifiedUserId == null ||
                state.verifiedUserId == _member.id) {
              // Phone number has been updated
              const snackBar = SnackBar(
                content: Text("Your phone number has been updated."),
                duration: Duration(seconds: 2),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            } else {
              final contactSupport = await showConfirmDialog(
                context: context,
                title: 'Phone Number Already In Use',
                content:
                    'The phone number you entered is already in use by another user. Please try another phone number, or contact the hello! support team for assistance.',
                confirmText: 'Contact Us',
                cancelText: 'Close',
              );
              if (contactSupport) {
                if (context.mounted) {
                  context.read<AuthBloc>().add(
                        const AuthEventContactUs(),
                      );
                }
              }
            }
            if (context.mounted) {
              context.read<AuthBloc>().add(
                    AuthEventLoggedIn(currentUser: _member),
                  );
            }
          } else {
            if (state.verifiedUserId != null) {
              await showGenericDialog<void>(
                context: context,
                title: 'Already Registered',
                content:
                    'You already have an existing account, please try logging in instead.',
                optionsBuilder: () => {
                  'OK': null,
                },
              );
              if (context.mounted) {
                context.read<AuthBloc>().add(
                      const AuthEventLogOut(),
                    );
              }
            } else {
              if (mounted) {
                // Show snackbar.
                const snackBar = SnackBar(
                  content: Text("Your device has been successfully verified."),
                  duration: Duration(seconds: 2),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                context.read<AuthBloc>().add(
                      AuthEventShouldRegister(deviceId: _deviceId),
                    );
              }
            }
          }
        } else if (state.hasSentVerificationCode) {
          if (state.rejected) {
            await showErrorDialog(context,
                title: 'Incorrect SMS Code',
                text: 'Please check and try entering the code again.');
          } else {
            // Return if timer is already running.
            if (_timer != null) return;
            if (mounted) {
              _timerTick.value = _resendWaitTimeSeconds;
              _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (mounted) {
                  _timerTick.value--;
                  if (_timerTick.value == 0) {
                    timer.cancel();
                    _timer = null;
                  }
                }
              });
            }
          }
          if (mounted) {
            setState(() {
              _isVerifying = true;
              _requestId = state.requestId;
              _smsCodeFocusNode.requestFocus();
            });
          }
        }
      }
    }
  }

  Future<String?> _getDeviceId() async {
    if (Platform.isIOS) {
      // Unique ID on iOS.
      var deviceInfo = await DeviceInfoPlugin().iosInfo;
      return deviceInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      // Unique ID on Android.
      return await const AndroidId().getId();
    }
    return null;
  }

  Future<void> _sendSMSCode() async {
    if (_formKey.currentState!.validate()) {
      _phoneNumber =
          '+${_selectedCountry!.phoneCode}${_phoneNumberTextEditingController.text}';
      final smsCodeRequest =
          SmsCodeRequest(deviceId: _deviceId!, phoneNumber: _phoneNumber!);
      context.read<AuthBloc>().add(AuthEventRequestSmsVerification(
            smsCodeRequest: smsCodeRequest,
            currentUser: _member,
          ));
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

  Future<void> _verifySMSCode(String code) async {
    if (_requestId == null) {
      throw Exception('SMS request identifier is invalid.');
    }

    final verifySmsCodeRequest = VerifySmsCodeRequest(
      deviceId: _deviceId!,
      phoneNumber: _phoneNumber!,
      requestId: _requestId!,
      verificationCode: code,
      // Authenticate only if not logged in.
      generateAuth: _member == null,
    );
    context.read<AuthBloc>().add(AuthEventVerifySmsCode(
          verifySmsCodeRequest: verifySmsCodeRequest,
          currentUser: _member,
        ));
    if (mounted) {
      setState(
        () {
          _autoValidate = false;
        },
      );
    }
  }

  Future<void> _exit() async {
    bool canExit = true;
    if (_phoneNumberTextEditingController.text.isNotEmpty) {
      canExit = await showConfirmDialog(
          context: context,
          content:
              'Exit this page?\n\nAny information that you have entered will be lost.');
    }
    if (canExit && mounted) {
      // Pop if a phone number change is in progress, otherwise go back to log in.
      if (_member != null) {
        if (mounted) {
          context.read<AuthBloc>().add(
                AuthEventLoggedIn(currentUser: _member),
              );
        }
      } else {
        if (mounted) {
          context.read<AuthBloc>().add(
                const AuthEventLogOut(),
              );
        }
      }
    }
  }
}
