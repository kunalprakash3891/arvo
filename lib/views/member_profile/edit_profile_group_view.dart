import 'dart:io';

import 'package:arvo/views/shared/member_xprofile_location_selection_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/views/shared/confirm_share_contact_information_dialog.dart';
import 'package:nifty_three_bp_app_base/api/member_field.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_post_request.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_group.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:arvo/views/shared/x_profile_data_input_widget.dart';
import 'package:nifty_three_bp_app_base/views/exceptions/x_profile_exceptions.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/extensions/string_extensions.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/loading/loading_screen.dart';

class EditProfileGroupView extends StatefulWidget {
  const EditProfileGroupView({super.key});

  @override
  State<EditProfileGroupView> createState() => _EditProfileGroupViewState();
}

class _EditProfileGroupViewState extends State<EditProfileGroupView> {
  late final ConnectionService _connectionService;
  late final Member _currentUser;
  int? _xProfileGroupId;
  XProfileGroup? _xProfileGroup;
  List<XProfileField>? _xProfileFields;
  late final Map<int, Widget> _profileDataWidgets;
  late final Map<int, TextEditingController> _textEditingControllers;
  late final Map<int, XProfileField?> _dropdownSelections;
  late final Map<int, XProfileFieldOptionsItem?> _multiSelectSelections;
  late final Future _future;
  late final ValueNotifier<XProfileFieldOptionsItem?> _multiSelectFieldChanged;
  late final ValueNotifier<XProfileField?> _dropDownSelectFieldChanged;
  late final ValueNotifier<bool> _groupChanged;
  late final GlobalKey<FormState> _formKey;
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _profileDataWidgets = {};
    _textEditingControllers = {};
    _dropdownSelections = {};
    _multiSelectSelections = {};
    _multiSelectFieldChanged = ValueNotifier(null);
    _dropDownSelectFieldChanged = ValueNotifier(null);
    _groupChanged = ValueNotifier(false);
    _formKey = GlobalKey<FormState>();
    _future = _buildForm();
  }

  @override
  void dispose() {
    // Dispose the text editing controllers.
    for (var value in _textEditingControllers.values) {
      value.dispose();
    }
    _multiSelectFieldChanged.dispose();
    _groupChanged.dispose();
    super.dispose();
  }

  Future<void> _buildForm() async {
    _xProfileGroup = (await _connectionService.getXProfileGroups())
        .where((group) => group.id == _xProfileGroupId)
        .firstOrNull;

    if (_xProfileGroup == null) {
      throw Exception('Profile group does not exist.');
    }

    if (mounted) _groupChanged.value = true;

    // Fields that will be skipped and not displayed.
    List<int> ignoreDataFields = [
      // NOTE: If in future the name is made editable, it will need to apply
      // the same validation logic as has applied during registration.
      xProfileFieldName,
      xProfileFieldBirthdate,
      xProfileFieldGender,
      xProfileFieldTermsAcceptance,
    ];

    // Add editable fields.
    for (final field in _xProfileFields!) {
      if (ignoreDataFields.contains(field.id)) {
        continue;
      }
      if (mounted) {
        switch (field.type) {
          case fieldTypeTextBox:
          case fieldTypeTextArea:
            _profileDataWidgets[field.id] = buildXProfileTextBoxWidget(
              context,
              _xProfileGroupId!,
              field,
              _textEditingControllers,
              currentUser: _currentUser,
            );
          case fieldTypeSelectBox:
            if (field.id == xProfileFieldLocation) {
              _profileDataWidgets[field.id] =
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
                splitCharacter: ' | ',
                currentUser: _currentUser,
              );
              continue;
            }
            _profileDataWidgets[field.id] = buildXProfileSelectBoxWidget(
              context,
              _xProfileGroupId!,
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
              currentUser: _currentUser,
            );
          case fieldTypeCheckBox:
          case fieldTypeMultiSelectBox:
            _profileDataWidgets[field.id] =
                buildXProfileMultiSelectDisplayWidget(
              context,
              _xProfileGroupId!,
              field,
              _multiSelectSelections,
              (context, options) =>
                  _awaitReturnFromOptionsSelectionView(context, options),
              _multiSelectFieldChanged,
              currentUser: _currentUser,
            );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _xProfileGroupId = context.getArgument<int>();

    if (_xProfileGroupId == null) throw Exception('Invalid profile group.');

    _xProfileFields = _connectionService.xProfileFields!
        .where((field) => field.groupId == _xProfileGroupId)
        .toList();

    if (_xProfileFields == null) {
      throw Exception('Invalid profile group field data.');
    }

    if (_xProfileFields!.isEmpty) {
      throw Exception('Profile group field data is empty.');
    }

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
                _save(prompt: true);
              },
              child: Scaffold(
                appBar: AppBar(
                  title: ValueListenableBuilder(
                    valueListenable: _groupChanged,
                    builder: (context, value, child) {
                      return _xProfileGroup == null
                          ? const SizedBox.shrink()
                          : Text(_xProfileGroup!.name);
                    },
                  ),
                  leading: IconButton(
                    onPressed: () async {
                      _save(prompt: true);
                    },
                    icon: Icon(
                      Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _save();
                      },
                      child: const Text(
                        'Done',
                      ),
                    ),
                  ],
                ),
                body: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: _buildEditProfileGroupWidget(),
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

  Widget _buildEditProfileGroupWidget() {
    var profileDataWidgetsScrollView = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            children: setHeightBetweenWidgets(
              _profileDataWidgets.values.toList(),
              height: 16.0,
            ),
          ),
        ),
      ),
    );

    return profileDataWidgetsScrollView;
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

  XProfileFieldsUpdateRequests _generateUpdateRequests() {
    List<XProfileFieldPostRequest> updateRequests = [];
    List<EmptyRequiredFieldException> emptyRequiredFieldExceptions = [];
    List<FieldContainsProfanityException> fieldContainsProfanityExceptions = [];
    List<FieldContainsUrlException> fieldContainsUrlExceptions = [];
    List<MemberField> fieldsContainContactInformation = [];

    final profileGroupFields = _currentUser.xProfile?.groups
            .where((group) => group.id == _xProfileGroupId)
            .first
            .fields ??
        [];

    for (final profileGroupField in profileGroupFields) {
      final xProfileField = _xProfileFields!
          .where((field) => field.id == profileGroupField.id)
          .firstOrNull;
      if (xProfileField == null) throw Exception('Invalid profile field.');
      if (_textEditingControllers[profileGroupField.id] != null) {
        final existingUnserialisedValue =
            profileGroupField.value?.unserialized?.firstOrNull;
        final existingValue = existingUnserialisedValue != null
            ? existingUnserialisedValue.removeEscapeCharacters().parseHTML()
            : '';
        final newValue = _textEditingControllers[profileGroupField.id]?.text;
        final valueChanged = existingValue != newValue;
        if (xProfileField.isRequired &&
            (newValue == null || newValue.isEmpty)) {
          emptyRequiredFieldExceptions.add(EmptyRequiredFieldException(
              "'${profileGroupField.name}' cannot be empty."));
        }
        final profanities = newValue?.containsProfanity();
        if (profanities != null && profanities.isNotEmpty) {
          fieldContainsProfanityExceptions.add(FieldContainsProfanityException(
              "'${profileGroupField.name}' contains the following text which is not accepted, please remove first before proceeding.\n\n"
              "${profanities.join('\n')}"));
        }
        final urls = newValue?.containsUrlText();
        if (urls != null && urls.isNotEmpty) {
          fieldContainsUrlExceptions.add(FieldContainsUrlException(
              "'${profileGroupField.name}' appears to contain the following text which may be an external link, please remove first before proceeding.\n\n"
              "${urls.join('\n')}"));
        }
        // Add any fields that may have contact information for prompting at the end.
        final contactDetails = newValue?.containsContactDetails();
        if (contactDetails != null && contactDetails.isNotEmpty) {
          fieldsContainContactInformation.add(profileGroupField);
        }
        if (valueChanged) {
          updateRequests.add(
            XProfileFieldPostRequest(
                fieldId: profileGroupField.id,
                userId: _currentUser.id,
                value: newValue == null ? '' : newValue.addEscapeCharacters()),
          );
        }
      } else if (_dropdownSelections[profileGroupField.id] != null) {
        final existingValue = profileGroupField.value?.unserialized?.firstOrNull
            ?.removeEscapeCharacters()
            .parseHTML();
        final newValue = _dropdownSelections[profileGroupField.id]
            ?.name
            .removeEscapeCharacters();
        final valueChanged = existingValue != newValue;
        if (xProfileField.isRequired &&
            (newValue == null || newValue.isEmpty)) {
          emptyRequiredFieldExceptions.add(EmptyRequiredFieldException(
              "Please make a selection for '${profileGroupField.name}.'"));
        }
        if (valueChanged) {
          updateRequests.add(
            XProfileFieldPostRequest(
                fieldId: profileGroupField.id,
                userId: _currentUser.id,
                value: newValue == null ? '' : newValue.addEscapeCharacters()),
          );
        }
      } else if (_multiSelectSelections[profileGroupField.id] != null) {
        // Sort list alphabetically.
        profileGroupField.value?.unserialized
            ?.sort((a, b) => a.toString().compareTo(b.toString()));
        final existingValue = profileGroupField.value?.unserialized
            ?.join(',')
            .removeEscapeCharacters()
            .parseHTML();
        final selectedValues = _multiSelectSelections[profileGroupField.id]
            ?.selectionItems
            .where((selectionItem) => selectionItem.isSelected == true);
        List<String> newValues = [];
        selectedValues?.forEach(
          (value) {
            newValues.add(value.contextTypeDescription);
          },
        );
        // Sort list alphabetically.
        newValues.sort((a, b) => a.toString().compareTo(b.toString()));
        String newValue = newValues.join(',');
        final valueChanged = existingValue != newValue;
        if (xProfileField.isRequired && (newValue.isEmpty)) {
          emptyRequiredFieldExceptions.add(EmptyRequiredFieldException(
              "Please select at least 1 item for for '${profileGroupField.name}'."));
        }
        if (valueChanged) {
          // Remove alphabetical sorting before updating to preserve original
          // sort order.
          newValues.clear();
          selectedValues?.forEach(
            (value) {
              newValues.add(value.contextTypeDescription);
            },
          );
          newValue = newValues.join(',');
          updateRequests.add(
            XProfileFieldPostRequest(
                fieldId: profileGroupField.id,
                userId: _currentUser.id,
                value: newValue.addEscapeCharacters()),
          );
        }
      }
    }

    return XProfileFieldsUpdateRequests(
      updateRequests: updateRequests,
      emptyRequiredFieldExceptions: emptyRequiredFieldExceptions,
      fieldContainsProfanityExceptions: fieldContainsProfanityExceptions,
      fieldsContainContactInformation: fieldsContainContactInformation,
    );
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
    final locationOptions = LocationOptions(
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

  Future<void> _save({bool prompt = false}) async {
    try {
      // Unfocus all fields.
      FocusManager.instance.primaryFocus?.unfocus();

      XProfileFieldsUpdateRequests xProfileFieldsUpdateRequests;

      bool canPop = true;

      // Build list of POST requests.
      xProfileFieldsUpdateRequests = _generateUpdateRequests();

      // POST any changes.
      if (xProfileFieldsUpdateRequests.updateRequests.isNotEmpty || !prompt) {
        bool canSave = true;

        if (prompt && mounted && canSave) {
          canSave = await showConfirmDialog(
              context: context,
              content: 'Would you like to save your changes?');
        }

        if (canSave &&
            xProfileFieldsUpdateRequests
                .emptyRequiredFieldExceptions.isNotEmpty) {
          throw xProfileFieldsUpdateRequests.emptyRequiredFieldExceptions.first;
        }

        if (canSave &&
            xProfileFieldsUpdateRequests
                .fieldContainsProfanityExceptions.isNotEmpty) {
          throw xProfileFieldsUpdateRequests
              .fieldContainsProfanityExceptions.first;
        }

        if (canSave && xProfileFieldsUpdateRequests.updateRequests.isNotEmpty) {
          if (_formKey.currentState!.validate()) {
            if (mounted &&
                xProfileFieldsUpdateRequests
                    .fieldsContainContactInformation.isNotEmpty) {
              if (!await confirmPostContactInformationDialog(
                context,
                fieldName: xProfileFieldsUpdateRequests
                    .fieldsContainContactInformation.first.name,
              )) {
                return;
              }
            }

            if (mounted) {
              LoadingScreen().show(
                context: context,
                text: 'Updating...',
              );
            }
            for (final updateRequest
                in xProfileFieldsUpdateRequests.updateRequests) {
              await _connectionService.updateXProfileFieldData(updateRequest);
            }
            // Refresh the current user.
            await _connectionService.refreshCurrentUser();
            if (mounted) {
              LoadingScreen().hide();
            }
            // Show snackbar.
            const snackBar = SnackBar(
              content: Text("Profile updated."),
              duration: Duration(seconds: 2),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
            canPop = true;
          } else {
            canPop = false;
            if (mounted) {
              setState(
                () {
                  _autoValidate = true;
                },
              );
            }
          }
        } else {
          canPop = true;
        }
      }

      if (canPop) {
        // Pop the page.
        if (mounted) {
          Navigator.of(context).pop();
        }
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
      } else {
        if (mounted) {
          await processException(context: context, exception: e);
        }
      }
    }
  }
}

@immutable
class XProfileFieldsUpdateRequests {
  final List<XProfileFieldPostRequest> updateRequests;
  final List<EmptyRequiredFieldException> emptyRequiredFieldExceptions;
  final List<FieldContainsProfanityException> fieldContainsProfanityExceptions;
  final List<MemberField> fieldsContainContactInformation;

  const XProfileFieldsUpdateRequests({
    required this.updateRequests,
    required this.emptyRequiredFieldExceptions,
    required this.fieldContainsProfanityExceptions,
    required this.fieldsContainContactInformation,
  });
}
