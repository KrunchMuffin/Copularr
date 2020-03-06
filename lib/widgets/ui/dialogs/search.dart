import 'package:flutter/material.dart';
import 'package:lunasea/widgets.dart';
import 'package:lunasea/core.dart';

class LSDialogSearch {
    static Future<List> downloadNZB(BuildContext context) async {
        bool flag = false;
        await showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                title: LSDialog.title(text: 'Download NZB'),
                actions: <Widget>[
                    LSDialog.button(
                        text: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                    ),
                    LSDialog.button(
                        text: 'Download',
                        onPressed: () {
                            flag = true;
                            Navigator.of(context).pop();
                        },
                        textColor: LSColors.accent,
                    )
                ],
                content: LSDialog.content(
                    children: [
                        LSDialog.textContent(
                            text: 'Are you sure you want to download this NZB to your device?',
                        ),
                    ],
                ),
            ),
        );
        return [flag];
    }

    static Future<List> sendToClient(BuildContext context) async {
        bool flag = false;
        String service = '';
        await showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
                title: LSDialog.title(text: 'Send to Client'),
                actions: <Widget>[
                    LSDialog.button(
                        text: 'Cancel',
                        textColor: LSColors.accent,
                        onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
                content: ValueListenableBuilder(
                    valueListenable: Database.lunaSeaBox.listenable(keys: ['profile']),
                    builder: (context, lunaBox, widget) => ValueListenableBuilder(
                        valueListenable: Database.profilesBox.listenable(),
                        builder: (context, profilesBox, widget) => LSDialog.content(
                            noPadding: true,
                            children: <Widget>[
                                Padding(
                                    child: DropdownButton(
                                        icon: LSIcon(
                                            icon: Icons.arrow_drop_down,
                                            color: LSColors.accent,
                                        ),
                                        underline: Container(
                                            height: 2,
                                            color: LSColors.accent,
                                        ),
                                        value: lunaBox.get('profile'),
                                        items: (profilesBox as Box).keys.map<DropdownMenuItem<String>>((dynamic value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                        )).toList(),
                                        onChanged: (value) {
                                            lunaBox.put('profile', value);
                                        },
                                        isExpanded: true,
                                    ),
                                    padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                                ),
                                if(Database.currentProfileObject.sabnzbdEnabled) LSDialog.tile(
                                    icon: true,
                                    iconData: CustomIcons.sabnzbd,
                                    iconColor: LSColors.list(0),
                                    text: 'SABnzbd',
                                    onTap: () {
                                        flag = true;
                                        service = 'sabnzbd';
                                        Navigator.of(context).pop();
                                    }
                                ),
                                if(Database.currentProfileObject.nzbgetEnabled) LSDialog.tile(
                                    icon: true,
                                    iconData: CustomIcons.nzbget,
                                    iconColor: LSColors.list(1),
                                    text: 'NZBGet',
                                    onTap: () {
                                        flag = true;
                                        service = 'nzbget';
                                        Navigator.of(context).pop();
                                    }
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
        return [flag, service];
    }
}