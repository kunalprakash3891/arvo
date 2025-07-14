import 'dart:io';
import 'package:arvo/views/shared/x_profile_concat_location_utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/enums/tip_type.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:arvo/services/connection/member_filters.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/tips/tip_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/widgets/quick_info_widget.dart';

typedef MemberFiltersCallback = Future<void> Function();

class MemberFiltersView extends StatefulWidget {
  const MemberFiltersView({super.key});

  @override
  State<MemberFiltersView> createState() => _MemberFiltersViewState();
}

class _MemberFiltersViewState extends State<MemberFiltersView> {
  late final MemberDirectoryService _memberDirectoryService;
  late final FeatureService _featureService;
  late final TipService _tipService;
  late MemberFilters _filters;
  late final TextEditingController _textSearchKeyController;
  MemberFiltersCallback? _reloadFunction;
  bool _executeReload = false;
  late final ValueNotifier<bool> _isSelectingAgeRange;
  late final MemberFilters _defaultFilters;

  @override
  void initState() {
    super.initState();
    _memberDirectoryService = MemberDirectoryService.arvo();
    _featureService = FeatureService.arvo();
    _tipService = TipService.arvo();
    _filters = _memberDirectoryService.memberFilters;
    _textSearchKeyController = TextEditingController();
    _textSearchKeyController.text = _filters.searchKey;
    _isSelectingAgeRange = ValueNotifier(false);
    _defaultFilters = MemberFilters();
    _memberDirectoryService.populateMemberSearchFilters(_defaultFilters);
  }

