import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lunasea/core.dart';

class LSSliverAppBarTabs extends StatelessWidget {
    final String title;
    final String backgroundURI;
    final List<Widget> actions;
    final Widget body;
    final Widget bottom;

    LSSliverAppBarTabs({
        @required this.title,
        @required this.backgroundURI,
        this.actions,
        @required this.body,
        @required this.bottom,
    });

    @override
    Widget build(BuildContext context) => NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
                child: SliverSafeArea(
                    top: false,
                    bottom: false,
                    sliver: SliverAppBar(
                        expandedHeight: 200.0,
                        pinned: true,
                        elevation: Constants.UI_ELEVATION,
                        flexibleSpace: FlexibleSpaceBar(
                            titlePadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 64.0),
                            title: Container(
                                child: Text(
                                    title,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        letterSpacing: Constants.UI_LETTER_SPACING,
                                    ),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 96.0),
                            ),
                            background: Image(
                                image: AdvancedNetworkImage(
                                    backgroundURI,
                                    useDiskCache: true,
                                    fallbackAssetImage: 'assets/images/secondary_color.png',
                                    loadFailedCallback: () {},
                                    retryLimit: 1,
                                ),
                                fit: BoxFit.cover,
                                color: Color(Constants.SECONDARY_COLOR).withAlpha((255/1.5).floor()),
                                colorBlendMode: BlendMode.darken,
                            ),
                        ),
                        actions: actions,
                        bottom: bottom,
                    ),
                ),
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
        ],
        body: body,
    );
}
