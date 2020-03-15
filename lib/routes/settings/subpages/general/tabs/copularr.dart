import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:copularr/logic/system/version.dart';
import 'package:copularr/core.dart';
import 'package:copularr/widgets/ui.dart';

class Copularr extends StatefulWidget {
    @override
    State<Copularr> createState() {
        return _State();
    }
}

class _State extends State<Copularr> {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    String _version;
    String _buildNumber;

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            body: _systemLinks(),
        );
    }

    @override
    void initState() {
        super.initState();
        _fetchVersion();
    }

    void _fetchVersion() async {
        PackageInfo info = await PackageInfo.fromPlatform();
        if(mounted) {
            setState(() {
                _version = info.version;
                _buildNumber = info.buildNumber;
            });
        }
    }

    Widget _systemLinks() {
        return Scrollbar(
            child: ListView(
                children: <Widget>[
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Version: $_version ($_buildNumber)'),
                            subtitle: Elements.getSubtitle('View recent changes in Copularr'),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.system_update),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List changes = await System.getChangelog();
                                await SystemDialogs.showChangelogPrompt(context, changes);
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Elements.getDivider(),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Documentation'),
                            subtitle: Elements.getSubtitle('Discover all the features of Copularr'),
                            trailing: IconButton(
                                icon: Elements.getIcon(CustomIcons.documentation),
                                onPressed: null,
                            ),
                            onTap: () async {
                                await Functions.openURL('https://docs.copularr.app');
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('GitHub'),
                            subtitle: Elements.getSubtitle('View the source code'),
                            trailing: IconButton(
                                icon: Elements.getIcon(CustomIcons.github),
                                onPressed: null,
                            ),
                            onTap: () async {
                                await Functions.openURL('https://github.com/JagandeepBrar/Copularr');
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Reddit'),
                            subtitle: Elements.getSubtitle('Get support and request features'),
                            trailing: IconButton(
                                icon: Elements.getIcon(CustomIcons.reddit),
                                onPressed: null,
                            ),
                            onTap: () async {
                                await Functions.openURL('https://www.reddit.com/r/CopularrApp');
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Website'),
                            subtitle: Elements.getSubtitle('Visit Copularr\'s website'),
                            trailing: IconButton(
                                icon: Elements.getIcon(CustomIcons.home),
                                onPressed: null,
                            ),
                            onTap: () async {
                                await Functions.openURL('https://www.copularr.app');
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                ],
                padding: Elements.getListViewPadding(),
            ),
        );
    }
}
