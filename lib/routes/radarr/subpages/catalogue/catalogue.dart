import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:copularr/logic/automation/radarr.dart';
import 'package:copularr/routes/radarr/subpages/details/movie.dart';
import 'package:copularr/routes/radarr/subpages/details/edit.dart';
import 'package:copularr/core.dart';
import 'package:copularr/widgets/ui.dart';

class Catalogue extends StatefulWidget {
    final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;

    Catalogue({
        Key key,
        @required this.refreshIndicatorKey,
    }) : super(key: key);

    @override
    State<Catalogue> createState() {
        return _State();
    }
}

class _State extends State<Catalogue> with TickerProviderStateMixin {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    final _searchController = TextEditingController();
    final _scrollController = ScrollController();
    AnimationController _animationController;
    String searchFilter = '';
    String _sortType = 'abc';
    bool _sortAsc = true;
    bool _loading = true;
    bool _hideUnmonitored = false;
    bool _hideFab = false;

    List<RadarrCatalogueEntry> _catalogueEntries = [];
    List<RadarrCatalogueEntry> _searchedEntries = [];

    @override
    void initState() {
        super.initState();
        _animationController = AnimationController(vsync: this, duration: kThemeAnimationDuration);
        _animationController?.forward();
        _searchController.addListener(() {
            if(mounted) {
                setState(() {
                    searchFilter = _searchController.text;
                    _searchedEntries = _catalogueEntries.where(
                        (entry) => searchFilter == 'null' || searchFilter == '' ? entry != null : entry.title.toLowerCase().contains(searchFilter.toLowerCase()),
                    ).toList();
                });
            }
        });
        _scrollController.addListener(() {
            if(_scrollController?.position?.userScrollDirection == ScrollDirection.reverse) {
                if(!_hideFab) {
                    _hideFab = true;
                    _animationController?.reverse();

                }
            } else if(_scrollController?.position?.userScrollDirection == ScrollDirection.forward) {
                if(_hideFab) {
                    _hideFab = false;
                    _animationController?.forward();
                }
            }
        });
        Future.delayed(Duration(milliseconds: 200)).then((_) {
            if(mounted) {
                widget.refreshIndicatorKey?.currentState?.show();
            } 
        });
    }

