import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/animation/fade_animation.dart';
import 'package:lottie/lottie.dart';
import 'package:app_base/generics/get_arguments.dart';

class PerfectMatchQuizStartView extends StatefulWidget {
  const PerfectMatchQuizStartView({super.key});

  @override
  State<PerfectMatchQuizStartView> createState() =>
      _PerfectMatchQuizStartViewState();
}

class _PerfectMatchQuizStartViewState extends State<PerfectMatchQuizStartView> {
  Function? _quizEndedCallback;

  @override
  Widget build(BuildContext context) {
    // Optional function that will be executed when quiz ends.
    _quizEndedCallback = _quizEndedCallback ?? context.getArgument<Function>();

    return Scaffold(
      backgroundColor: kBaseCoastalTeal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: FadeAnimation(
              1.0,
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: setHeightBetweenWidgets(
                    [
                      Lottie.asset(
                        'assets/animations/question_answer_animation.json',
                        fit: BoxFit.fill,
                        repeat: false,
                      ),
                      Text(
                        "Fair Dinkum Dating Quiz",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text(
                        "Take the quiz to increase your profile strength, and also improve the quality of percentage match ratings with others.",
                        textAlign: TextAlign.center,
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(
                            perfectMatchQuizRoute,
                            arguments: _quizEndedCallback,
                          );
                        },
                        child: const Text(
                          'Start',
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text(
                              'Go Back',
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
      ),
    );
  }
}
