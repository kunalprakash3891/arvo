import 'dart:io';

import 'package:age_calculator/age_calculator.dart';
import 'package:arvo/views/shared/member_xprofile_location_selection_view.dart';
import 'package:arvo/views/shared/x_profile_concat_location_utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/services/development/development_service.dart';
import 'package:arvo/views/shared/confirm_share_contact_information_dialog.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/sign_up_availability.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';
import 'package:arvo/theme/palette.dart';
import 'package:arvo/utilities/url_launcher.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:arvo/views/shared/x_profile_data_input_widget.dart';
import 'package:nifty_three_bp_app_base/views/exceptions/x_profile_exceptions.dart';
import 'package:intl/intl.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/extensions/string_extensions.dart';
import 'package:app_base/loading/loading_screen.dart';
import 'package:zxcvbn/zxcvbn.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

// TODO: Tidy up registration activation email.

class _RegisterViewState extends State<RegisterView> {
  late final ConnectionService _connectionService;
  late final DevelopmentService _developmentService;
  // Raw list of sign-up fields.
  List<XProfileField>? _signUpXProfileFields;
  // Sign-up fields mapped by group.
  final Map<int, Map<int, Widget>> _signUpXProfileGroupFieldsWidgetsMap = {};
  // Headers for specific groups.
  /*final Map<int, String> _signUpXProfileGroupHeaderMap = {
    xProfileGroupAboutMe: "Let's start with the important stuff.",
    xProfileGroupBackground: "Add a little more detail.",
    xProfileGroupInterests: "Finally, tell everyone what makes you, you.",
  };*/
  // Alternate sign-up friendly names for fields.
  final Map<int, String> _xProfileFieldsAlternateNameMap = {
    xProfileFieldName: "What's your first name?",
    xProfileFieldGender: "What gender do you identify as?",
    xProfileFieldSexualOrientation:
        "Which sexual orientation do you identify as?",
    xProfileFieldLocation: "Where are you located?",
    xProfileFieldStatus: "What's your relationship status?",
    xProfileFieldOftenAlcohol: "How often do you drink alcohol?",
  };
  final Map<int, List<TextInputFormatter>> _xProfileFieldsInputFormattersMap = {
    xProfileFieldName: [
      FilteringTextInputFormatter.allow(RegExp("[a-zA-Z -]"))
    ],
  };
  final Map<int, TextCapitalization> _xProfileFieldsTextCapitalisation = {
    xProfileFieldName: TextCapitalization.words,
  };
  // Add default keys for fixed account form.
  late final Map<int, GlobalKey<FormState>?> _formKeysMap;
  late final Map<int, bool> _autoValidateMap;
  late final Map<int, FocusNode> _focusMap;
  final Map<int, TextEditingController> _textEditingControllers = {};
  final Map<int, XProfileField?> _dropdownSelections = {};
  final Map<int, XProfileFieldOptionsItem?> _multiSelectSelections = {};
  final ValueNotifier<XProfileFieldOptionsItem?> _multiSelectFieldChanged =
      ValueNotifier(null);
  final ValueNotifier<XProfileField?> _dropDownSelectFieldChanged =
      ValueNotifier(null);
  late final TextEditingController _textUserNameEditingController;
  late final TextEditingController _textEmailEditingController;
  late final TextEditingController _textPasswordEditingController;
  late final TextEditingController _textPasswordConfirmEditingController;
  late final FocusNode _userNameFocusNode;
  late final FocusNode _emailAddressFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;
  String _enteredUserNameText = '';
  String _enteredEmailAddressText = '';
  String _enteredPasswordText = '';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  DateTime? _selectedBirthdate;
  final ValueNotifier<bool> _birthdateChanged = ValueNotifier(false);
  ProcessedException? _error;
  late final Future _future;
  double _progress = 0;
  late final PageController _pageController;
  int _index = 0;
  // Set to 1 for default account form.
  int _pageCount = 0;
  // Set this value to the count of pages that appear before the XProfile Group forms.
  final int _xProfilePageOffset = 1;
  final Map<String, Object> _registrationData = {"context": "edit"};
  bool _termsAccepted = false;
  late final Zxcvbn zxcvbn;
  double? _passwordStrength;
  String? _passwordWarning;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _developmentService = DevelopmentService.arvo();
    _pageController = PageController();
    _textUserNameEditingController = TextEditingController();
    _textEmailEditingController = TextEditingController();
    _textPasswordEditingController = TextEditingController();
    _textPasswordConfirmEditingController = TextEditingController();
    _userNameFocusNode = FocusNode();
    _emailAddressFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
    // Add default keys for fixed account form.
    _formKeysMap = {
      0: GlobalKey<FormState>(),
    };
    _autoValidateMap = {
      0: false,
    };
    _focusMap = {
      0: FocusNode(),
    };
    zxcvbn = Zxcvbn();
    _future = _buildXProfileForms();
  }

  @override
  void dispose() {
    _textUserNameEditingController.dispose();
    _textEmailEditingController.dispose();
    _textPasswordEditingController.dispose();
    _textPasswordConfirmEditingController.dispose();
    _userNameFocusNode.dispose();
    _emailAddressFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    for (var value in _textEditingControllers.values) {
      value.dispose();
    }
    _birthdateChanged.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    // Bloc should be in this state, read the device ID.
    if (authBloc.state is AuthStateRegistering) {
      final state = authBloc.state as AuthStateRegistering;
      _deviceId = state.deviceId;
    }

    const title = Text('Register');
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        _error = await processBlocException(
            context: context, state: state, showDialog: false);
        if (_error != null) {
          if (context.mounted) {
            await showErrorDialog(context, text: _error!.message);
          }
        }
      },
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
                  context.read<AuthBloc>().add(
                        const AuthEventLogOut(),
                      );
                }
              },
              child: buildErrorScaffold(
                title: title,
                leading: IconButton(
                    onPressed: () {
                      if (mounted) {
                        context.read<AuthBloc>().add(
                              const AuthEventLogOut(),
                            );
                      }
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
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(5.0),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            minHeight: 5.0,
                            value: _progress,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    actions: _signUpXProfileFields == null
                        ? null
                        : [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                'Step ${_index + 1}/$_pageCount',
                                style: Theme.of(context).textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                  ),
                  /*floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                floatingActionButton: _signUpXProfileFields == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildFloatingButtonWidget(),
                      ),*/
                  body: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: _buildRegistrationWidget(),
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

  /*Widget _buildFloatingButtonWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _index == 0
            ? const SizedBox.shrink()
            : FloatingActionButton(
                heroTag: null,
                shape: const CircleBorder(),
                onPressed: _navigateToPreviousPage,
                child: Icon(
                  Platform.isIOS ? CupertinoIcons.back :  Icons.navigate_before_rounded,
                  size: 32.0,
                ),
              ),
        (_index + 1 == _pageCount)
            ? FloatingActionButton(
                heroTag: null,
                shape: const CircleBorder(),
                onPressed: _navigateToNextPage,
                child: Icon(
                 Platform.isIOS ? CupertinoIcons.check_mark :  Icons.done_rounded,
                  size: 32.0,
                ),
              )
            : FloatingActionButton(
                heroTag: null,
                shape: const CircleBorder(),
                onPressed: _navigateToNextPage,
                child: Icon(
                  Platform.isIOS ? CupertinoIcons.forward : Icons.navigate_next_rounded,
                  size: 32.0,
                ),
              )
      ],
    );
  }*/

  Future<void> _buildXProfileForms() async {
    await _connectionService.getXProfileSignUpFields().then((result) {
      _signUpXProfileFields = result;
    });
    if (_signUpXProfileFields == null) {
      throw Exception('Invalid sign up field data.');
    }

    var groupdIds = <int>{};
    _signUpXProfileFields!
        .where((field) => groupdIds.add(field.groupId))
        .toList();

    for (int i = 0; i < groupdIds.length; i++) {
      _formKeysMap[i + 1] ??= GlobalKey<FormState>();
      _autoValidateMap[i + 1] ??= false;
      _focusMap[i + 1] ??= FocusNode();
      final groupId = groupdIds.elementAt(i);
      _signUpXProfileGroupFieldsWidgetsMap[groupId] = _buildXProfileGroupForm(
          groupId,
          _signUpXProfileFields!
              .where((field) => field.groupId == groupId)
              .toList());
    }

    _pageCount =
        _signUpXProfileGroupFieldsWidgetsMap.length + _xProfilePageOffset;
    if (mounted) {
      setState(() {
        _progress = 1 / _pageCount;
      });
    }
  }

  Widget _buildAccountDetailsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeysMap[0]!,
        autovalidateMode: _autoValidateMap[0]!
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: setHeightBetweenWidgets(
            [
              Container(
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create your username',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                        'You can use letters and numbers. Minimum of 4 characters, maximum of 25.'),
                    TextFormField(
                        style: Theme.of(context).textTheme.titleMedium,
                        controller: _textUserNameEditingController,
                        focusNode: _userNameFocusNode,
                        maxLines: 1,
                        maxLength: 25,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          counterText: _enteredUserNameText.length < 4
                              ? 'Min 4, max 25'
                              : '${_enteredUserNameText.length.toString()}/Max 25',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp("[0-9a-zA-Z]")),
                        ],
                        onChanged: (value) {
                          if (mounted) {
                            setState(
                              () {
                                _enteredUserNameText = value;
                              },
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a username.';
                          } else if (value.length < 4) {
                            return 'Your username is too short.';
                          }
                          return null;
                        },
                        onEditingComplete: _emailAddressFocusNode.requestFocus),
                  ],
                ),
              ),
              Container(
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your email',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text('Your email must be valid and belong to you.'),
                    TextFormField(
                        style: Theme.of(context).textTheme.titleMedium,
                        controller: _textEmailEditingController,
                        focusNode: _emailAddressFocusNode,
                        maxLines: 1,
                        maxLength: 320,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email Address',
                          counterText: "",
                        ),
                        onChanged: (value) {
                          if (mounted) {
                            setState(
                              () {
                                _enteredEmailAddressText = value;
                              },
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.isValidEmail()) {
                            return 'Please enter a valid email.';
                          }
                          return null;
                        },
                        onEditingComplete: _passwordFocusNode.requestFocus),
                  ],
                ),
              ),
              Container(
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a strong password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: setWidthBetweenWidgets(
                        width: 4.0,
                        [
                          Expanded(
                            child: _buildPasswordChecklistWidget(),
                          ),
                          _buildPasswordStrengthWidget(_passwordStrength),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    TextFormField(
                      style: Theme.of(context).textTheme.titleMedium,
                      controller: _textPasswordEditingController,
                      focusNode: _passwordFocusNode,
                      obscureText: !_showPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Password',
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
                      onChanged: (value) {
                        _evaluatePasswordStength(value);
                        if (mounted) {
                          setState(
                            () {
                              _enteredPasswordText = value;
                            },
                          );
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a valid password.';
                        } else if (value.contains(r'\')) {
                          return "Backslash (\\) character cannot be used.";
                        } else {
                          if (_passwordWarning != null &&
                              _passwordWarning!.isNotEmpty) {
                            return _passwordWarning;
                          }
                          return null;
                        }
                      },
                      onEditingComplete: _confirmPasswordFocusNode.requestFocus,
                    ),
                  ],
                ),
              ),
              Container(
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm your password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text('Type your password again.'),
                    TextFormField(
                      style: Theme.of(context).textTheme.titleMedium,
                      controller: _textPasswordConfirmEditingController,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: !_showConfirmPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'Confirm password',
                        suffixIcon: IconButton(
                          icon: Icon(_showConfirmPassword
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
                                  _showConfirmPassword = !_showConfirmPassword;
                                },
                              );
                            }
                          },
                        ),
                      ),
                      onChanged: (value) {
                        if (mounted) {
                          setState(
                            () {},
                          );
                        }
                      },
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            value != _enteredPasswordText) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              _buildTermsAcceptanceWidget(),
              // Add SizedBox to provide space for floating action buttons.
              /*const SizedBox(
                height: 64.0,
              ),*/
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        _navigateToNextPage();
                      },
                      child: const Text(
                        'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            height: 16.0,
          ),
        ),
      ),
    );
  }

  void _evaluatePasswordStength(String password) {
    if (password.isNotEmpty) {
      final criteraWarning = _checkPasswordMeetsCriteria(password);
      if (criteraWarning != null) {
        _passwordStrength = 1;
        _passwordWarning = criteraWarning;
      } else {
        final result = zxcvbn.evaluate(password);
        _passwordStrength = result.score;
        _passwordWarning = result.feedback.warning;
      }
    } else {
      _passwordStrength = null;
      _passwordWarning = null;
    }
  }

  String? _checkPasswordMeetsCriteria(String password) {
    /*
    1 lower case character,
    1 upper case character,
    1 numeric character,
    1 special character,
    12 characters in length,
    Common allow ( ! @ # $ & * ~ )
    */

    if (!password.containsLowerCase()) {
      return 'Must contain at least 1 lower case character.';
    }

    if (!password.containsUpperCase()) {
      return 'Must contain at least 1 upper case character.';
    }

    if (!password.containsNumbers()) {
      return 'Must contain at least 1 numeric character.';
    }

    if (!password.containsSpecialCharacters()) {
      return 'Must contain at least 1 special character.';
    }

    if (password.length < 12) {
      return 'Your password is too short.';
    }

    return null;
  }

  String _getPassordStrengthDescription(double? strength) {
    return strength == null
        ? 'Weak'
        : strength >= 4.0
            ? 'Strong'
            : strength >= 2.0
                ? 'Medium'
                : 'Weak';
  }

  Color _getPasswordStrengthColour(double? strength) {
    return strength == null
        ? kBaseCoralSunset
        : strength >= 4.0
            ? kBaseEucalyptusGreen
            : strength >= 2.0
                ? kBaseOutbackOchre
                : kBaseCoralSunset;
  }

  Widget _buildPasswordStrengthWidget(double? strength) {
    return Container(
      width: 72.0,
      decoration: BoxDecoration(
        color: _getPasswordStrengthColour(strength).withOpacity(0.2),
        border: Border.all(
          color: _getPasswordStrengthColour(strength),
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          _getPassordStrengthDescription(strength),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _getPasswordStrengthColour(strength),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordChecklistWidget() {
    return Column(
      children: setHeightBetweenWidgets(
        [
          _buildPasswordChecklistItemWidget(
            '1 lower case character [a-z]',
            _textPasswordEditingController.text.containsLowerCase(),
          ),
          _buildPasswordChecklistItemWidget(
            '1 upper case character [A-Z]',
            _textPasswordEditingController.text.containsUpperCase(),
          ),
          _buildPasswordChecklistItemWidget(
            '1 numeric character [1-9]',
            _textPasswordEditingController.text.containsNumbers(),
          ),
          _buildPasswordChecklistItemWidget(
            r"1 special character [e.g. ! @ # $]",
            _textPasswordEditingController.text.containsSpecialCharacters(),
          ),
          _buildPasswordChecklistItemWidget(
            '12 characters minimum',
            _textPasswordEditingController.text.length >= 12,
          ),
        ],
        height: 8.0,
      ),
    );
  }

  Widget _buildPasswordChecklistItemWidget(String description, bool checked) {
    return Row(
      children: setWidthBetweenWidgets(
        width: 4.0,
        [
          Icon(
            checked
                ? Platform.isIOS
                    ? CupertinoIcons.check_mark_circled
                    : Icons.check_circle_outline_rounded
                : Platform.isIOS
                    ? CupertinoIcons.circle
                    : Icons.radio_button_off_rounded,
            size: 24.0,
            color: checked
                ? kActionColour
                : Theme.of(context)
                    .inputDecorationTheme
                    .focusedBorder!
                    .borderSide
                    .color,
          ),
          Flexible(child: Text(description)),
        ],
      ),
    );
  }

  Widget _buildTermsAcceptanceWidget() {
    return Column(
      children: [
        Container(
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
          child: FormField(
            initialValue: _termsAccepted,
            validator: (value) {
              if (value == false) {
                return 'Terms and Conditions is a required field.';
              }
              return null;
            },
            builder: (FormFieldState<bool> field) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Terms and Conditions",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  InputDecorator(
                    decoration: InputDecoration(
                      errorText: field.errorText,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                const TextSpan(
                                    text: 'I have read and accepted the '),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      await browseToUrl(
                                        context: context,
                                        _connectionService.serverUrl! +
                                            termsAndConditionsURL,
                                      );
                                    },
                                ),
                                const TextSpan(
                                    text: ' and its linked policies.'),
                              ],
                            ),
                          ),
                        ),
                        Switch(
                          value: _termsAccepted,
                          onChanged: (bool value) {
                            if (mounted) {
                              setState(
                                () {
                                  _termsAccepted = value;
                                  field.didChange(value);
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        )
      ],
    );
  }

  Map<int, Widget> _buildXProfileGroupForm(
      int xProfileGroupId, List<XProfileField> xProfileSignUpFields) {
    // Add editable fields.
    Map<int, Widget> profileGroupDataWidgets = {};
    for (final field in xProfileSignUpFields) {
      if (mounted) {
        switch (field.type) {
          case fieldTypeTextBox:
          case fieldTypeTextArea:
            profileGroupDataWidgets[field.id] = buildXProfileTextBoxWidget(
              context,
              xProfileGroupId,
              field,
              _textEditingControllers,
              alternateName: _xProfileFieldsAlternateNameMap[field.id],
              inputFormatters: _xProfileFieldsInputFormattersMap[field.id],
              textCapitalisation: _xProfileFieldsTextCapitalisation[field.id],
            );
          case fieldTypeSelectBox:
            if (field.id == xProfileFieldLocation) {
              profileGroupDataWidgets[field.id] =
                  buildXProfileNavigateToSelectDisplayWidget(
                context,
                field,
                _dropdownSelections,
                (context, xProfileField, selectedOption) =>
                    _awaitReturnFromLocationSelectionView(
                  context,
                  field,
                  _dropdownSelections[field.id],
                ),
                _dropDownSelectFieldChanged,
                alternateName: _xProfileFieldsAlternateNameMap[field.id],
                textDisplayFormatter: locationDisplayFormatter,
              );
              continue;
            }
            profileGroupDataWidgets[field.id] =
                buildRegistrationXProfileSelectBoxWidget(
              context,
              field,
              _dropdownSelections,
              (newValue) => {
                if (newValue != null)
                  {
                    if (mounted)
                      {
                        setState(
                          () {
                            _dropdownSelections[field.id] = newValue;
                          },
                        )
                      }
                  }
              },
              alternateName: _xProfileFieldsAlternateNameMap[field.id],
            );
          case fieldTypeCheckBox:
          case fieldTypeMultiSelectBox:
            profileGroupDataWidgets[field.id] =
                buildXProfileMultiSelectDisplayWidget(
                    context,
                    xProfileGroupId,
                    field,
                    _multiSelectSelections,
                    (context, options) =>
                        _awaitReturnFromOptionsSelectionView(context, options),
                    _multiSelectFieldChanged);
          case fieldTypeDateBox:
            profileGroupDataWidgets[field.id] =
                _buildRegistrationXProfileBirthdateTimeWidget(field);
        }
      }
    }

    return profileGroupDataWidgets;
  }

  Widget _buildRegistrationXProfileBirthdateTimeWidget(
      XProfileField xProfileFieldBirthdate) {
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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "When is your birthday?",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            (xProfileFieldBirthdate.description.rendered != null &&
                    xProfileFieldBirthdate.description.rendered!.isNotEmpty)
                ? Text(
                    xProfileFieldBirthdate.description.rendered!.parseHTML(),
                  )
                : const SizedBox.shrink(),
            OutlinedButton(
              onPressed: () {
                _selectDate(context);
              },
              child: ValueListenableBuilder(
                valueListenable: _birthdateChanged,
                builder: (context, value, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        _selectedBirthdate != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_selectedBirthdate!)
                            : 'Day/Month/Year',
                      ),
                      if (_selectedBirthdate != null)
                        Text(
                          "${AgeCalculator.age(_selectedBirthdate!).years} years",
                        )
                    ],
                  );
                },
              ),
            ),
          ]),
    );
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ??
          DateTime(DateTime.now().year - 18), // Refer step 1
      firstDate: DateTime(DateTime.now().year - 100),
      lastDate: DateTime(DateTime.now().year),
    );
    if (picked != null) {
      _selectedBirthdate = picked;
      if (mounted) _birthdateChanged.value = !_birthdateChanged.value;
    }
  }

  void _awaitReturnFromOptionsSelectionView(BuildContext context,
      XProfileFieldOptionsItem xProfileFieldOptionsItem) async {
    final xProfileFieldOptionsItemOriginal =
        XProfileFieldOptionsItem.clone(xProfileFieldOptionsItem);
    // Navigate to view and wait for it to return.
    await Navigator.of(context).pushNamed(
        memberXProfileOptionsSelectionViewRoute,
        arguments: xProfileFieldOptionsItem);
    // Update this page on return.
    if (xProfileFieldOptionsItemOriginal != xProfileFieldOptionsItem) {
      if (mounted) _multiSelectFieldChanged.value = xProfileFieldOptionsItem;
    }
    // Clear the notifier value so that it can be triggered again.
    if (mounted) _multiSelectFieldChanged.value = null;
  }

  void _awaitReturnFromLocationSelectionView(
    BuildContext context,
    XProfileField xProfileFieldLocation,
    XProfileField? xProfileFieldSelectedLocation,
  ) async {
    final xProfileFieldSelectedLocationOriginal =
        xProfileFieldSelectedLocation != null
            ? XProfileField.clone(xProfileFieldSelectedLocation)
            : null;
    // Navigate to view and wait for it to return.
    final locationOptions = XProfileLocationSelectionOptions(
        xProfileFieldLocation: xProfileFieldLocation,
        xProfileFieldSelectedLocation: xProfileFieldSelectedLocation);
    await Navigator.of(context).pushNamed(
      selectLocationViewRoute,
      arguments: locationOptions,
    );
    // Update this page on return.
    if (locationOptions.xProfileFieldSelectedLocation !=
        xProfileFieldSelectedLocationOriginal) {
      _dropdownSelections[xProfileFieldLocation.id] =
          locationOptions.xProfileFieldSelectedLocation;
      if (mounted) {
        _dropDownSelectFieldChanged.value =
            locationOptions.xProfileFieldSelectedLocation;
      }
    }
    // Clear the notifier value so that it can be triggered again.
    if (mounted) _dropDownSelectFieldChanged.value = null;
  }

  Widget _buildRegistrationWidget() {
    return _signUpXProfileFields == null ||
            _signUpXProfileGroupFieldsWidgetsMap.isEmpty
        ? buildCenteredErrorWidget(
            message:
                'Sorry, this page could not be loaded, please try again later.\n\nPress the close button to exit.')
        : PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              _index = index;
              FocusScope.of(context).requestFocus(_focusMap[index]);
              if (index > 0) {
                int key = _signUpXProfileGroupFieldsWidgetsMap.keys
                    .elementAt(index - _xProfilePageOffset);
                final xProfileGroup = _signUpXProfileGroupFieldsWidgetsMap[key];
                // Rebuild DropdownButtonFormField widgets since they get reset on page change.
                if (xProfileGroup != null) {
                  for (final key in xProfileGroup.keys) {
                    final field = _signUpXProfileFields!
                        .where((field) => field.id == key)
                        .firstOrNull;
                    if (field != null) {
                      if (field.type == fieldTypeSelectBox) {
                        if (field.id == xProfileFieldLocation) {
                          continue;
                        }
                        xProfileGroup[field.id] =
                            buildRegistrationXProfileSelectBoxWidget(
                          context,
                          field,
                          _dropdownSelections,
                          (newValue) => {
                            if (newValue != null)
                              {
                                if (mounted)
                                  {
                                    setState(
                                      () {
                                        _dropdownSelections[field.id] =
                                            newValue;
                                      },
                                    )
                                  }
                              }
                          },
                          alternateName:
                              _xProfileFieldsAlternateNameMap[field.id],
                        );
                      }
                    }
                  }
                }
              }
              if (mounted) {
                setState(() {
                  _progress = (index + 1) / _pageCount;
                });
              }
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAccountDetailsForm();
              } else {
                int key = _signUpXProfileGroupFieldsWidgetsMap.keys
                    .elementAt(index - _xProfilePageOffset);
                final group = _signUpXProfileGroupFieldsWidgetsMap[key];
                return _buildEditProfileGroupWidget(context, index, key, group);
              }
            },
            itemCount: _pageCount,
          );
  }

  Widget _buildEditProfileGroupWidget(BuildContext context, int index,
      int groupId, Map<int, Widget>? profileGroupDataWidgets) {
    return profileGroupDataWidgets == null
        ? const SizedBox.shrink()
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKeysMap[index]!,
                autovalidateMode: _autoValidateMap[index]!
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  children: setHeightBetweenWidgets(
                    [
                      /*_signUpXProfileGroupHeaderMap[groupId] == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _signUpXProfileGroupHeaderMap[groupId]!,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                          ),*/
                      Column(
                        children: setHeightBetweenWidgets(
                          profileGroupDataWidgets.values.toList(),
                          height: 16.0,
                        ),
                      ),
                      // Add SizedBox to provide space for floating action buttons.
                      /*const SizedBox(
                      height: 64.0,
                    ),*/
                      Row(
                        children: setWidthBetweenWidgets(
                          [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  _navigateToPreviousPage();
                                },
                                child: const Text(
                                  'Previous',
                                ),
                              ),
                            ),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  _navigateToNextPage();
                                },
                                child: Text(
                                  (_index + 1 == _pageCount)
                                      ? 'Finish'
                                      : 'Next',
                                ),
                              ),
                            ),
                          ],
                          width: 4.0,
                        ),
                      ),
                    ],
                    height: 16.0,
                  ),
                ),
              ),
            ),
          );
  }

  void _navigateToPreviousPage() {
    _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn);
  }

  void _navigateToNextPage() async {
    try {
      // Unfocus all fields.
      FocusManager.instance.primaryFocus?.unfocus();
      if (_formKeysMap[_index]!.currentState!.validate()) {
        if (await _validateXProfileFields()) {
          if (_index + 1 == _pageCount) {
            await _register();
          } else {
            _pageController.nextPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn);
          }
        }
      } else {
        if (mounted) {
          setState(
            () {
              _autoValidateMap[_index] = true;
            },
          );
        }
        throw EmptyRequiredFieldException(
          title: 'Required Fields',
          'Please complete all required fields.',
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        LoadingScreen().hide();
      }
      if (e is EmptyRequiredFieldException) {
        if (mounted) {
          await showErrorDialog(context, title: e.title, text: e.message);
        }
      } else if (e is FieldContainsProfanityException) {
        if (mounted) {
          await showErrorDialog(context, title: e.title, text: e.message);
        }
      } else if (e is FieldContainsUrlException) {
        if (mounted) {
          await showErrorDialog(context, title: e.title, text: e.message);
        }
      } else if (e is TextFieldValidationException) {
        if (mounted) {
          await showErrorDialog(context, title: e.title, text: e.message);
        }
      } else if (e is SignUpAvailabilityException) {
        if (mounted) {
          if (await showConfirmDialog(
            context: context,
            title: e.title,
            content: e.message,
            confirmText: 'Back to Log In',
            cancelText: 'Cancel',
          )) {
            _exit();
          }
        }
      } else {
        if (mounted) {
          await processException(context: context, exception: e);
        }
      }
    }
  }

  Future<bool> _validateXProfileFields() async {
    List<int> profileGroupFieldIdsWithContactInformation = [];
    if (mounted) {
      LoadingScreen().show(context: context, text: 'Validating...');
    }
    if (_index == 0) {
      // Bypass text validation if development.
      if (!_developmentService.isDevelopment) {
        final bannedUserNameText =
            _enteredUserNameText.containsBannedUserNameText();
        if (bannedUserNameText.isNotEmpty) {
          throw TextFieldValidationException(
            title: 'Flagged Text',
            message:
                "Your username contains the following text which is not accepted. Please try another username.\n\n"
                "${bannedUserNameText.join('\n')}",
          );
        }

        final bannedEmailAddressText =
            _enteredEmailAddressText.containsBannedEmailAddressText();
        if (bannedEmailAddressText.isNotEmpty) {
          throw TextFieldValidationException(
            title: 'Flagged Email Address',
            message:
                "Your email address contains the following text or domains which are not accepted. Please use another email address.\n\n"
                "${bannedEmailAddressText.join('\n')}",
          );
        }

        final invalidEmailAddressText =
            _enteredEmailAddressText.containsInvalidEmailAddressText();
        if (invalidEmailAddressText.isNotEmpty) {
          throw TextFieldValidationException(
            title: 'Invalid Email Address',
            message:
                "Your email address contains the following text or domains which are invalid. Please use another email address.\n\n"
                "${invalidEmailAddressText.join('\n')}",
          );
        }

        if (await _connectionService.checkDisposableEmail(
            _enteredEmailAddressText, true)) {
          throw TextFieldValidationException(
            title: 'Disposable Email Address',
            message:
                "Disposable email addresses are not accepted. Please use another email address.\n\n"
                "${bannedEmailAddressText.join('\n')}",
          );
        }

        final bannedPasswordText =
            _enteredPasswordText.containsBannedPasswordText();
        if (bannedPasswordText.isNotEmpty) {
          throw TextFieldValidationException(
            title: "Insecure Password",
            message:
                "Your password contains the following text which is not secure. Please use another password.\n\n"
                "${bannedPasswordText.join('\n')}",
          );
        }
      }

      _registrationData['user_login'] = _enteredUserNameText;
      _registrationData['user_email'] = _enteredEmailAddressText.toLowerCase();
      _registrationData['password'] = _enteredPasswordText;
      // Terms Acceptance.
      _registrationData['field_2996'] = '1';
      // Device ID.
      _registrationData['device_id'] = _deviceId ?? '';
    } else {
      int key = _signUpXProfileGroupFieldsWidgetsMap.keys
          .elementAt(_index - _xProfilePageOffset);
      final xProfileGroup = _signUpXProfileGroupFieldsWidgetsMap[key];

      if (xProfileGroup == null) throw Exception('Invalid form group.');

      final profileGroupFieldIds = xProfileGroup.keys;

      for (final profileGroupFieldId in profileGroupFieldIds) {
        final profileGroupField = _signUpXProfileFields!
            .where((field) => field.id == profileGroupFieldId)
            .firstOrNull;

        if (profileGroupField == null) {
          throw Exception(
              'Group field does not exist in list of sign up fields.');
        }

        if (profileGroupFieldId == xProfileFieldBirthdate) {
          if (_selectedBirthdate == null) {
            throw EmptyRequiredFieldException(
                'Please enter a date for your birthday.');
          }
          if (AgeCalculator.age(_selectedBirthdate!).years < 18) {
            throw EmptyRequiredFieldException(
                'You must be at least 18 years old to register.');
          }
          _registrationData['field_$profileGroupFieldId'] =
              DateFormat('yyyy-MM-dd 00:00:00').format(_selectedBirthdate!);
        } else if (_textEditingControllers[profileGroupFieldId] != null) {
          final newValue = _textEditingControllers[profileGroupFieldId]?.text;
          if (profileGroupField.isRequired &&
              (newValue == null || newValue.isEmpty)) {
            throw EmptyRequiredFieldException(
                "'${profileGroupField.name}' cannot be empty.");
          }
          if (profileGroupFieldId == xProfileFieldName) {
            final bannedNames = newValue?.containsBannedNameText();
            if (bannedNames != null && bannedNames.isNotEmpty) {
              throw TextFieldValidationException(
                title: 'Flagged Text',
                message:
                    "Your name contains the following text which is not accepted. Please remove or replace before proceeding.\n\n"
                    "${bannedNames.join('\n')}",
              );
            }
          }
          final profanities = newValue?.containsProfanity();
          if (profanities != null && profanities.isNotEmpty) {
            throw FieldContainsProfanityException(
                "'${profileGroupField.name}' contains the following text which is not accepted, please remove first before proceeding.\n\n"
                "${profanities.join('\n')}");
          }
          final urls = newValue?.containsUrlText();
          if (urls != null && urls.isNotEmpty) {
            throw FieldContainsUrlException(
                "'${profileGroupField.name}' appears to contain the following text which may be an external link, please remove first before proceeding.\n\n"
                "${urls.join('\n')}");
          }
          // Add any fields that may have contact information for prompting at the end.
          final contactDetails = newValue?.containsContactDetails();
          if (contactDetails != null && contactDetails.isNotEmpty) {
            profileGroupFieldIdsWithContactInformation.add(profileGroupFieldId);
          }
          // NOTE: 'user_name' value should be the same as the name xProfile field value.
          if (profileGroupFieldId == xProfileFieldName) {
            _registrationData['user_name'] =
                newValue == null ? '' : newValue.addEscapeCharacters();
          }
          _registrationData['field_$profileGroupFieldId'] =
              newValue == null ? '' : newValue.addEscapeCharacters();
        } else if (_dropdownSelections.containsKey(profileGroupFieldId)) {
          if (profileGroupField.isRequired &&
              _dropdownSelections[profileGroupFieldId] == null) {
            throw EmptyRequiredFieldException(
                "Please make a selection for '${profileGroupField.name}.'");
          }
          _registrationData['field_$profileGroupFieldId'] =
              _dropdownSelections[profileGroupFieldId] == null
                  ? ''
                  : _dropdownSelections[profileGroupFieldId]!.name;
        } else if (_multiSelectSelections[profileGroupFieldId] != null) {
          final selectedValues = _multiSelectSelections[profileGroupFieldId]
              ?.selectionItems
              .where((selectionItem) => selectionItem.isSelected == true);
          List<String> newValues = [];
          selectedValues?.forEach(
            (value) {
              newValues.add(value.contextTypeDescription.addEscapeCharacters());
            },
          );
          if (profileGroupField.isRequired && newValues.isEmpty) {
            throw EmptyRequiredFieldException(
                "Please select at least 1 item for for '${profileGroupField.name}'.");
          }
          _registrationData['field_$profileGroupFieldId'] = newValues;
        }
      }
    }

    // Check sign-up availability on first and last pages.
    if (_index == 0 || _index + 1 == _pageCount) {
      await _checkSignUpAvailability();
    }

    if (mounted) {
      LoadingScreen().hide();
    }

    if (profileGroupFieldIdsWithContactInformation.isNotEmpty) {
      final profileGroupFieldId =
          profileGroupFieldIdsWithContactInformation.first;

      final profileGroupField = _signUpXProfileFields!
          .where((field) => field.id == profileGroupFieldId)
          .firstOrNull;
      if (mounted &&
          !await confirmPostContactInformationDialog(
            context,
            fieldName: profileGroupField?.name,
          )) {
        return false;
      }
    }

    return true;
  }

  Future<void> _checkSignUpAvailability() async {
    final signUpAvailability = await _connectionService
        .checkSignUpAvailability(SignUpAvailabilityGetRequest(
      userLogin: _enteredUserNameText,
      userEmail: _enteredEmailAddressText,
    ));

    if (!signUpAvailability.userLogin && !signUpAvailability.userEmail) {
      throw SignUpAvailabilityException(
        title: 'Already Registered',
        message:
            "The username and email address that you entered are both in use.\n\nIf you have previously registered but have forgotten your password, you can use the lost password link on the Log In page to reset your password.",
      );
    } else if (!signUpAvailability.userLogin) {
      throw SignUpAvailabilityException(
        title: 'Username Taken',
        message:
            "The username that you entered is already in use, please try another.\n\nIf you have previously registered but have forgotten your password, you can use the lost password link on the Log In page to reset your password.",
      );
    } else if (!signUpAvailability.userEmail) {
      throw SignUpAvailabilityException(
        title: 'Already Registered',
        message:
            "The email address that you entered is already in use.\n\nIf you have previously registered but have forgotten your password, you can use the lost password link on the Log In page to reset your password.",
      );
    }
  }

  Future<void> _register() async {
    context.read<AuthBloc>().add(
          AuthEventRegister(
            _registrationData,
          ),
        );
  }

  Future<void> _exit() async {
    if (await showConfirmDialog(
        context: context,
        content:
            'Exit Registration?\n\nAny information that you have entered will be lost.')) {
      if (mounted) {
        context.read<AuthBloc>().add(
              const AuthEventLogOut(),
            );
      }
    }
  }
}

// Exception for field validation.
class TextFieldValidationException implements Exception {
  final String title;
  final String message;
  TextFieldValidationException({required this.title, required this.message});
}

// Exception for existing sign up details.
class SignUpAvailabilityException implements Exception {
  final String title;
  final String message;
  SignUpAvailabilityException({required this.title, required this.message});
}
