import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/enums/tip_type.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:arvo/views/shared/confirm_share_contact_information_dialog.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/message_send_new_message_request.dart';
import 'package:arvo/services/development/development_service.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/services/tips/tip_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/messages/message_thread_view.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:nifty_three_bp_app_base/views/widgets/circle_avatar.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/loading/loading_screen.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class NewMessageThreadView extends StatefulWidget {
  final Member recipient;
  const NewMessageThreadView({required this.recipient, super.key});

  @override
  State<NewMessageThreadView> createState() => _NewMessageThreadViewState();
}

class _NewMessageThreadViewState extends State<NewMessageThreadView> {
  late final ConnectionService _connectionService;
  late final MessagingHandlerService _messagingHandlerService;
  late final FeatureService _featureService;
  late final DevelopmentService _developmentService;
  late Member _recipient;
  late final Member _currentUser;
  late final TextEditingController _textSubjectEditingController;
  late final TextEditingController _textMessageEditingController;
  bool _isUsingCustomOpener = false;
  String _selectedOpener = '';
  String _enteredSubjectText = '';
  String _enteredMessageText = '';
  late final List<String> _openers;
  late final GlobalKey<FormState> _formKey;
  bool _autoValidate = false;
  int _latestMessageThreadId = 0;
  bool _latestMessageThreadOverride = false;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _recipient = widget.recipient;
    _messagingHandlerService = MessagingHandlerService.arvo();
    _featureService = FeatureService.arvo();
    _developmentService = DevelopmentService.arvo();
    _textSubjectEditingController = TextEditingController();
    _textMessageEditingController = TextEditingController();
    _openers = [
      greeting,
      'Hello',
      'Hi',
      'Hey',
      localisedMessageOpener1,
      localisedMessageOpener2,
    ];
    _selectedOpener = _openers.first;
    _formKey = GlobalKey<FormState>();
    // addPostFrameCallback runs after the page has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show tip.
      TipService.arvo().showTipOverlay(context, TipType.tipMessageGuidelines);
    });
  }

  @override
  void dispose() {
    _textSubjectEditingController.dispose();
    _textMessageEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              children: setHeightBetweenWidgets(
                [
                  _buildRecipientAvatarWidget(),
                  _buildOpenersWidget(),
                  _buildMessageBoxWidget(),
                  _buildSendWidget(),
                ],
                height: 16.0,
                header: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientAvatarWidget() {
    final mediaSize = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
      ),
      child: Container(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: setWidthBetweenWidgets(
                  [
                    buildCircleAvatarWithOnlineStatus(
                      _recipient,
                      kBaseColour,
                      kBaseColour,
                      Theme.of(context).colorScheme.surface,
                      kBaseComplementaryColour,
                      kBaseAnalogousColour1,
                      kBaseTriadicColour2,
                      showOnlineStatus:
                          _featureService.featureMemberOnlineIndicator,
                      radius: 32.0,
                    ),
                    SizedBox(
                      width: mediaSize.width * 0.50,
                      child: Text(
                        _recipient.name!,
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  width: 8.0,
                ),
              ),
              CircularPercentIndicator(
                radius: 22.0,
                lineWidth: 4.0,
                backgroundColor: Colors.transparent,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: getMatchPercentageColour(_recipient.matchWeight,
                    _featureService.featureMatchInsight),
                animation: true,
                animationDuration: 800,
                percent: (_recipient.matchWeight / 100).toDouble(),
                center: Text(
                  '${_recipient.matchWeight}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenersWidget() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
      ),
      child: Container(
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
        ),
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
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '1. Select or write an opener',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _isUsingCustomOpener
                ? _buildCustomOpenerWidget()
                : _buildOpenersCarousel(),
            _isUsingCustomOpener
                ? TextButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _isUsingCustomOpener = false;
                        });
                      }
                    },
                    child: const Text(
                      'Select from preset openers',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  )
                : TextButton(
                    onPressed: () async {
                      _featureService.featureCustomOpeners
                          ? {
                              if (mounted)
                                {
                                  setState(() {
                                    _isUsingCustomOpener = true;
                                  })
                                }
                            }
                          : Navigator.of(context)
                              .pushNamed(subscriptionsViewRoute);
                    },
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Write my own opener',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        _featureService.featureCustomOpeners
                            ? const SizedBox.shrink()
                            : const SizedBox(
                                width: 8.0,
                              ),
                        _featureService.featureCustomOpeners
                            ? const SizedBox.shrink()
                            : Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                    color: kBaseColour,
                                    borderRadius: BorderRadius.circular(8.0)),
                                child: const Text(
                                  'Premium',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenersCarousel() {
    return CarouselSlider(
      items: _openers
          .map(
            (item) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5.0,
                      spreadRadius: 1.0,
                      offset: const Offset(1.0, 1.0),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 20.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 24.0,
                      child: Wrap(
                        children: setWidthBetweenWidgets(
                          [
                            Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.arrow_left_right
                                  : Icons.swipe_rounded,
                              size: 18.0,
                            ),
                            const Text('Swipe to change'),
                          ],
                          width: 8.0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
      options: CarouselOptions(
        enlargeCenterPage: true,
        height: 120.0,
        onPageChanged: (index, reason) {
          _selectedOpener = _openers[index];
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildCustomOpenerWidget() {
    final textFormField = Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
      ),
      child: TextFormField(
        style: Theme.of(context).textTheme.titleMedium,
        controller: _textSubjectEditingController,
        keyboardType: TextInputType.multiline,
        maxLength: 50,
        maxLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Opener',
          hintText: 'Write something short to get their attention.',
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
          if (_isUsingCustomOpener && (value == null || value.trim().isEmpty)) {
            return 'Please enter some text.';
          }
          return null;
        },
      ),
    );

    return textFormField;
  }

  Widget _buildMessageBoxWidget() {
    final textFormField = Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
      ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '2. Write a message',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            TextFormField(
              style: Theme.of(context).textTheme.titleMedium,
              controller: _textMessageEditingController,
              keyboardType: TextInputType.multiline,
              maxLines: null, //Make the editor expand as lines are entered.
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'e.g. I loved your profile...',
              ),
              onChanged: (value) {
                if (mounted) {
                  setState(
                    () {
                      _enteredMessageText = value;
                    },
                  );
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please type a message.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );

    return textFormField;
  }

  Widget _buildSendWidget() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: ElevatedButton(
        onPressed: () async {
          _sendMessage();
        },
        child: const Text(
          'Send',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    try {
      if (_formKey.currentState!.validate()) {
        if (mounted) {
          LoadingScreen().show(
            context: context,
            text: 'Validating...',
          );
        }

        _latestMessageThreadId = await _messagingHandlerService
            .getLastMessageThreadId(_recipient.id);

        if (mounted) {
          LoadingScreen().hide();
        }

        bool redirectToLatestThread = false;
        if (_latestMessageThreadId > 0 && !_latestMessageThreadOverride) {
          _developmentService.isDevelopment
              ? {
                  if (mounted)
                    {
                      redirectToLatestThread = await showConfirmDialog(
                        context: context,
                        title: 'Development',
                        content:
                            "A message thread with ${_recipient.name} already exists.\n\nWould you like to switch to this thread?",
                        cancelText: 'No',
                        confirmText: 'Yes',
                      )
                    }
                }
              : {
                  if (mounted)
                    {
                      redirectToLatestThread = await showConfirmDialog(
                        context: context,
                        title: 'Message Thread Exists',
                        content:
                            "You can't start a new message thread with ${_recipient.name} because you already have an existing thread with them.\n\nWould you like to switch to this thread?",
                        cancelText: 'Cancel',
                        confirmText: 'Yes',
                      )
                    }
                };
        }

        if (redirectToLatestThread) {
          await _redirectToLatestThread();
        } else {
          // Return if not development and this is not the latest thread.
          if (!_developmentService.isDevelopment &&
              _latestMessageThreadId > 0) {
            return;
          }
          // If development and we've reached this point, it means we
          // are overriding the latest message thread prompt.
          if (_developmentService.isDevelopment) {
            _latestMessageThreadOverride = true;
          }

          final contactDetails =
              _textMessageEditingController.text.containsContactDetails();
          if (contactDetails.isNotEmpty) {
            if (mounted &&
                !await confirmShareContactInformationDialog(context)) {
              return;
            }
          }

          if (mounted) {
            LoadingScreen().show(
              context: context,
              text: 'Sending...',
            );
          }

          final isRecipientReachable = await _messagingHandlerService
              .checkRecipientIsReachable(_recipient);

          if (!isRecipientReachable) {
            if (mounted) {
              LoadingScreen().hide();
            }
            if (mounted) {
              await showErrorDialog(context,
                  title: 'Unable to send',
                  text:
                      '${_recipient.name!} is not accepting messages right now, please try again later.');
            }
          } else {
            var newMessageRequest = MessageSendNewMessageRequest(
              subject:
                  _isUsingCustomOpener ? _enteredSubjectText : _selectedOpener,
              message: _enteredMessageText,
              recipients: [_recipient.id],
              senderId: _currentUser.id,
            );
            var result =
                await _connectionService.sendNewMessage(newMessageRequest);
            if (mounted) {
              LoadingScreen().hide();
            }
            if (result.isNotEmpty) {
              // Message was sent successfully.
              // Update new message sent timestamp which is used to check for
              // excessive new messages.
              _messagingHandlerService.updateNewMessageSentTimestamp();
              // Navigate to message thread view.
              var messageThread = result[0];
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessageThreadView(
                      messageThread: messageThread,
                    ),
                  ),
                );
              }
            } else {
              // Couldn't send, ask user to try again later.
              if (mounted) {
                await showErrorDialog(context);
              }
            }
          }
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
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  // Navigates to the latest thread.
  Future<void> _redirectToLatestThread() async {
    if (mounted) {
      LoadingScreen().show(
        context: context,
        text: 'Redirecting...',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MessageThreadView(
            messageThreadId: _latestMessageThreadId,
            draft: _textMessageEditingController.text,
          ),
        ),
      );
    }

    if (mounted) {
      LoadingScreen().hide();
    }
  }
}
