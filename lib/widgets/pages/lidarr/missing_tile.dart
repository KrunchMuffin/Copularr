import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/routes/lidarr/routes.dart';
import 'package:lunasea/widgets/ui.dart';

class LidarrMissingTile extends StatefulWidget {
    final LidarrMissingEntry entry;
    final GlobalKey<ScaffoldState> scaffoldKey;
    final Function refresh;

    LidarrMissingTile({
        @required this.entry,
        @required this.scaffoldKey,
        @required this.refresh,
    });

    @override
    State<LidarrMissingTile> createState() => _State();
}

class _State extends State<LidarrMissingTile> {
    @override
    Widget build(BuildContext context) => LSCardTile(
        title: LSTitle(text: widget.entry.artistTitle),
        subtitle: RichText(
            text: TextSpan(
                children: <TextSpan>[
                    TextSpan(
                        text: widget.entry.title,
                        style: TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                        ),
                    ),
                    TextSpan(
                        text: '\nReleased ${widget.entry.releaseDateString}',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                        ),
                    ),
                ],
            ),
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 2,
        ),
        trailing: LSIconButton(
            icon: Icons.search,
            onPressed: () async => _search(),
        ),
        onTap: () async => _enterAlbum(),
        onLongPress: () async => _enterArtist(),
        decoration: LSCardBackground(uri: widget.entry.bannerURI()),
        padContent: true,
    );

    Future<void> _search() async {
        final _api = LidarrAPI.from(Database.currentProfileObject);
        await _api.searchAlbums([widget.entry.albumID])
            ? LSSnackBar(context: context, title: 'Searching...', message: widget.entry.title)
            : LSSnackBar(context: context, title: 'Failed to Search', message: widget.entry.title, type: SNACKBAR_TYPE.failure);
    }

    Future<void> _enterArtist() async {
        final dynamic result = await Navigator.of(context).pushNamed(
            LidarrDetailsArtist.ROUTE_NAME,
            arguments: LidarrDetailsArtistArguments(
                data: null,
                artistID: widget.entry.artistID,
            ),
        );
        if(result != null) switch(result[0]) {
            case 'remove_artist': {
                LSSnackBar(
                    context: context,
                    title: result[1] ? 'Removed (With Data)' : 'Removed',
                    message: widget.entry.title,
                );
                widget.refresh();
                break;
            }
        }
    }

    Future<void> _enterAlbum() async => await Navigator.of(context).pushNamed(LidarrDetailsAlbum.ROUTE_NAME);
}