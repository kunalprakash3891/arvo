import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';
import 'package:app_base/extensions/string_extensions.dart';
import 'package:app_base/widgets/quick_info_widget.dart';

Widget buildXProfileTextBoxWidget(
  BuildContext context,
  int xProfileGroupId,
  XProfileField xProfileField,
  Map<int, TextEditingController> textEditingControllers, {
  Member? currentUser,
  String? alternateName,
  List<TextInputFormatter>? inputFormatters,
  TextCapitalization? textCapitalisation,
}) {
  final textEditingController = TextEditingController();

  final existingUnserialisedValue = currentUser?.xProfile?.groups
      .where((group) => group.id == xProfileGroupId)
      .first
      .fields
      .where((field) => field.id == xProfileField.id)
      .first
      .value
      ?.unserialized
      ?.firstOrNull;

  textEditingController.text = existingUnserialisedValue != null
      ? existingUnserialisedValue.removeEscapeCharacters().parseHTML()
      : '';

  textEditingControllers[xProfileField.id] = textEditingController;

  final maxCharacters = xProfileFieldCharacterLimitMap[xProfileField.id];

  final hintText = xProfileField.name;

  final textFormField = Container(
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
        xProfileField.isRequired
            ? const SizedBox.shrink()
            : buildQuickInfoWidget(
                context: context,
                text: 'Optional',
                textStyle: Theme.of(context).textTheme.bodySmall,
                iconData: Platform.isIOS
                    ? CupertinoIcons.info_circle_fill
                    : Icons.info_rounded,
                iconSize: 16.0,
              ),
        Text(
          alternateName ?? xProfileField.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        (xProfileField.description.rendered != null &&
                xProfileField.description.rendered!.isNotEmpty)
            ? Text(
                xProfileField.description.rendered!.parseHTML(),
              )
            : const SizedBox.shrink(),
        TextFormField(
          decoration: InputDecoration(
            hintText: hintText,
          ),
          controller: textEditingController,
          keyboardType: xProfileField.type == fieldTypeTextArea
              ? TextInputType.multiline
              : TextInputType.text,
          maxLines: xProfileField.type == fieldTypeTextArea
              ? null
              : 1, //make the editor expand as lines are entered
          textCapitalization:
              textCapitalisation ?? TextCapitalization.sentences,
          maxLength: maxCharacters,
          inputFormatters: inputFormatters,
          validator: (value) {
            if (xProfileField.isRequired &&
                (value == null || value.trim().isEmpty)) {
              return 'This field cannot be empty.';
            }
            return null;
          },
        ),
      ],
    ),
  );

  return textFormField;
}

Widget buildXProfileSelectBoxWidget(
  BuildContext context,
  int xProfileGroupId,
  XProfileField xProfileField,
  Map<int, XProfileField?> dropdownSelections,
  Function onChanged, {
  Member? currentUser,
  String? alternateName,
}) {
  final existingUnserialisedValue = currentUser?.xProfile?.groups
      .where((group) => group.id == xProfileGroupId)
      .first
      .fields
      .where((field) => field.id == xProfileField.id)
      .first
      .value
      ?.unserialized
      ?.firstOrNull;

  final selectedValue = existingUnserialisedValue != null
      ? existingUnserialisedValue.removeEscapeCharacters().parseHTML()
      : '';

  final additionalInformation =
      xProfileFieldAdditionalInformationMap[xProfileField.id];

  // Note: xProfileField.options is not in HTML, but it may have escape characters.
  var selectedOption = xProfileField.options!
      .where((option) => option.name.removeEscapeCharacters() == selectedValue)
      .firstOrNull;
  dropdownSelections[xProfileField.id] = selectedOption;

  final dropdownButtonFormField = generateDropDownButtomFormField(
      context, xProfileField, selectedOption, onChanged);

  var iconData = getXProfileFieldDataIcon(
    xProfileField.id,
    xProfileField.name,
  );

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
          Wrap(
            children: [
              iconData == null
                  ? const SizedBox.shrink()
                  : Icon(
                      iconData,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              iconData == null
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 4.0),
              Text(
                alternateName ?? xProfileField.name,
                style: Theme.of(context).textTheme.titleLarge,
              )
            ],
          ),
          (xProfileField.description.rendered != null &&
                  xProfileField.description.rendered!.isNotEmpty)
              ? Text(
                  xProfileField.description.rendered!.parseHTML(),
                )
              : const SizedBox.shrink(),
          additionalInformation == null
              ? const SizedBox.shrink()
              : Text(additionalInformation),
          dropdownButtonFormField,
        ]),
  );
}

