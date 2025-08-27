import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/server.dart';
import 'package:nifty_three_bp_app_base/enums/menu_action.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:arvo/utilities/url_launcher.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:app_base/widgets/back_to_top_widget.dart';

class FAQsView extends StatefulWidget {
  const FAQsView({super.key});

  @override
  State<FAQsView> createState() => _FAQsViewState();
}

class _FAQsViewState extends State<FAQsView> {
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _backToTopButtonVisible;
  late final ValueNotifier<bool> _isShowingClearFilter;
  late final TextEditingController _textSearchKeyController;
  late final List<FAQItem> _faqs;
  String? _searchKey;
  late final FocusNode _searchKeyFocusNode;

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
    _buildFAQs();
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
    _scrollController.addListener(() {
      //Back to top botton will show on scroll offset.
      if (mounted) {
        _backToTopButtonVisible.value = _scrollController.offset > 10.0;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQs',
        ),
        actions: [
          _buildPopupMenuWidget(),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _buildFilterWidget(),
            Expanded(
              child: ListView(
                // Add padding to bottom to prevent back top top button from
                // covering the last item.
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 96.0),
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                children: setHeightBetweenWidgets(
                  _textSearchKeyController.text != ''
                      ? _filterFAQs()
                          .map((faq) => _buildFAQItem(context, faq))
                          .toList()
                      : _faqs
                          .map((faq) => _buildFAQItem(context, faq))
                          .toList(),
                  height: 8.0,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: buildBackToTopFloatingButtonWidget(
        _backToTopButtonVisible,
        _scrollController,
        scrollToTopCompletedCallback: () {
          // Set back to top button visibility in case items size has changed.
          if (mounted) {
            if (_scrollController.hasClients) {
              _backToTopButtonVisible.value = _scrollController.offset > 10.0;
            }
          }
        },
      ),
    );
  }

  Widget _buildPopupMenuWidget() {
    return PopupMenuButton<MenuExpandCollapse>(
      onSelected: (value) async {
        switch (value) {
          case MenuExpandCollapse.expand:
            if (mounted) {
              setState(() {
                for (var faq in _faqs) {
                  faq.isExpanded = true;
                }
              });
            }
            break;
          case MenuExpandCollapse.collapse:
            if (mounted) {
              setState(() {
                for (var faq in _faqs) {
                  faq.isExpanded = false;
                }
              });
            }
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem<MenuExpandCollapse>(
            value: MenuExpandCollapse.expand,
            child: Text('Expand All'),
          ),
          const PopupMenuItem<MenuExpandCollapse>(
            value: MenuExpandCollapse.collapse,
            child: Text('Collapse All'),
          ),
        ];
      },
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
                    labelText: 'Search FAQs',
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

  Widget _buildFAQItem(BuildContext context, FAQItem faqItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        faqItem.header != null
            ? Text(
                faqItem.header!,
                style: Theme.of(context).textTheme.displaySmall,
              )
            : const SizedBox.shrink(),
        faqItem.question.isNotEmpty && faqItem.answerText.isNotEmpty
            ? const SizedBox(
                height: 8.0,
              )
            : const SizedBox.shrink(),
        faqItem.question.isNotEmpty && faqItem.answerText.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      faqItem.isExpanded = !faqItem.isExpanded;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5.0,
                        spreadRadius: 1.0,
                        offset: const Offset(1.0, 1.0),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              faqItem.question,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Icon(
                            faqItem.isExpanded
                                ? Platform.isIOS
                                    ? CupertinoIcons.chevron_up
                                    : Icons.keyboard_arrow_up_rounded
                                : Platform.isIOS
                                    ? CupertinoIcons.chevron_down
                                    : Icons.keyboard_arrow_down_rounded,
                            size: 32.0,
                          ),
                        ],
                      ),
                      faqItem.isExpanded
                          ? Text(
                              faqItem.answerText,
                            )
                          : const SizedBox.shrink(),
                      faqItem.isExpanded && faqItem.answerFunction != null
                          ? Column(
                              children: setHeightBetweenWidgets(
                                height: 4.0,
                                [
                                  const Divider(),
                                  TextButton(
                                    onPressed: faqItem.answerFunction,
                                    child:
                                        Text(faqItem.answerFunctionName ?? ''),
                                  )
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
        faqItem.freeText.isNotEmpty
            ? const SizedBox(
                height: 8.0,
              )
            : const SizedBox.shrink(),
        faqItem.freeText.isNotEmpty
            ? Text(
                faqItem.freeText,
              )
            : const SizedBox.shrink(),
        faqItem.function != null
            ? const SizedBox(
                height: 8.0,
              )
            : const SizedBox.shrink(),
        faqItem.function != null
            ? FilledButton(
                onPressed: faqItem.function!,
                child: Text(
                  faqItem.functionName ?? '',
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  void _buildFAQs() {
    _faqs = [];
    _faqs.add(FAQItem(
        freeText:
            "Below you'll find some of the most frequently asked questions about Arvo.\n\nIf you have a question that isn't answered on this page, you can get in touch us with using the button at the bottom of this page."));
    _faqs.add(FAQItem(header: 'Matching with Other Arvo Members'));
    _faqs.add(
      FAQItem(
        question: "How is the match percentage calculated?",
        answerText:
            "Our match percentage system relies on the information you share in your profile to identify other members that you might match with. Different sections of member profiles are weighted differently, depending on how much they relate to compatibility. For example, sharing the same values and morals is considered more than your favourite types of books.",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "Why don't I see high match percentages with other members?",
        answerText:
            "There could be a couple of reasons for this. The more questions you answer in your profile, the more likely you are to see higher match percentages with other members. We strongly recommend completing the “Fair Dinkum Dating Quiz”, available through editing your profile, to help increase the accuracy of match percentages. If you, or other members, don't have complete profiles, our system cannot create accurate matches. Arvo is also still a young platform, so it will take time for our community of members to grow. This means that it may take some time before your perfect match also joins Arvo, but we know it won't take long!",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "Is the match percentage accurate?",
        answerText:
            "Nothing in life is perfect. We like to think that the match percentage is a good indicator about if you will connect with another individual, romantically or otherwise. However, we can’t guarantee that you will always hit it off with someone just because you had a high percentage match. Likewise, you may find yourself becoming besties with someone who you shared a lower match percentage with. We recommend getting to know people based on their values and personality, rather than basing a decision on a number alone.",
      ),
    );
    _faqs.add(
      FAQItem(
        question:
            "I have a high match percentage with another member, but we don't get along at all! Why did we match so highly?",
        answerText:
            "Most of the match percentage between members is dependent on shared interests, values, and preferences. From time to time, you therefore might have a high match percentage with another member, but ultimately not agree on something that you consider to be fundamental. We suggest you get to know people based on their values and personality, rather than basing a decision on a number alone.",
      ),
    );
    _faqs.add(FAQItem(header: 'Blocking or Reporting Arvo Members'));
    _faqs.add(
      FAQItem(
        question: "How can I block another member?",
        answerText:
            "If you need to block another member for any reason, you can do so through these steps:\n\n1. Navigate to the profile of the member you wish to block.\n2. Once on their profile page, you will see a button with ellipsis (three dots) in the top right corner.\n3. Tap this button to bring up a pop-up menu.\n4. Tap the option called “Block”. You will be prompted with a confirmation dialog, tap “Yes” to block the member.",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "What happens when I block another member?",
        answerText:
            "A couple of key things happen when any member blocks someone:\n\n\u2022 The Arvo team will be notified of which member has been blocked and who blocked them.\n\u2022 The blocked member will not be able to access the profile of the member who blocked them.\n\u2022 The profiles of both members will be hidden from one another in some key areas. This includes the “Search” tab on the app.",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "Can I see which members I have blocked?",
        answerText:
            "Absolutely, you can view blocked members using the “Manage Blocked Members” button below, or through these steps via Settings:\n\n1. Navigate to the Settings page by tapping on the icon in the top right corner of the Home page to bring up a pop-up menu, then tap on “Settings”.\n2. Once in the Settings page, you will see a button called “Blocked Members”.\n3. Tap this button. You should now be able to see your blocked members.",
        answerFunctionName: 'Manage Blocked Members',
        answerFunction: () {
          Navigator.of(context).pushNamed(
            blockedMembersRoute,
          );
        },
      ),
    );
    _faqs.add(
      FAQItem(
        question: "Can I unblock another member?",
        answerText:
            "You sure can, simply follow these steps:\n\n1. Navigate to the Settings page by tapping on the icon in the top right corner of the Home page to bring up a pop-up menu, then tap on “Settings”.\n2. Once in the Settings page, you will see a button called “Blocked Members”.\n3. Tap this button to show your blocked members.\n4. Tap on the profile of the member that you want to unblock.\n5. Once on their profile page, you will see a button with a padlock on the bottom right of the screen.\n6. Tap the button to unblock the member.",
        answerFunctionName: 'Manage Blocked Members',
        answerFunction: () {
          Navigator.of(context).pushNamed(
            blockedMembersRoute,
          );
        },
      ),
    );
    _faqs.add(
      FAQItem(
        question: "When should I report a member?",
        answerText:
            "Arvo is an inclusive platform that welcomes members of all backgrounds, genders, ages, preferences, and orientations. We encourage you to report another member if they breach any of Arvo's Terms and Conditions. This includes, but is not limited to:\n\n\u2022 Threatening, offensive or abusive behaviour, including comments or media uploads.\n\u2022 Fake accounts, or accounts used for catfishing.\n\u2022 Accounts of a member who is under the age of 18.\n\u2022 Members who are engaging in, or encouraging, discriminatory or harassing behaviour (e.g. derogatory comments made towards or about ethnicity or sexual orientation).\n\nFor more information on what Arvo considers to be appropriate member conduct, please see our Terms and Conditions.",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "How do I report a member?",
        answerText:
            "If you need to report a member for any reason, you can do so through these steps:\n\n1. Navigate to the profile of the member you wish to report.\n2. Once on their profile page, you will see a button with ellipsis (three dots) in the top right corner.\n3. Tap this button to bring up a pop-up menu.\n4. Tap the option called “Report”. This will take you to a new page where you can enter more details.\n5. Select the most relevant category for reporting, and then enter a description of why you are reporting the member, with as much detail as possible. Then, tap on “Submit”.\n\nWe encourage you to include any relevant information when reporting another member; this will assist us in monitoring for any trends of regularly reported members, so that we can ensure the Arvo community remains a safe place for all members.",
      ),
    );
    _faqs.add(FAQItem(header: 'Account Verification'));
    _faqs.add(
      FAQItem(
        question: "How does account verification work?",
        answerText:
            "To become verified, a user must upload a selfie that matches the specific pose provided by the Arvo Dating app. If the user then chooses to upload a profile photo, Arvo admins compare the user's verification photo to their profile photo during the avatar moderation process to ensure it's the same person using the Arvo account.",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "How do I know if an account is verified?",
        answerText:
            "Verified users will have a visible tick icon and a “Verified” badge on their profiles.",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "How do I verify my account?",
        answerText:
            "Verifying your account is simple! Just head to your profile and tap the “Unverified” button on your profile photo area. Then all you need to do is follow the on-screen prompts to upload your own verification photo. Don't worry; your verification photo will only be seen by Arvo admins and won't be visible on your profile.",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "Do I have to verify my account?",
        answerText:
            "If you want to upload a profile photo, you will need to verify your account. We strongly recommend uploading a profile photo, as users with profile photos generally get more views and messages.",
      ),
    );
    _faqs.add(FAQItem(header: 'Subscriptions'));
    _faqs.add(
      FAQItem(
        question:
            "I bought a subscription, but it hasn't been applied. What do I do?",
        answerText:
            "Try restarting the app. If you're unsure on how to do this, the easiest way is to restart your phone. If your subscription still hasn't applied, please contact the Arvo support team by using the “Contact Us” button at the bottom of this page.",
      ),
    );
    _faqs.add(FAQItem(header: 'Other'));
    _faqs.add(
      FAQItem(
        question: "Is Arvo free to use?",
        answerText:
            "Arvo is free to join. Members of Arvo are able to view other member's profiles and send private messages. In addition, you can opt into paid subscriptions and enjoy access to premium app features.",
      ),
    );
    _faqs.add(
      FAQItem(
        question: "How do I delete my account?",
        answerText:
            "We are always sad to see a Arvo member leave, but we hope it's because you've found your perfect match! You can delete your Arvo account through following these steps:\n\n1. Navigate to the Settings page by tapping on the icon in the top right corner of the Home page to bring up a pop-up menu, then tap on “Settings”.\n2. Once in the Settings page, look under the “Account” section, and find and tap the button called “Delete Account”.\n3. Follow the on-screen prompts to delete your account.\n\nPlease note, deleting your account on Arvo is irreversible; we cannot recover your account for you. Please be sure that you really want to delete your account before following the above steps.",
      ),
    );
    _faqs.add(
      FAQItem(
        functionName: 'Online Safety Tips',
        function: () async {
          await browseToUrl(
            context: context,
            ConnectionService.arvo().serverUrl! + onlineSafetyTipsURL,
          );
        },
      ),
    );
    _faqs.add(
      FAQItem(
        functionName: 'Terms and Conditions',
        function: () async {
          await browseToUrl(
            context: context,
            ConnectionService.arvo().serverUrl! + termsAndConditionsURL,
          );
        },
      ),
    );
    _faqs.add(
      FAQItem(
        functionName: 'Contact Us',
        function: () {
          context.read<AuthBloc>().add(
                const AuthEventContactUs(),
              );
        },
      ),
    );
  }

  List<FAQItem> _filterFAQs() {
    List<FAQItem> results = [];

    results.addAll(_faqs.where((faq) =>
        faq.question.toLowerCase().contains(_searchKey!.toLowerCase())));
    results.addAll(_faqs.where((faq) =>
        faq.answerText.toLowerCase().contains(_searchKey!.toLowerCase())));

    // Remove duplicates.
    results = results.toSet().toList();
    // Expand to show the answers.
    return results;
  }
}

class FAQItem {
  bool isExpanded;
  String? header;
  String question;
  String answerText;
  String? answerFunctionName;
  void Function()? answerFunction;
  String freeText;
  String? functionName;
  void Function()? function;

  FAQItem({
    this.isExpanded = false,
    this.header,
    this.question = '',
    this.answerText = '',
    this.answerFunction,
    this.answerFunctionName,
    this.freeText = '',
    this.functionName,
    this.function,
  });
}
