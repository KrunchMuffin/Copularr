import 'package:flutter/material.dart';
import 'package:copularr/widgets/ui.dart';

class Indexers extends StatefulWidget {
    @override
    State<Indexers> createState() {
        return _State();
    }
}

class _State extends State<Indexers> {
    final _scaffoldKey = GlobalKey<ScaffoldState>();

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            appBar: Navigation.getAppBar('Settings', context),
            body: Notifications.centeredMessage('Coming Soon'),
        );
    }
}