Widget buildRegistrationXProfileSelectBoxWidget(
  BuildContext context,
  XProfileField xProfileField,
  Map<int, XProfileField?> dropdownSelections,
  Function onChanged, {
  String? alternateName,
}) {
  final additionalInformation =
      xProfileFieldAdditionalInformationMap[xProfileField.id];

  var selectedOption = dropdownSelections[xProfileField.id];

  final dropdownButtonFormField = generateDropDownButtomFormField(
      context, xProfileField, selectedOption, onChanged);

  var iconData = getXProfileFieldDataIcon(
    xProfileField.id,
    xProfileField.name,
  );

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
          Wrap(
            children: [
              iconData == null
                  ? const SizedBox.shrink()
                  : Icon(
                      iconData,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              iconData == null
                  ? const SizedBox.shrink()
                  : const SizedBox(width: 4.0),
              Text(
                alternateName ?? xProfileField.name,
                style: Theme.of(context).textTheme.titleLarge,
              )
            ],
          ),
          (xProfileField.description.rendered != null &&
                  xProfileField.description.rendered!.isNotEmpty)
              ? Text(
                  xProfileField.description.rendered!.parseHTML(),
                )
              : const SizedBox.shrink(),
          additionalInformation == null
              ? const SizedBox.shrink()
              : Text(additionalInformation),
          dropdownButtonFormField,
        ]),
  );
}

Widget generateDropDownButtomFormField(
    BuildContext context,
    XProfileField xProfileField,
    XProfileField? selectedOption,
    Function onChanged,
    {bool showLabelText = false}) {
  return DropdownButtonFormField<XProfileField>(
    decoration: (showLabelText && selectedOption != null)
        ? InputDecoration(labelText: xProfileField.name)
        : null,
    hint: Align(
      alignment: Alignment.centerLeft,
      child: Text(xProfileField.name),
    ),
    isExpanded: true,
    value: selectedOption,
    items: xProfileField.options!
        .map<DropdownMenuItem<XProfileField>>((XProfileField value) {
      return DropdownMenuItem<XProfileField>(
          value: value,
          child: _generateDropDownButtonFieldWidget(
            context,
            xProfileField,
            value.name.removeEscapeCharacters(),
          ));
    }).toList(),
    onChanged: (XProfileField? newValue) {
      onChanged(newValue);
    },
    validator: (value) {
      if (xProfileField.isRequired && value == null) {
        return 'Please make a selection.';
      }
      return null;
    },
  );
}

Widget _generateDropDownButtonFieldWidget(
  BuildContext context,
  XProfileField xProfileField,
  String optionName,
) {
  late final IconData? iconData;

  // Ignore icons for selected fields.
  List<int> ignoreIconFields = [
    xProfileFieldLocation,
    xProfileFieldOccupation,
    xProfileFieldOftenSmoke,
    xProfileFieldOftenAlcohol,
  ];

  if (ignoreIconFields.contains(xProfileField.id)) {
    iconData = null;
  } else {
    iconData = getXProfileFieldDataIcon(
      xProfileField.id,
      optionName,
    );
  }

  final option = Wrap(
    children: [
      iconData == null
          ? const SizedBox.shrink()
          : Icon(
              iconData,
              color: Theme.of(context).colorScheme.secondary,
            ),
      iconData == null ? const SizedBox.shrink() : const SizedBox(width: 4.0),
      Text(
        optionName,
      )
    ],
  );

  return xProfileDropDownDividerPostfix.contains(optionName)
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            option,
            const Divider(),
          ],
        )
      : option;
}

