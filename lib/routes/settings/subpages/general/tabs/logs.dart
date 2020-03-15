import 'package:flutter/material.dart';
import 'package:copularr/routes/settings/subpages/general/tabs/logs/type.dart';
import 'package:copularr/system.dart';
import 'package:copularr/widgets/ui.dart';

class Logs extends StatefulWidget {
    @override
    State<Logs> createState() {
        return _State();
    }
}

class _State extends State<Logs> {
    final _scaffoldKey = GlobalKey<ScaffoldState>();

    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            body: _logSettings(),
        );
    }

    Widget _logSettings() {
        return Scrollbar(
            child: ListView(
                children: <Widget>[
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('View Logs'),
                            subtitle: Elements.getSubtitle('View all recorded logs'),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.developer_mode),
                                onPressed: null,
                            ),
                            onTap: () async {
                                await _viewLogs();
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Elements.getDivider(),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Export Logs'),
                            subtitle: Elements.getSubtitle('Export all recorded logs'),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.file_download),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await SystemDialogs.showExportLogsPrompt(context);
                                if(_values[0]) {
                                    Logger.exportLogs();
                                    Notifications.showSnackBar(_scaffoldKey, 'Exported recorded logs to the filesystem');
                                }
                            },
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Clear Logs'),
                            subtitle: Elements.getSubtitle('Clear all recorded logs'),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.delete),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await SystemDialogs.showClearLogsPrompt(context);
                                if(_values[0]) {
                                    Logger.clearLogs();
                                    Notifications.showSnackBar(_scaffoldKey, 'All recorded logs have been cleared');
                                }
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

    Future<void> _viewLogs() async {
        await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => TypeLogs(),
            ),
        );
    }
}
