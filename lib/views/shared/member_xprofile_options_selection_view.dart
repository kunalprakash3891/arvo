import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/widgets/back_to_top_widget.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';

class MemberXProfileOptionsSelectionView extends StatefulWidget {
  const MemberXProfileOptionsSelectionView({super.key});

  @override
  State<MemberXProfileOptionsSelectionView> createState() =>
      _MemberXProfileOptionsSelectionViewState();
}

class _MemberXProfileOptionsSelectionViewState
    extends State<MemberXProfileOptionsSelectionView> {
  XProfileFieldOptionsItem? _optionsItem;
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _backToTopButtonVisible;
  late final ValueNotifier<bool> _isShowingClearFilter;
  late final TextEditingController _textSearchKeyController;
  String? _searchKey;
  late final FocusNode _searchKeyFocusNode;
  bool _hasFilter = false;
  final int _minimumItemsFilterThreshold = 8;
  int? _noneSelectionItemId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _backToTopButtonVisible = ValueNotifier(false);
    _isShowingClearFilter = ValueNotifier(false);
    _textSearchKeyController = TextEditingController();
    _setUpTextSearchKeyControllerListener();
    _searchKeyFocusNode = FocusNode();
    _searchKeyFocusNode.addListener(_searchKeyFocusChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textSearchKeyController.dispose();
    _searchKeyFocusNode.dispose();
    _backToTopButtonVisible.dispose();
    _isShowingClearFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _optionsItem = context.getArgument<XProfileFieldOptionsItem>();

    if (_optionsItem == null) throw Exception('Invalid options.');

    _scrollController.addListener(() {
      //Back to top botton will show on scroll offset.
      if (mounted) {
        _backToTopButtonVisible.value = _scrollController.offset > 10.0;
      }
    });

    _hasFilter =
        _optionsItem!.selectionItems.length > _minimumItemsFilterThreshold;

    _noneSelectionItemId =
        noneSelectionItemXProfileFieldMap[_optionsItem!.xProfileFieldId];

    final selectedItemCount = _optionsItem!.selectionItems
        .where((selectionItem) =>
            selectionItem.isSelected &&
            selectionItem.contextTypeId != _noneSelectionItemId)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _optionsItem!.displayTitle,
            ),
            selectedItemCount > 0
                ? Text(
                    '$selectedItemCount selected',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ],
        ),
        actions: [
          selectedItemCount > 0
              ? TextButton(
                  onPressed: () async {
                    if (await showConfirmDialog(
                        context: context, content: 'Clear selection?')) {
                      if (mounted) {
                        setState(() {
                          for (final selectionItem
                              in _optionsItem!.selectionItems) {
                            selectionItem.isSelected = false;
                          }
                        });
                      }
                    }
                  },
                  child: const Text(
                    'Clear',
                  ),
                )
              : const SizedBox.shrink(),
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Done',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _hasFilter ? _buildFilterWidget() : const SizedBox.shrink(),
          Expanded(
            child: ListView(
              // Add padding to bottom to prevent back top top button from
              // covering the last item.
              padding: const EdgeInsets.only(bottom: 96.0),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              children: setHeightBetweenWidgets(
                _textSearchKeyController.text != ''
                    ? _optionsItem!.selectionItems
                        .where((selectionItem) => selectionItem
                            .contextTypeDescription
                            .toLowerCase()
                            .contains(_searchKey!.toLowerCase()))
                        .map((selectionItem) =>
                            _buildSelectionItem(context, selectionItem))
                        .toList()
                    : _optionsItem!.selectionItems
                        .map((selectionItem) =>
                            _buildSelectionItem(context, selectionItem))
                        .toList(),
                height: 8.0,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: buildBackToTopFloatingButtonWidget(
          _backToTopButtonVisible, _scrollController),
    );
  }

  // Apply filter as user is typing.
  void _textSearchKeyControllerListener() async {
    if (mounted) {
      setState(() {
        _searchKey = _textSearchKeyController.text;
      });
    }
  }

  void _setUpTextSearchKeyControllerListener() {
    _textSearchKeyController.removeListener(_textSearchKeyControllerListener);
    _textSearchKeyController.addListener(_textSearchKeyControllerListener);
  }

  Widget _buildFilterWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: setWidthBetweenWidgets(
          [
            Expanded(
              child: TextField(
                controller: _textSearchKeyController,
                decoration: InputDecoration(
                    labelText: 'Search ${_optionsItem!.displayTitle}',
                    prefixIcon: Icon(Platform.isIOS
                        ? CupertinoIcons.search
                        : Icons.search_rounded)),
                focusNode: _searchKeyFocusNode,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: _isShowingClearFilter,
              builder: (context, value, child) {
                if (value) {
                  return TextButton(
                    onPressed: () {
                      _cancelFilter();
                    },
                    child: const Text(
                      'Cancel',
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
          width: 8.0,
        ),
      ),
    );
  }

  void _cancelFilter() {
    _searchKeyFocusNode.unfocus();
    if (_textSearchKeyController.text.isNotEmpty) {
      if (mounted) {
        setState(
          () {
            _textSearchKeyController.clear();
          },
        );
      }
    }
  }

  void _searchKeyFocusChanged() {
    if (mounted) _isShowingClearFilter.value = _searchKeyFocusNode.hasFocus;
  }

  Widget _buildSelectionItem(
      BuildContext context, XProfileFieldOptionSelectionItem selectionItem) {
    return _noneSelectionItemId != null &&
            selectionItem.contextTypeId == _noneSelectionItemId
        ? SwitchListTile(
            title: Text(selectionItem.contextTypeDescription),
            value: selectionItem.isSelected,
            onChanged: (bool? value) {
              if (mounted) {
                setState(() {
                  selectionItem.isSelected = value!;
                  if (value) {
                    for (final selectionItem in _optionsItem!.selectionItems) {
                      if (selectionItem.contextTypeId != _noneSelectionItemId) {
                        selectionItem.isSelected = false;
                      }
                    }
                  }
                });
              }
            },
          )
        : CheckboxListTile(
            title: Text(selectionItem.contextTypeDescription),
            value: selectionItem.isSelected,
            onChanged: (bool? value) {
              if (mounted) {
                setState(() {
                  selectionItem.isSelected = value!;
                  for (final selectionItem in _optionsItem!.selectionItems) {
                    if (selectionItem.contextTypeId == _noneSelectionItemId) {
                      selectionItem.isSelected = false;
                    }
                  }
                });
              }
            },
          );
  }
}
