import 'package:flutter/material.dart';
import 'package:copularr/logic/automation/radarr.dart';
import 'package:copularr/routes/radarr/subpages/catalogue/addmovie/details.dart';
import 'package:copularr/core.dart';
import 'package:copularr/widgets/ui.dart';

class RadarrMovieSearch extends StatefulWidget {
    @override
    State<RadarrMovieSearch> createState() {
        return _State();
    }  
}

class _State extends State<RadarrMovieSearch> {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    final _searchController = TextEditingController();

    bool _searched = false;
    String _message = 'No Movies Found';
    List<RadarrSearchEntry> _entries = [];
    List<int> _availableIDs = [];

    @override
    void initState() {
        super.initState();
        _fetchAvailableMovies();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            appBar: Navigation.getAppBar('Add Movie', context),
            body: _buildList(),
            floatingActionButton: _buildFloatingActionButton(),
        );
    }

    Future<void> _startSearch() async {
        if(mounted) {
            setState(() {
                _entries = [];
                _message = 'Searching...';
                _searched = true;
            });
        }
        _entries = await RadarrAPI.searchMovies(_searchController.text);
        if(mounted) {
            setState(() {
                _message = _entries == null ? 'Connection Error' : 'No Movies Found';
            });
        }
    }

    Future<void> _fetchAvailableMovies() async {
        _availableIDs = await RadarrAPI.getAllMovieIDs();
        _availableIDs ??= [];
    }

    Widget _buildFloatingActionButton() {
        return FloatingActionButton(
            heroTag: null,
            tooltip: 'Search',
            child: Elements.getIcon(Icons.search),
            onPressed: _startSearch,
        );
    }

    Widget _buildList() {
        return Scrollbar(
            child: ListView.builder(
                itemCount: _entries == null || _entries.length == 0 ?  _searched ? 3 : 1 : _entries.length+2,
                itemBuilder: (context, index) {
                    switch(index) {
                        case 0: return _buildSearchBar();
                        case 1: return Elements.getDivider();
                    }
                    return _entries == null || _entries.length == 0 ?
                        Notifications.centeredMessage(_message) :
                        _buildEntry(_entries[index-2]);
                },
                padding: Elements.getListViewPadding(extraBottom: true),
            ),
        );
    }

    Widget _buildSearchBar() {
        return Card(
            child: Padding(
                child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                        labelText: 'Search...',
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
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                        _startSearch();
                    },
                ),
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }

    Widget _buildEntry(RadarrSearchEntry entry) {
        bool alreadyAdded = _availableIDs.contains(entry.tmdbId);
        return Card(
            child: Container(
                child: ListTile(
                    title: Elements.getTitle(entry.title, darken: alreadyAdded),
                    subtitle: Elements.getSubtitle(entry.overview, preventOverflow: true, darken: alreadyAdded),
                    trailing: !alreadyAdded ? IconButton(
                        icon: Elements.getIcon(
                            Icons.arrow_forward_ios,
                            color: alreadyAdded ? Colors.white30 : Colors.white,
                        ),
                        onPressed: null,
                    ) : null,
                    onTap: () async {
                        alreadyAdded
                            ? Notifications.showSnackBar(_scaffoldKey, '${entry.title} is already in Radarr')
                            : await _enterMovieDetails(entry);
                    },
                ),
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }

    Future<void> _enterMovieDetails(RadarrSearchEntry entry) async {
        final result = await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => RadarrMovieSearchDetails(entry: entry),
            ),
        );
        //Handle the result
        if(result != null) {
            switch(result[0]) {
                case 'movie_added': {
                    Navigator.of(context).pop(result);
                    break;
                }
            }
        }
    }
}