Widget buildXProfileMultiSelectDisplayWidget(
    BuildContext context,
    int xProfileGroupId,
    XProfileField xProfileField,
    Map<int, XProfileFieldOptionsItem?> multSelectSelections,
    Function onEditPressed,
    ValueNotifier<XProfileFieldOptionsItem?> fieldChangedValueNotifier,
    {Member? currentUser}) {
  final selectedValues = currentUser?.xProfile?.groups
      .where((group) => group.id == xProfileGroupId)
      .first
      .fields
      .where((field) => field.id == xProfileField.id)
      .first
      .value
      ?.unserialized;

  final options = XProfileFieldOptionsItem(
    xProfileFieldId: xProfileField.id,
    displayTitle: xProfileField.name,
    selectionItems: [],
  );

  // Note: xProfileField.options is not in HTML, but it may have escape characters.
  for (final option in xProfileField.options!) {
    var selectionItem = XProfileFieldOptionSelectionItem(
      contextTypeId: option.id,
      contextTypeDescription: option.name.removeEscapeCharacters(),
    );

    if (selectedValues != null) {
      for (final selectedValue in selectedValues) {
        if (selectedValue.removeEscapeCharacters().parseHTML() ==
            option.name.removeEscapeCharacters()) {
          selectionItem.isSelected = true;
        }
      }
    }

    options.selectionItems.add(selectionItem);
  }

  multSelectSelections[xProfileField.id] = options;

  var iconData = getXProfileFieldDataIcon(
    xProfileField.id,
    xProfileField.name,
  );

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
      onPressed: () async {
        onEditPressed(context, options);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: [
                    iconData == null
                        ? const SizedBox.shrink()
                        : Icon(
                            iconData,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    iconData == null
                        ? const SizedBox.shrink()
                        : const SizedBox(width: 4.0),
                    Text(
                      xProfileField.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable: fieldChangedValueNotifier,
                  builder: (context, value, child) {
                    return value != null &&
                            value.xProfileFieldId == xProfileField.id
                        ? _buildMultiSelectSelectedOptionsSummary(
                            context, value, xProfileField.isRequired)
                        : _buildMultiSelectSelectedOptionsSummary(
                            context, options, xProfileField.isRequired);
                  },
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

List<Widget> _buildQuickInfoWidgets(
  BuildContext context,
  List<XProfileFieldOptionSelectionItem> selectionItems,
) {
  final List<Widget> quickInfoWidgets = [];

  for (final selectionItem in selectionItems) {
    if (selectionItem.isSelected) {
      quickInfoWidgets.add(
        buildQuickInfoWidget(
          context: context,
          text: selectionItem.contextTypeDescription,
        ),
      );
    }
  }

  return quickInfoWidgets;
}

Widget _buildMultiSelectSelectedOptionsSummary(
  BuildContext context,
  XProfileFieldOptionsItem? xProfileFieldOptionsItem,
  bool isRequired,
) {
  return xProfileFieldOptionsItem != null &&
          xProfileFieldOptionsItem.selectionItems
              .where((selectionItem) => selectionItem.isSelected == true)
              .isNotEmpty
      ? Wrap(
          children: _buildQuickInfoWidgets(
          context,
          xProfileFieldOptionsItem.selectionItems,
        ))
      : isRequired
          ? Text(
              'At least one selection required',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            )
          : Text(
              'None Selected',
              style: Theme.of(context).textTheme.bodyLarge,
            );
}

Widget buildXProfileNavigateToSelectDisplayWidget(
  BuildContext context,
  XProfileField xProfileField,
  Map<int, XProfileField?> dropdownSelections,
  Function onEditPressed,
  ValueNotifier<XProfileField?> fieldChangedValueNotifier, {
  String? alternateName,
  TextDisplayFormatterCallback? textDisplayFormatter,
  Member? currentUser,
}) {
  final existingUnserialisedValue = currentUser?.xProfile?.groups
      .where((group) => group.id == xProfileField.groupId)
      .first
      .fields
      .where((field) => field.id == xProfileField.id)
      .first
      .value
      ?.unserialized
      ?.firstOrNull;

  final selectedValue = existingUnserialisedValue != null
      ? existingUnserialisedValue.removeEscapeCharacters().parseHTML()
      : '';

  // Note: xProfileField.options is not in HTML, but it may have escape characters.
  var selectedOption = xProfileField.options!
      .where((option) => option.name.removeEscapeCharacters() == selectedValue)
      .firstOrNull;
  dropdownSelections[xProfileField.id] = selectedOption;

  final additionalInformation =
      xProfileFieldAdditionalInformationMap[xProfileField.id];

  var iconData = getXProfileFieldDataIcon(
    xProfileField.id,
    xProfileField.name,
  );

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
        Wrap(
          children: [
            iconData == null
                ? const SizedBox.shrink()
                : Icon(
                    iconData,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            iconData == null
                ? const SizedBox.shrink()
                : const SizedBox(width: 4.0),
            Text(
              alternateName ?? xProfileField.name,
              style: Theme.of(context).textTheme.titleLarge,
            )
          ],
        ),
        (xProfileField.description.rendered != null &&
                xProfileField.description.rendered!.isNotEmpty)
            ? Text(xProfileField.description.rendered!.parseHTML())
            : const SizedBox.shrink(),
        additionalInformation == null
            ? const SizedBox.shrink()
            : Text(additionalInformation),
        if (additionalInformation != null) Text(additionalInformation),
        OutlinedButton(
          onPressed: () async {
            onEditPressed(context, xProfileField, selectedOption);
          },
          child: ValueListenableBuilder(
            valueListenable: fieldChangedValueNotifier,
            builder: (context, value, child) {
              return value != null && value.parentId == xProfileField.id
                  ? Text(
                      textDisplayFormatter != null
                          ? textDisplayFormatter(value.name)
                          : value.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : dropdownSelections[xProfileField.id] != null
                      ? Text(
                          textDisplayFormatter != null
                              ? textDisplayFormatter(
                                  dropdownSelections[xProfileField.id]!.name)
                              : dropdownSelections[xProfileField.id]!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : xProfileField.isRequired
                          ? const Text(
                              'Select',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Text(
                              'None Selected',
                            );
            },
          ),
        ),
      ],
    ),
  );
}
