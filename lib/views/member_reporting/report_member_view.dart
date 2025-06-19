import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nifty_three_bp_app_base/constants/reporting.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/member_report_request.dart';
import 'package:arvo/utilities/ip.dart';
import 'package:arvo/utilities/url_launcher.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/loading/loading_screen.dart';

class ReportMemberView extends StatefulWidget {
  final Member member;
  final int category;
  final String? description;

  const ReportMemberView(
      {required this.member,
      required this.category,
      this.description,
      super.key});

  @override
  State<ReportMemberView> createState() => _ReportMemberViewState();
}

class _ReportMemberViewState extends State<ReportMemberView> {
  late final ConnectionService _connectionService;
  late final Member _member;
  //late final TextEditingController _textSubjectEditingController;
  late final TextEditingController _textContentEditingController;
  late final int _reportCategory;
  //String _enteredSubjectText = '';
  String _enteredDescriptionText = '';
  late final GlobalKey<FormState> _formKey;
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    //_textSubjectEditingController = TextEditingController();
    _member = widget.member;
    _reportCategory = widget.category;
    _enteredDescriptionText = widget.description ?? '';
    _textContentEditingController =
        TextEditingController(text: _enteredDescriptionText);
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    //_textSubjectEditingController.dispose();
    _textContentEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(
            'Report ${_member.name!}',
          ),
          leading: IconButton(
            onPressed: () async {
              _exit();
            },
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.xmark : Icons.close_rounded,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Category',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          DropdownButtonFormField<int>(
                            items: reportCategoryMap
                                .map((value, description) {
                                  return MapEntry(
                                    description,
                                    DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(description),
                                    ),
                                  );
                                })
                                .values
                                .toList(),
                            value: _reportCategory,
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                if (mounted) {
                                  setState(
                                    () {
                                      _reportCategory = newValue;
                                    },
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    /*TextFormField(
                    style: Theme.of(context).textTheme.titleMedium,
                    controller: _textSubjectEditingController,
                    maxLines: 1,
                    maxLength: 50,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      hintText: 'e.g. Fake profile picture',
                      counterText: _enteredSubjectText.length < 4
                          ? 'Min 4, max 50'
                          : '${_enteredSubjectText.length.toString()}/50 character(s)',
                    ),
                    onChanged: (value) {
                    if (mounted) {
                        setState(
                          () {
                            _enteredSubjectText = value;
                          },
                        );
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a subject.';
                      } else if (value.length < 4) {
                        return 'Subject must be at least 4 characters.';
                      }
                      return null;
                    },
                  ),*/
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
                            'Description',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text(
                              'Tell us why you are submitting this report, using at least 50 characters or more.'),
                          TextFormField(
                            style: Theme.of(context).textTheme.titleMedium,
                            controller: _textContentEditingController,
                            keyboardType: TextInputType.multiline,
                            maxLines:
                                null, //Make the editor expand as lines are entered.
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Provide as much detail as you can.',
                              counterText: _enteredDescriptionText.length < 50
                                  ? '${_enteredDescriptionText.length}/Min 50'
                                  : '',
                            ),
                            onChanged: (value) {
                              if (mounted) {
                                setState(
                                  () {
                                    _enteredDescriptionText = value;
                                  },
                                );
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description.';
                              } else if (value.length < 50) {
                                return 'Description is too short.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            _submitReport();
                          },
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              const TextSpan(
                                  text:
                                      'Submitting false reports is a violation of the '),
                              TextSpan(
                                text: 'Terms and Conditions.',
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
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  height: 16.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    try {
      if (_formKey.currentState!.validate()) {
        FocusScope.of(context).unfocus();
        if (mounted) {
          LoadingScreen().show(
            context: context,
            text: 'Submitting...',
          );
        }
        final ip = await getPublicIP();
        var memberReportRequest = MemberReportRequest(
          memberId: _member.id,
          userId: _connectionService.currentUser!.id,
          category: _reportCategory,
          subject: reportCategoryMap[
              _reportCategory]!, //_textSubjectEditingController.text,
          message: _textContentEditingController.text,
          name: _member.name!,
          email: _connectionService.currentUserEmailAddress!,
          ip: ip,
        );
        var reported =
            await _connectionService.reportMember(memberReportRequest);
        if (mounted) {
          LoadingScreen().hide();
        }
        if (reported) {
          final snackBar = SnackBar(
            content:
                Text("Your report about ${_member.name!} has been submitted."),
            duration: const Duration(seconds: 2),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        } else {
          if (mounted) {
            await showErrorDialog(context);
          }
        }
        if (mounted) {
          Navigator.of(context).pop();
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
    } on Exception catch (e) {
      if (mounted) {
        LoadingScreen().hide();
      }
      if (e is DuplicateReportException) {
        if (mounted) {
          await showErrorDialog(context,
              title: "Already Reported",
              text:
                  "You've already submitted a report for this member.\n\nIf you do not want to engage with them further, please consider blocking them.",
              backToPrevious: true);
        }
      } else {
        if (mounted) {
          await processException(context: context, exception: e);
        }
      }
    }
  }

  Future<void> _exit() async {
    bool canExit = true;
    if (_textContentEditingController.text.isNotEmpty) {
      canExit = await showConfirmDialog(
          context: context,
          content:
              'Exit this page?\n\nAny information that you have entered will be lost.');
    }
    if (canExit && mounted) {
      Navigator.of(context).pop();
    }
  }
}

// TODO: Below section shows how to create a stateless widget form.
/*class ReportMemberView extends StatelessWidget {
  static final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  static final GlobalKey<FormFieldState<String>> firstNameKey =
      GlobalKey<FormFieldState<String>>();
  static final GlobalKey<FormFieldState<String>> lastNameKey =
      GlobalKey<FormFieldState<String>>();
  static final GlobalKey<FormFieldState<String>> emailKey =
      GlobalKey<FormFieldState<String>>();
  const ReportMemberView({super.key});

  @override
  Widget build(BuildContext context) {
    List listUserType = [
      {'name': 'Individual', 'value': 'individual'},
      {'name': 'Company', 'value': 'company'}
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          //autovalidate: false,
          child: ListView(
            children: [
              DropdownButtonFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.settings_rounded),
                  hintText: 'Organisation Type',
                  filled: true,
                  fillColor: Colors.white,
                  errorStyle: TextStyle(color: Colors.yellow),
                ),
                items: listUserType.map((map) {
                  return DropdownMenuItem(
                    child: Text(map['name']),
                    value: map['value'],
                  );
                }).toList(),
                onChanged: (value) {},
              ),
              TextFormField(
                key: firstNameKey,
                decoration: const InputDecoration(
                  hintText: 'First Name',
                ),
              ),
              TextFormField(
                key: lastNameKey,
                decoration: const InputDecoration(
                  hintText: 'Last Name',
                ),
              ),
              TextFormField(
                key: emailKey,
                decoration: const InputDecoration(
                  hintText: 'Email Address',
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_rounded),
        onPressed: () {
          final form = formKey.currentState;
          if (form!.validate()) {
            var firstName = firstNameKey.currentState!.value;
            var lastName = lastNameKey.currentState!.value;
            var email = emailKey.currentState!.value;

            // Later, do some stuff here

            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
*/