  @override
  void dispose() {
    _textSearchKeyController.dispose();
    _isSelectingAgeRange.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reloadFunction = context.getArgument<MemberFiltersCallback>();

    if (_reloadFunction == null) throw Exception('Invalid reload function.');

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
          title: _memberDirectoryService.activeMemberFiltersCount > 0
              ? Text(
                  'Filters (${_memberDirectoryService.activeMemberFiltersCount})')
              : const Text('Filters'),
          leading: IconButton(
            onPressed: () async {
              _exit();
            },
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
            ),
          ),
          actions: [
            _filters != _defaultFilters
                ? TextButton(
                    onPressed: () async {
                      if (await showConfirmDialog(
                          context: context, content: 'Clear all filters?')) {
                        await _memberDirectoryService
                            .clearMemberSearchFilters();
                        // Dismiss tip since it no longer applies (user has modified their filters).
                        await _tipService.dismissTip(TipType.tipFiltersApplied);
                        if (mounted) {
                          setState(
                            () {
                              _filters = _memberDirectoryService.memberFilters;
                              _textSearchKeyController.clear();
                              _executeReload = true;
                            },
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Clear',
                    ),
                  )
                : const SizedBox.shrink(),
            TextButton(
              onPressed: () async {
                _exit();
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
                _buildSortByFilterWidget(),
                _buildXProfileFilterDisplayWidget(_filters.connectionTypes),
                _buildXProfileFilterDisplayWidget(_filters.genders),
                _buildXProfileFilterDisplayWidget(_filters.sexualOrientations),
                _buildRangeFilterWidget(_filters.ageRange),
                _buildXProfileFilterDisplayWidget(
                  _filters.locations,
                  selectedItemDescriptionFormatter: locationDisplayFormatter,
                ),
                //_buildLocationFilterWidget(),
                _buildXProfileFilterDisplayWidget(_filters.passions),
                _buildXProfileFilterDisplayWidget(_filters.ethnicities),
                _buildProfilePhotoFilterWidget(),
                _buildSearchKeyWidget(),
              ],
              height: 16.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeFilterWidget(RangeFilterItem rangeFilterItem) {
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rangeFilterItem.displayTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              children: [
                SizedBox(
                  width: 24.0,
                  child: ValueListenableBuilder(
                    valueListenable: _isSelectingAgeRange,
                    builder: (context, value, child) {
                      return Text(
                        !value
                            ? '${rangeFilterItem.selectedRange.start.round()}'
                            : '',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: rangeFilterItem.selectedRange,
                    onChanged: (RangeValues newRange) async {
                      if (mounted) {
                        setState(() {
                          rangeFilterItem.selectedRange = newRange;
                        });
                      }
                      await _save();
                    },
                    onChangeStart: (value) {
                      if (mounted) _isSelectingAgeRange.value = true;
                    },
                    onChangeEnd: (value) {
                      if (mounted) _isSelectingAgeRange.value = false;
                    },
                    min: rangeFilterItem.min,
                    max: rangeFilterItem.max,
                    divisions: 81,
                    labels: RangeLabels(
                      '${rangeFilterItem.selectedRange.start.round()}',
                      '${rangeFilterItem.selectedRange.end.round()}',
                    ),
                  ),
                ),
                SizedBox(
                  width: 24.0,
                  child: ValueListenableBuilder(
                    valueListenable: _isSelectingAgeRange,
                    builder: (context, value, child) {
                      return Text(
                        !value
                            ? '${rangeFilterItem.selectedRange.end.round()}'
                            : '',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoFilterWidget() {
    return GestureDetector(
      onTap: _featureService.featurePhotoTypeSearch
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: setHeightBetweenWidgets(
              [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _filters.profilePhotoTypes.displayTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _featureService.featurePhotoTypeSearch
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                                color: kBasePremiumBackgroundColour,
                                borderRadius: BorderRadius.circular(8.0)),
                            child: const Text(
                              'Premium',
                              style: TextStyle(
                                  color: kBasePremiumForegroundTextColour),
                            ),
                          ),
                  ],
                ),
                DropdownButtonFormField<SelectionItem>(
                  isExpanded: true,
                  value: _filters.selectedProfilePhotoType,
                  items: _filters.profilePhotoTypes.selectionItems
                      .map<DropdownMenuItem<SelectionItem>>(
                          (SelectionItem value) {
                    return DropdownMenuItem<SelectionItem>(
                      value: value,
                      child: Text(value.description ?? value.value.toString()),
                    );
                  }).toList(),
                  onChanged: _featureService.featurePhotoTypeSearch
                      ? (SelectionItem? newValue) async {
                          if (newValue != null) {
                            if (mounted) {
                              setState(
                                () {
                                  _filters.selectedProfilePhotoType = newValue;
                                },
                              );
                            }
                            await _save();
                          }
                        }
                      : null,
                ),
              ],
              height: 8.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortByFilterWidget() {
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: setHeightBetweenWidgets(
            [
              Text(
                _filters.sortByTypes.displayTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              DropdownButtonFormField<SelectionItem>(
                isExpanded: true,
                value: _filters.selectedSortByType,
                items: _filters.sortByTypes.selectionItems
                    .map<DropdownMenuItem<SelectionItem>>(
                        (SelectionItem value) {
                  return DropdownMenuItem<SelectionItem>(
                    value: value,
                    child: Text(value.description ?? value.value.toString()),
                  );
                }).toList(),
                onChanged: (SelectionItem? newValue) async {
                  if (newValue != null) {
                    if (mounted) {
                      setState(
                        () {
                          _filters.selectedSortByType = newValue;
                        },
                      );
                    }
                    await _save();
                  }
                },
              ),
            ],
            height: 8.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchKeyWidget() {
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          style: Theme.of(context).textTheme.titleMedium,
          controller: _textSearchKeyController,
          keyboardType: TextInputType.text,
          maxLines: 1,
          decoration: const InputDecoration(
            labelText: 'Keywords',
            hintText: 'e.g. coffee, live music, road trips',
          ),
          onChanged: (value) async {
            if (mounted) {
              setState(
                () {
                  _filters.searchKey = value;
                },
              );
            }
            await _save();
          },
        ),
      ),
    );
  }

  Widget _buildXProfileFilterDisplayWidget(
      XProfileFieldOptionsItem xProfileFieldOptionsItem,
      {TextDisplayFormatterCallback? selectedItemDescriptionFormatter}) {
    final List<Widget> selectedItems = [];

    for (final selectionItem in xProfileFieldOptionsItem.selectionItems) {
      if (selectionItem.isSelected) {
        selectedItems.add(
          buildQuickInfoWidget(
            context: context,
            text: selectedItemDescriptionFormatter != null
                ? selectedItemDescriptionFormatter(
                    selectionItem.contextTypeDescription)
                : selectionItem.contextTypeDescription,
          ),
        );
      }
    }

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
          await _awaitReturnFromOptionsSelectionView(
              context, xProfileFieldOptionsItem,
              selectedItemDescriptionFormatter:
                  selectedItemDescriptionFormatter);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(8.0),
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
                  Text(
                    xProfileFieldOptionsItem.displayTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  selectedItems.isNotEmpty
                      ? Wrap(children: selectedItems)
                      : Text(
                          'Any',
                          style: Theme.of(context).textTheme.bodyLarge,
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

  Future<void> _awaitReturnFromOptionsSelectionView(
      BuildContext context, XProfileFieldOptionsItem xProfileFieldOptionsItem,
      {TextDisplayFormatterCallback? selectedItemDescriptionFormatter}) async {
    final xProfileFieldOptionsItemOriginal =
        XProfileFieldOptionsItem.clone(xProfileFieldOptionsItem);
    // Navigate to view and wait for it to return.
    await Navigator.of(context).pushNamed(
      memberXProfileOptionsSelectionViewRoute,
      arguments: XProfileFieldSelectionOptions(
        optionsItems: xProfileFieldOptionsItem,
        descriptionFormatter: selectedItemDescriptionFormatter,
      ),
    );
    // Update this page on return.
    if (xProfileFieldOptionsItemOriginal != xProfileFieldOptionsItem) {
      if (mounted) {
        setState(() {});
      }
      await _save();
    }
  }

  Future<void> _save() async {
    await _memberDirectoryService.saveMemberSearchFilters();
    // Dismiss tip since it no longer applies (user has modified their filters).
    await _tipService.dismissTip(TipType.tipFiltersApplied);
    _executeReload = true;
  }

  Future<void> _exit() async {
    if (mounted) {
      Navigator.of(context).pop();
      if (_executeReload) {
        _reloadFunction!();
      }
    }
  }
}