    @override
    void dispose() {
        _animationController?.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            floatingActionButton: _buildFloatingActionButton(),
            body: RefreshIndicator(
                key: widget.refreshIndicatorKey,
                backgroundColor: Color(Constants.SECONDARY_COLOR),
                onRefresh: _handleRefresh,
                child: _loading ? 
                    Notifications.centeredMessage('Loading...') :
                    _catalogueEntries == null ? 
                        Notifications.centeredMessage('Connection Error', showBtn: true, btnMessage: 'Refresh', onTapHandler: () {widget.refreshIndicatorKey?.currentState?.show();}) : 
                        _catalogueEntries.length == 0 ? 
                            Notifications.centeredMessage('No Movies Found', showBtn: true, btnMessage: 'Refresh', onTapHandler: () {widget.refreshIndicatorKey?.currentState?.show();}) :
                            _buildList(),
            ),
        );
    }

    Widget _buildFloatingActionButton() {
        if(_loading || _catalogueEntries == null) {
            return Container();
        }
        return ScaleTransition(
            child: FloatingActionButton(
                heroTag: null,
                child: Elements.getIcon(_hideUnmonitored ? Icons.visibility_off : Icons.visibility),
                tooltip: 'Hide/Unhide Unmonitored Movies',
                onPressed: () {
                    if(mounted) {
                        setState(() {
                            _hideUnmonitored = !_hideUnmonitored;
                        });
                    }
                },
            ),
            scale: _animationController,
        );
    }

    Future<void> _handleRefresh() async {
        if(mounted) {
            setState(() {
                _loading = true;
                _catalogueEntries = [];
                _searchedEntries = [];
                _hideUnmonitored = false;
            });
        }
        _catalogueEntries = await RadarrAPI.getAllMovies();
        await _sortQueue();
        if(mounted) {
            setState(() {
                _loading = false;
            });
        }
    }

    Future<void> _sortQueue({ bool keepSearched = false }) async {
        if(_catalogueEntries != null && _catalogueEntries.length != 0) {
            switch(_sortType) {
                case 'size': {
                    if(_sortAsc) {
                        _catalogueEntries.sort((a,b) => b.sizeOnDisk.compareTo(a.sizeOnDisk));
                        if(keepSearched) _searchedEntries.sort((a,b) => b.sizeOnDisk.compareTo(a.sizeOnDisk));
                    } else {
                        _catalogueEntries.sort((a,b) => a.sizeOnDisk.compareTo(b.sizeOnDisk));
                        if(keepSearched) _searchedEntries.sort((a,b) => a.sizeOnDisk.compareTo(b.sizeOnDisk));
                    }
                    break;
                }
                case 'abc':
                default: {
                    if(_sortAsc) {
                        _catalogueEntries.sort((a,b) => a.sortTitle.compareTo(b.sortTitle));
                        if(keepSearched) _searchedEntries.sort((a,b) => a.sortTitle.compareTo(b.sortTitle));
                    } else {
                        _catalogueEntries.sort((a,b) => b.sortTitle.compareTo(a.sortTitle));
                        if(keepSearched) _searchedEntries.sort((a,b) => b.sortTitle.compareTo(a.sortTitle));
                    }
                    break;
                }
            }
            if(!keepSearched) {
                _searchedEntries = _catalogueEntries;
                _searchController.text = '';
            }
        }
        if(mounted) setState(() {});
    }

    Widget _noEntries(String message) {
        return Card(
            child: ListTile(
                title: Text(
                    message,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                    ),
                ),
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }

    Widget _buildList() {
        bool monitored = false;
        if(_hideUnmonitored) {
            for(var entry in _searchedEntries) {
                if(entry.monitored) {
                    monitored = true;
                    break;
                }
            }
        }
        return Scrollbar(
            child: ListView.builder(
                controller: _scrollController,
                itemCount: (_searchedEntries.length == 0 || (_hideUnmonitored && !monitored)) ? 2 : _searchedEntries.length+1,
                itemBuilder: (context, index) {
                    if((_searchedEntries.length == 0 || (_hideUnmonitored && !monitored))) {
                        return index == 0 ? _buildSearchSort() : _noEntries(_hideUnmonitored ? 'No Monitored Movies Found' : 'No Movies Found');
                    }
                    return index == 0 ? _buildSearchSort() : _buildEntry(_searchedEntries[index-1], index-1);
                },
                padding: Elements.getListViewPadding(),
                physics: AlwaysScrollableScrollPhysics(),
            ),
        );
    }

    Widget _buildSearchSort() {
        return Row(
            children: <Widget>[
                Expanded(
                    child: Card(
                        child: Padding(
                            child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                    labelText: 'Search Movies...',
                                    labelStyle: TextStyle(
                                        color: Colors.white54,
                                        decoration: TextDecoration.none,
                                    ),
                                    icon: Padding(
                                        child: Icon(
                                            Icons.search,
                                            color: Color(Constants.ACCENT_COLOR),
                                        ),
                                        padding: EdgeInsets.fromLTRB(20.0, 8.0, 0.0, 8.0),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                                ),
                                style: TextStyle(
                                    color: Colors.white,
                                ),
                                cursorColor: Color(Constants.ACCENT_COLOR),
                            ),
                            padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
                        ),
                        margin: Elements.getCardMargin(),
                        elevation: 4.0,
                    ),
                ),
                Card(
                    child: Padding(
                        child: PopupMenuButton<String>(
                            icon: Elements.getIcon(Icons.sort),
                            onSelected: (result) {
                                if(_sortType == result) {
                                    _sortAsc = !_sortAsc;
                                } else {
                                    _sortType = result;
                                    _sortAsc = true;
                                }
                                _sortQueue(keepSearched: true);
                            },
                            itemBuilder: (context) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                    value: 'abc',
                                    child: Text('Alphabetical'),
                                ),
                                PopupMenuItem<String>(
                                    value: 'size',
                                    child: Text('Size'),
                                ),
                            ],
                        ), 
                        padding: EdgeInsets.all(1.5),
                    ),
                    margin: EdgeInsets.fromLTRB(0.0, 6.0, 12.0, 6.0),
                    elevation: 4.0,
                ),
            ],
        );
    }

    Widget _buildEntry(RadarrCatalogueEntry entry, int index) {
        if(_hideUnmonitored && !entry.monitored) {
            return Container();
        }
        return Card(
            child: Container(
                child: ListTile(
                    title: Elements.getTitle(entry.title, darken: !entry.monitored),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                            Elements.getSubtitle('${entry.year}${Functions.runtimeReadable(entry.runtime, withDot: true)}${entry.profileString}', preventOverflow: true, darken: !entry.monitored),
                            Row(
                                children: <Widget>[
                                    Padding(
                                        child: Icon(
                                            Icons.videocam,
                                            size: 18.0,
                                            color: entry.isInCinemas ?
                                                entry.monitored ? Colors.orange : Colors.orange.withOpacity(0.30) :
                                                entry.monitored ? Colors.grey : Colors.grey.withOpacity(0.30),
                                        ),
                                        padding: EdgeInsets.fromLTRB(0.0, 3.0, 12.0, 3.0),
                                    ),
                                    Padding(
                                        child: Icon(
                                            Icons.album,
                                            size: 18.0,
                                            color: entry.isPhysicallyReleased ?
                                                entry.monitored ? Colors.blue : Colors.blue.withOpacity(0.30) : 
                                                entry.monitored ? Colors.grey : Colors.grey.withOpacity(0.30),
                                        ),
                                        padding: EdgeInsets.fromLTRB(0.0, 3.0, 12.0, 3.0),
                                    ),
                                    Padding(
                                        child: Icon(
                                            Icons.check_circle,
                                            size: 18.0,
                                            color: entry.downloaded ?
                                                entry.monitored ? Color(Constants.ACCENT_COLOR) : Color(Constants.ACCENT_COLOR).withOpacity(0.30) :
                                                entry.monitored ? Colors.grey : Colors.grey.withOpacity(0.30),
                                        ),
                                        padding: EdgeInsets.fromLTRB(0.0, 3.0, 16.0, 3.0),
                                    ),
                                    Padding(
                                        child: RichText(
                                            text: entry.subtitle,
                                        ),
                                        padding: EdgeInsets.fromLTRB(0.0, 3.0, 0.0, 3.0),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    trailing: IconButton(
                        alignment: Alignment.center,
                        icon: Elements.getIcon(
                            entry.monitored ? Icons.turned_in : Icons.turned_in_not,
                            color: entry.monitored ? Colors.white : Colors.white30,
                        ),
                        tooltip: 'Toggle Monitored',
                        onPressed: () async {
                            if(await RadarrAPI.toggleMovieMonitored(entry.movieID, !entry.monitored)) {
                                if(mounted) {
                                    setState(() {
                                        entry.monitored = !entry.monitored;
                                    });
                                }
                                Notifications.showSnackBar(
                                    _scaffoldKey,
                                    entry.monitored ? 'Monitoring ${entry.title}' : 'No longer monitoring ${entry.title}',
                                );
                                _refreshSingleEntry(entry, index);
                            } else {
                                Notifications.showSnackBar(
                                    _scaffoldKey,
                                    entry.monitored ? 'Failed to stop monitoring ${entry.title}' : 'Failed to start monitoring ${entry.title}',
                                );
                            }
                        },
                    ),
                    onTap: () async {
                        _enterMovie(entry, index);
                    },
                    onLongPress: () async {
                        List<dynamic> values = await RadarrDialogs.showEditMoviePrompt(context, entry);
                        if(values[0]) {
                            switch(values[1]) {
                                case 'refresh_movie': {
                                    if(await RadarrAPI.refreshMovie(entry.movieID)) {
                                        Notifications.showSnackBar(_scaffoldKey, 'Refreshing ${entry.title}...');
                                    } else {
                                        Notifications.showSnackBar(_scaffoldKey, 'Failed to refresh ${entry.title}');
                                    }
                                    break;
                                }
                                case 'edit_movie': {
                                    await _enterEditMovie(entry);
                                    break;
                                }
                                case 'remove_movie': {
                                    values = await RadarrDialogs.showDeleteMoviePrompt(context);
                                    if(values[0]) {
                                        if(values[1]) {
                                            values = await SystemDialogs.showDeleteCatalogueWithFilesPrompt(context, entry.title);
                                            if(values[0]) {
                                                if(await RadarrAPI.removeMovie(entry.movieID, deleteFiles: true)) {
                                                    Notifications.showSnackBar(_scaffoldKey, 'Removed ${entry.title}');
                                                    widget.refreshIndicatorKey?.currentState?.show();
                                                } else {
                                                    Notifications.showSnackBar(_scaffoldKey, 'Failed to remove ${entry.title}');
                                                }
                                            }
                                        } else {
                                            if(await RadarrAPI.removeMovie(entry.movieID)) {
                                                Notifications.showSnackBar(_scaffoldKey, 'Removed ${entry.title}');
                                                widget.refreshIndicatorKey?.currentState?.show();
                                            } else {
                                                Notifications.showSnackBar(_scaffoldKey, 'Failed to remove ${entry.title}');
                                            }
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    },
                    contentPadding: EdgeInsets.fromLTRB(12.0, 3.0, 12.0, 0.0),
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AdvancedNetworkImage(
                            entry.posterURI(),
                            useDiskCache: true,
                            loadFailedCallback: () {},
                            fallbackAssetImage: 'assets/images/secondary_color.png',
                            retryLimit: 1,
                        ),
                        colorFilter: new ColorFilter.mode(Color(Constants.SECONDARY_COLOR).withOpacity(entry.monitored ? 0.20: 0.10), BlendMode.dstATop),
                        fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                ),
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }

    Future<void> _enterMovie(RadarrCatalogueEntry entry, int index) async {
        final result = await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => RadarrMovieDetails(
                    entry: entry,
                    movieID: entry.movieID,
                ),
            ),
        );
        //Handle the result
        switch(result) {
            case 'movie_deleted': {
                Notifications.showSnackBar(_scaffoldKey, 'Removed ${entry.title}');
                widget.refreshIndicatorKey?.currentState?.show();
                break;
            }
            default: {
                _refreshSingleEntry(entry, index);
                break;
            }
        }
    }

    Future<void> _enterEditMovie(RadarrCatalogueEntry entry) async {
        final result = await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => RadarrEditMovie(entry: entry),
            ),
        );
        //Handle the result
        if(result != null) {
            switch(result[0]) {
                case 'updated_movie': {
                    if(mounted) {
                        setState(() {
                            entry = result[1];
                        });
                    }
                    Notifications.showSnackBar(_scaffoldKey, 'Updated ${entry.title}');
                    break;
                }
            }
        }
    }

    Future<void> _refreshSingleEntry(RadarrCatalogueEntry entry, int index) async {
        RadarrCatalogueEntry _entry = await RadarrAPI.getMovie(entry.movieID);
        _entry ??= _searchedEntries[index];
        if(mounted) {
            if(_searchedEntries[index]?.title == entry.title && mounted) {
                setState(() {
                    _searchedEntries[index] = _entry;
                });
            }
        }
    }
}
