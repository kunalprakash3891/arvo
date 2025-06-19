import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:arvo/views/favourites/favourites_view.dart';
import 'package:arvo/views/home/home_view.dart';
import 'package:arvo/views/member_search/member_search_view.dart';
import 'package:arvo/views/messages/messages_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;
  List _loadedScreens = [
    0,
  ];
  late List<Widget> _screens;
  late final MessagingHandlerService _messagingHandlerService;

  @override
  void initState() {
    super.initState();
    _messagingHandlerService = MessagingHandlerService.arvo();
  }

  @override
  Widget build(BuildContext context) {
    // Lazy load screens.
    _screens = [
      const HomeView(),
      _loadedScreens.contains(1) ? const MemberSearchView() : Container(),
      _loadedScreens.contains(2) ? const FavouritesView() : Container(),
      _loadedScreens.contains(3) ? const MessagesView() : Container(),
    ];
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        await processBlocException(context: context, state: state);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            var pages = _loadedScreens;
            if (!pages.contains(index)) {
              pages.add(index);
            }
            if (mounted) {
              setState(
                () {
                  _currentIndex = index;
                  _loadedScreens = pages;
                },
              );
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.house_fill
                      : Icons.home_rounded,
                  size: 32.0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                  Platform.isIOS ? CupertinoIcons.search : Icons.search_rounded,
                  size: 32.0),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.heart_fill
                      : Icons.favorite_rounded,
                  size: 32.0),
              label: 'Favourites',
            ),
            BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(
                        Platform.isIOS
                            ? CupertinoIcons.text_bubble_fill
                            : Icons.message_rounded,
                        size: 32.0),
                    ValueListenableBuilder(
                      valueListenable: _messagingHandlerService
                          .unreadMessageCountUpdatedNotifier,
                      builder: (context, value, child) {
                        return value == 0
                            ? const SizedBox.shrink()
                            : Positioned(
                                right: 0.0,
                                top: 0.0,
                                child: Container(
                                  padding: const EdgeInsets.all(1.0),
                                  decoration: BoxDecoration(
                                    color: kBaseMonochromaticColour,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16.0,
                                    minHeight: 16.0,
                                  ),
                                  child: Text(
                                    '$value',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                      },
                    ),
                  ],
                ),
                label: 'Messages')
          ],
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
