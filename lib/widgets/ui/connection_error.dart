import 'package:flutter/material.dart';
import 'package:copularr/widgets.dart';

class ConnectionError extends StatelessWidget {
    final Function onTapHandler;

    ConnectionError({
        Key key,
        @required this.onTapHandler,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) => 
    Notifications.centeredMessage(
        'Connection Error',
        btnMessage: 'Refresh',
        showBtn: true,
        onTapHandler: onTapHandler,
    );
}
