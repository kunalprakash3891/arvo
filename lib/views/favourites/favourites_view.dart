import 'package:flutter/material.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/favourites/favourited_me_view.dart';
import 'package:arvo/views/favourites/my_favourites_view.dart';
import 'package:uuid/uuid.dart';

class FavouritesView extends StatefulWidget {
  const FavouritesView({super.key});

  @override
  State<FavouritesView> createState() => _FavouritesViewState();
}

class _FavouritesViewState extends State<FavouritesView> {
  late final FeatureService _featureService;
  late String _uuid;

  @override
  void initState() {
    super.initState();
    _featureService = FeatureService.arvo();
    _uuid = const Uuid().v1();
    _featureService.registerFunctionForUpdate(_uuid, () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _featureService.unregisterFunction(_uuid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0.0,
          title: TabBar(
            tabs: [
              const Tab(text: 'My Favourites'),
              _featureService.featureFavouritedMe
                  ? const Tab(
                      text: 'Favourited Me',
                    )
                  : Tab(
                      child: Row(
                        children: setWidthBetweenWidgets(
                          [
                            const Text('Favourited Me'),
                            Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                  color: kBasePremiumBackgroundColour,
                                  borderRadius: BorderRadius.circular(8.0)),
                              child: const Text(
                                'Premium',
                                style: TextStyle(
                                    color: kBasePremiumForegroundTextColour,
                                    fontSize: 10.0),
                              ),
                            ),
                          ],
                          width: 4.0,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MyFavouritesView(),
            FavouritedMeView(),
          ],
        ),
      ),
    );
  }
}
