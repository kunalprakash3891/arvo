import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/member_field.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_field_post_request.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:app_base/extensions/string_extensions.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/loading/loading_indicator.dart';

class PerfectMatchQuizView extends StatefulWidget {
  const PerfectMatchQuizView({super.key});

  @override
  State<PerfectMatchQuizView> createState() => _PerfectMatchQuizViewState();
}

class _PerfectMatchQuizViewState extends State<PerfectMatchQuizView> {
  late final ConnectionService _connectionService;
  late final Member _currentUser;
  late final List<PerfectMatchQuizQuestion> _questions;
  PerfectMatchQuizQuestion? _currentQuestion;
  PerfectMatchQuizAnswer? _currentAnswer;
  late final Future _future;
  double _progress = 0;
  late final PageController _pageController;
  Function? _quizEndedCallback;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _questions = [];
    _pageController = PageController();
    // Note: Assigning the _future variable here will cause it to execute on load
    // before the build function executes.
    _future = _loadQuiz();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optional function that will be executed when quiz ends.
    _quizEndedCallback = _quizEndedCallback ?? context.getArgument<Function>();

    const title = Text('Fair Dinkum Dating Quiz');
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildErrorScaffold(
            title: title,
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
                Navigator.of(context).pop();
                _quizEndedCallback?.call();
              },
              child: Scaffold(
                appBar: AppBar(
                  title: title,
                  leading: IconButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(context).pop();
                        _quizEndedCallback?.call();
                      }
                    },
                    icon: Icon(Platform.isIOS
                        ? CupertinoIcons.back
                        : Icons.arrow_back),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(5.0),
                    child: LinearProgressIndicator(
                      minHeight: 5.0,
                      value: _progress,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                floatingActionButton: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildFloatingButtonWidget(),
                ),
                body: _buildPerfectMatchQuizWidget(),
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

  Widget _buildFloatingButtonWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FloatingActionButton(
          heroTag: null,
          shape: const CircleBorder(),
          onPressed: _navigateToPreviousPage,
          child: Icon(
            Platform.isIOS
                ? CupertinoIcons.back
                : Icons.navigate_before_rounded,
            size: 32.0,
          ),
        ),
        (_currentQuestion != null) && (_currentQuestion == _questions.last)
            ? SizedBox(
                width: 96.0,
                child: FilledButton(
                  onPressed: _navigateToNextPage,
                  child: const Text('Done'),
                ),
              )
            : FloatingActionButton(
                heroTag: null,
                shape: const CircleBorder(),
                onPressed: _navigateToNextPage,
                child: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.forward
                      : Icons.navigate_next_rounded,
                  size: 32.0,
                ),
              )
      ],
    );
  }

  Widget _buildPerfectMatchQuizWidget() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        if (mounted) {
          setState(() {
            _currentQuestion = _questions[index];
            _currentAnswer = _currentQuestion?.answers
                .where((answer) => answer.selected)
                .firstOrNull;
            _progress =
                (_questions.indexOf(_currentQuestion!) + 1) / _questions.length;
          });
        }
      },
      itemBuilder: (context, index) {
        final question = _questions[index];
        return _buildQuestion(context, question);
      },
      itemCount: _questions.length,
    );
  }

  Future<void> _loadQuiz() async {
    final selectedAnswers = _currentUser.xProfile!.groups
        .where((group) => group.id == xProfileGroupPerfectMatchQuiz)
        .first;
    var xProfileFields = _connectionService.xProfileFields!;
    for (final xProfileField in xProfileFields) {
      if (xProfileField.groupId == xProfileGroupPerfectMatchQuiz) {
        List<PerfectMatchQuizAnswer> answers = [];
        final selectedAnswer = selectedAnswers.fields
            .where((field) => field.id == xProfileField.id)
            .first
            .value
            ?.unserialized
            ?.firstOrNull;
        for (final option in xProfileField.options!) {
          final selected = selectedAnswer != null &&
              selectedAnswer.removeEscapeCharacters() ==
                  option.name.removeEscapeCharacters();
          answers.add(
            PerfectMatchQuizAnswer(option, selected),
          );
        }
        _questions.add(
          PerfectMatchQuizQuestion(xProfileField, answers),
        );
      }
    }
    if (mounted) {
      setState(() {
        _currentQuestion = _questions.first;
        _currentAnswer = _currentQuestion?.answers
            .where((answer) => answer.selected)
            .firstOrNull;
        _progress =
            (_questions.indexOf(_currentQuestion!) + 1) / _questions.length;
      });
    }
  }

  Widget _buildQuestion(
      BuildContext context, PerfectMatchQuizQuestion question) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32.0),
          Text(
            question.question.name,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 32.0),
          Expanded(
            child: _buildAnswers(
              question,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAnswers(
    PerfectMatchQuizQuestion question,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: setHeightBetweenWidgets(
          question.answers
              .map((answer) => _buildAnswer(context, answer))
              .toList(),
          height: 8.0),
    );
  }

  Widget _buildAnswer(BuildContext context, PerfectMatchQuizAnswer answer) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: answer.selected ? 3.0 : 1.0,
          color: answer.selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
        ),
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: RadioListTile<PerfectMatchQuizAnswer>(
        value: answer,
        groupValue: _currentAnswer,
        onChanged: (PerfectMatchQuizAnswer? value) {
          if (mounted) {
            setState(() {
              _selectAnswer(value!);
            });
          }
        },
        title: Text(
          // Replace escape characters.
          answer.answer.name.removeEscapeCharacters(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Future<void> _selectAnswer(PerfectMatchQuizAnswer selectedAnswer) async {
    if (_currentQuestion == null) {
      return;
    }

    try {
      if (mounted) {
        LoadingIndicator().show(
          context: context,
        );
      }
      for (final answer in _currentQuestion!.answers) {
        answer.selected = answer == selectedAnswer;
      }
      _currentAnswer = selectedAnswer;

      // Post the new field value.
      var xProfileFieldPostRequest = XProfileFieldPostRequest(
        userId: _connectionService.currentUser!.id,
        fieldId: _currentQuestion!.question.id,
        value: selectedAnswer.answer.name,
      );
      await _connectionService
          .updateXProfileFieldData(xProfileFieldPostRequest);
      // Replace the existing field value so we don't need to fetch the logged
      // in user's profile information again.
      var memberField = _currentUser.xProfile!.groups
          .where((group) => group.id == xProfileGroupPerfectMatchQuiz)
          .first
          .fields
          .where((field) => field.id == _currentQuestion!.question.id)
          .first;
      // Replace escape characters.
      var name = selectedAnswer.answer.name.removeEscapeCharacters();
      memberField.value =
          MemberFieldValue(raw: name, rendered: name, unserialized: [name]);
      // Navigate to the next question.
      _navigateToNextPage();
      if (mounted) {
        LoadingIndicator().hide();
      }
    } on Exception catch (e) {
      if (mounted) {
        LoadingIndicator().hide();
      }
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  void _navigateToPreviousPage() {
    _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn);
  }

  void _navigateToNextPage() {
    if (_currentQuestion == _questions.last) {
      Navigator.of(context).pushReplacementNamed(
        perfectMatchQuizFinishRoute,
        arguments: _quizEndedCallback,
      );
    } else {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn);
    }
  }
}

class PerfectMatchQuizQuestion {
  final XProfileField question;
  final List<PerfectMatchQuizAnswer> answers;
  PerfectMatchQuizQuestion(this.question, this.answers);
}

class PerfectMatchQuizAnswer {
  final XProfileField answer;
  bool selected;

  PerfectMatchQuizAnswer(this.answer, this.selected);
}
