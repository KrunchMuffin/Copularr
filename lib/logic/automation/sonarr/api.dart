import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:copularr/system.dart';
import 'package:copularr/logic/automation/sonarr.dart';

class SonarrAPI {
    SonarrAPI._();

    static void logWarning(String methodName, String text) {
        Logger.warning('package:copularr/logic/automation/sonarr/api.dart', methodName, 'Sonarr: $text');
    }

    static void logError(String methodName, String text, Object error) {
        Logger.error('package:copularr/logic/automation/sonarr/api.dart', methodName, 'Sonarr: $text', error, StackTrace.current);
    }
    
    static Future<bool> testConnection(List<dynamic> values) async {
        try {
            String uri = '${values[1]}/api/system/status?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                Map body = json.decode(response.body);
                if(body.containsKey('version')) {
                    return true;
                }
            }
        } catch (e) {
            logError('testConnection', 'Connection test failed', e);
            return false;
        }
        logWarning('testConnection', 'Connection test failed');
        return false;
    }

    static Future<int> getSeriesCount() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return -1;
        }
        try {
            String uri = '${values[1]}/api/series?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                return body.length ?? 0;
            } else {
                logError('getSeriesCount', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getSeriesCount', 'Failed to fetch series count', e);
            return -1;
        }
        logWarning('getSeriesCount', 'Failed to fetch series count');
        return -1;
    }

    static Future<bool> refreshSeries(int seriesID) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uri = '${values[1]}/api/command?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'name': 'RefreshSeries',
                    'seriesId': seriesID,
                }),
            );
            if(response.statusCode == 201) {
                Map body = json.decode(response.body);
                if(body.containsKey('status')) {
                    return true;
                }
            } else {
                logError('refreshSeries', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('refreshSeries', 'Failed to refresh series ($seriesID)', e);
            return false;
        }
        logWarning('refreshSeries', 'Failed to refresh series ($seriesID)');
        return false;
    }

    static Future<bool> removeSeries(int seriesID, { deleteFiles = false }) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uri = '${values[1]}/api/series/$seriesID?apikey=${values[2]}&deleteFiles=$deleteFiles';
            http.Response response = await http.delete(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                Map body = json.decode(response.body);
                if(body.length == 0) {
                    return true;
                }
            } else {
                logError('removeSeries', '<DELETE> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('removeSeries', 'Failed to remove series ($seriesID)', e);
            return false;
        }
        logWarning('removeSeries', 'Failed to remove series ($seriesID)');
        return false;
    }

    static Future<List<SonarrSearchEntry>> searchSeries(String search) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        if(search == '') {
            return [];
        }
        try {
            List<SonarrSearchEntry> entries = [];
            String uri = '${values[1]}/api/series/lookup?term=$search&apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                for(var entry in body) {
                    entries.add(SonarrSearchEntry(
                        entry['title'] ?? 'Unknown Title',
                        entry['overview'] == null || entry['overview'] == '' ? 'No summary is available' : entry['overview'],
                        entry['seasonCount'] ?? 0,
                        entry['status'] ?? 'Unknown Status',
                        entry['images'] ?? [],
                        entry['seasons'] ?? [],
                        entry['tvdbId'] ?? 0,
                        entry['tvMazeId'] ?? 0,
                        entry['imdbId'] ?? '',
                    ));
                }
                return entries;
            } else {
                logError('searchSeries', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('searchSeries', 'Failed to search ($search)', e);
            return null;
        }
        logWarning('searchSeries', 'Failed to search ($search)');
        return null;
    }

    static Future<bool> addSeries(SonarrSearchEntry entry, SonarrQualityProfile qualityProfile, SonarrRootFolder rootFolder, SonarrSeriesType seriesType, bool seasonFolders, bool monitored, {bool search = false}) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uri = '${values[1]}/api/series?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'addOptions': {
                        'ignoreEpisodesWithFiles': true,
                        'ignoreEpisodesWithoutFiles': false,
                        'searchForMissingEpisodes': search,
                    },
                    'tvdbId': entry.tvdbId,
                    'title': entry.title,
                    'titleSlug': entry.titleSlug,
                    'profileId': qualityProfile.id,
                    'images': entry.images,
                    'seasons': entry.seasons,
                    'rootFolderPath': rootFolder.path,
                    'monitored': monitored,
                    'seriesType': seriesType.type,
                    'seasonFolder': seasonFolders,
                }),
            );
            if(response.statusCode == 201) {
                return true;
            } else {
                logError('addSeries', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('addSeries', 'Failed to add series (${entry.title})', e);
            return false;
        }
        logWarning('addSeries', 'Failed to add series (${entry.title})');
        return false;
    }

    static Future<bool> editSeries(int seriesID, SonarrQualityProfile qualityProfile, SonarrSeriesType seriesType, String path, bool monitored, bool seasonFolder) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uriGet = '${values[1]}/api/series/$seriesID?apikey=${values[2]}';
            String uriPut = '${values[1]}/api/series?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uriGet),
            );
            if(response.statusCode == 200) {
                Map series = json.decode(response.body);
                series['monitored'] = monitored;
                series['seasonFolder'] = seasonFolder;
                series['profileId'] = qualityProfile.id;
                series['seriesType'] = seriesType.type;
                series['path'] = path;
                response = await http.put(
                    Uri.encodeFull(uriPut),
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: json.encode(series),
                );
                if(response.statusCode == 202) {
                    return true;
                } else {
                    logError('editSeries', '<PUT> HTTP Status Code (${response.statusCode})', null);
                }
            } else {
                logError('editSeries', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('editSeries', 'Failed to edit series ($seriesID)', e);
            return false;
        }
        logWarning('editSeries', 'Failed to edit series ($seriesID)');
        return false;
    }

    static Future<SonarrCatalogueEntry> getSeries(int seriesID) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            Map<int, SonarrQualityProfile> _qualities = await getQualityProfiles();
            if(_qualities != null) {
                String uri = '${values[1]}/api/series/$seriesID?apikey=${values[2]}';
                http.Response response = await http.get(
                    Uri.encodeFull(uri),
                );
                if(response.statusCode == 200) {
                    Map body = json.decode(response.body);
                    List<dynamic> _seasonData = body['seasons'];
                    _seasonData.sort((a, b) => a['seasonNumber'].compareTo(b['seasonNumber']));
                    SonarrCatalogueEntry entry = SonarrCatalogueEntry(
                        body['title'] ?? 'Unknown Title',
                        body['sortTitle'] ?? 'Unknown Title',
                        body['seasonCount'] ?? 0,
                        _seasonData ?? [],
                        body['episodeCount'] ?? 0,
                        body['episodeFileCount'] ?? 0,
                        body['status'] ?? 'Unknown Status',
                        body['id'] ?? -1,
                        body['previousAiring'] ?? '',
                        body['nextAiring'] ?? '',
                        body['network'] ?? 'Unknown Network',
                        body['monitored'] ?? false,
                        body['path'] ?? 'Unknown Path',
                        body['qualityProfileId'] ?? 0,
                        body['seriesType'] ?? 'Unknown Series Type',
                        body['seasonFolder'] ?? false,
                        body['overview'] ?? 'No summary is available',
                        body['tvdbId'] ?? 0,
                        body['tvMazeId'] ?? 0,
                        body['imdbId'] ?? '',
                        body['runtime'] ?? 0,
                        body['profileId'] != null ? _qualities[body['qualityProfileId']].name : '',
                        body['sizeOnDisk'] ?? 0,
                    );
                    return entry;
                } else {
                    logError('getSeries', '<GET> HTTP Status Code (${response.statusCode})', null);
                }
            }
        } catch (e) {
            logError('getSeries', 'Failed to fetch series ($seriesID)', e);
            return null;
        }
        logWarning('getSeries', 'Failed to fetch series ($seriesID)');
        return null;
    }

    static Future<List<SonarrCatalogueEntry>> getAllSeries() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            Map<int, SonarrQualityProfile> _qualities = await getQualityProfiles();
            List<SonarrCatalogueEntry> entries = [];
            if(_qualities != null) {
                String uri = '${values[1]}/api/series?apikey=${values[2]}';
                http.Response response = await http.get(
                    Uri.encodeFull(uri),
                ); 
                if(response.statusCode == 200) {
                    List body = json.decode(response.body);
                    for(var entry in body) {
                        List<dynamic> _seasonData = entry['seasons'];
                        _seasonData.sort((a, b) => a['seasonNumber'].compareTo(b['seasonNumber']));
                        entries.add(
                            SonarrCatalogueEntry(
                                entry['title'] ?? 'Unknown Title',
                                entry['sortTitle'] ?? 'Unknown Title',
                                entry['seasonCount'] ?? 0,
                                _seasonData ?? [],
                                entry['episodeCount'] ?? 0,
                                entry['episodeFileCount'] ?? 0,
                                entry['status'] ?? 'Unknown Status',
                                entry['id'] ?? -1,
                                entry['previousAiring'] ?? '',
                                entry['nextAiring'] ?? '',
                                entry['network'] ?? 'Unknown Network',
                                entry['monitored'] ?? false,
                                entry['path'] ?? 'Unknown Path',
                                entry['qualityProfileId'] ?? 0,
                                entry['seriesType'] ?? 'Unknown Series Type',
                                entry['seasonFolder'] ?? false,
                                entry['overview'] ?? 'No summary is available',
                                entry['tvdbId'] ?? 0,
                                entry['tvMazeId'] ?? 0,
                                entry['imdbId'] ?? '',
                                entry['runtime'] ?? 0,
                                entry['profileId'] != null ? _qualities[entry['qualityProfileId']].name : '',
                                entry['sizeOnDisk'] ?? 0,
                            ),
                        );
                    }
                    return entries;
                } else {
                    logError('getAllSeries', '<GET> HTTP Status Code (${response.statusCode})', null);
                }
            }
        } catch (e) {
            logError('getAllSeries', 'Failed to fetch all series', e);
            return null;
        }
        logWarning('getAllSeries', 'Failed to fetch all series');
        return null;
    }

    static Future<List<int>> getAllSeriesIDs() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            List<int> _entries = [];
            String uri = '${values[1]}/api/series?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                for(var entry in body) {
                    _entries.add(entry['tvdbId'] ?? 0);
                }
                return _entries;
            } else {
                logError('getAllSeriesIDs', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getAllSeriesIDs', 'Failed to fetch all series IDs', e);
            return null;
        }
        logWarning('getAllSeriesIDs', 'Failed to fetch all series IDs');
        return null;
    }

    static Future<Map> getUpcoming({int duration = 7}) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            DateTime now = DateTime.now();
            String start = DateFormat('y-MM-dd').format(now);
            String end = DateFormat('y-MM-dd').format(now.add(Duration(days: duration)));
            String uri = '${values[1]}/api/calendar?apikey=${values[2]}&start=$start&end=$end';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                if(body.length <= 0) {
                    return {};
                }
                Map entries = {};
                for(int i=0; i<duration; i++) {
                    entries[DateFormat('y-MM-dd').format(now.add(Duration(days: i)))] = {
                        'date': DateFormat('EEEE\nMMMM dd, y').format(now.add(Duration(days: i))),
                        'entries': [],
                    };
                }
                for(var entry in body) {
                    DateTime date = DateTime.tryParse(entry['airDateUtc'])?.toLocal();
                    if(date != null) {
                        String dateParsed = DateFormat('y-MM-dd').format(date);
                        if(entries.containsKey(dateParsed)) {
                            entries[dateParsed]['entries'].add(SonarrUpcomingEntry(
                                entry['series']['title'] ?? 'Unknown Series Title',
                                entry['title'] ?? 'Unknown Episode Title',
                                entry['seasonNumber'] ?? 0,
                                entry['episodeNumber'] ?? 0,
                                entry['series']['id'] ?? -1,
                                entry['id'] ?? -1,
                                entry['airDateUtc'] ?? '',
                                entry['hasFile'] ?? false,
                                entry['hasFile'] ? entry['episodeFile']['quality']['quality']['name'] : '',
                            ));
                        }
                    }
                }
                return entries;
            } else {
                logError('getUpcoming', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getUpcoming', 'Failed to fetch upcoming episodes', e);
            return null;
        }
        logWarning('getUpcoming', 'Failed to fetch upcoming episodes');
        return null;
    }

    static Future<List<SonarrHistoryEntry>> getHistory() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/history?apikey=${values[2]}&sortKey=date&pageSize=250&sortDir=desc';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List<SonarrHistoryEntry> _entries = [];
                Map body = json.decode(response.body);
                for(var entry in body['records']) {
                    switch(entry['eventType']) {
                        case 'downloadFolderImported': {
                            _entries.add(SonarrHistoryEntryDownloadImported(
                                entry['seriesId'] ?? -1,
                                entry['series']['title'] ?? 'Unknown Series Title',
                                entry['episode']['title'] ?? 'Unknown Episode Title',
                                entry['episode']['episodeNumber'] ?? 0,
                                entry['episode']['seasonNumber'] ?? 0,
                                entry['date'] ?? '',
                                entry['quality']['quality']['name'] ?? '',
                            ));
                            break;
                        }
                        case 'downloadFailed': {
                            _entries.add(SonarrHistoryEntryDownloadFailed(
                                entry['seriesId'] ?? -1,
                                entry['series']['title'] ?? 'Unknown Series Title',
                                entry['episode']['title'] ?? 'Unknown Episode Title',
                                entry['episode']['episodeNumber'] ?? 0,
                                entry['episode']['seasonNumber'] ?? 0,
                                entry['date'] ?? '',
                            ));
                            break;
                        }
                        case 'episodeFileDeleted': {
                            _entries.add(SonarrHistoryEntryEpisodeDeleted(
                                entry['seriesId'] ?? -1,
                                entry['series']['title'] ?? 'Unknown Series Title',
                                entry['episode']['title'] ?? 'Unknown Episode Title',
                                entry['episode']['episodeNumber'] ?? 0,
                                entry['episode']['seasonNumber'] ?? 0,
                                entry['date'] ?? '',
                                entry['data']['reason'] ?? 'Unknown Deletion Reason',
                            ));
                            break;
                        }
                        case 'episodeFileRenamed': {
                            _entries.add(SonarrHistoryEntryEpisodeRenamed(
                                entry['seriesId'] ?? -1,
                                entry['series']['title'] ?? 'Unknown Series Title',
                                entry['episode']['title'] ?? 'Unknown Episode Title',
                                entry['episode']['episodeNumber'] ?? 0,
                                entry['episode']['seasonNumber'] ?? 0,
                                entry['date'] ?? '',
                            ));
                            break;
                        }
                        case 'grabbed': {
                            _entries.add(SonarrHistoryEntryGrabbed(
                                entry['seriesId'] ?? -1,
                                entry['series']['title'] ?? 'Unknown Series Title',
                                entry['episode']['title'] ?? 'Unknown Episode Title',
                                entry['episode']['episodeNumber'] ?? 0,
                                entry['episode']['seasonNumber'] ?? 0,
                                entry['date'] ?? '',
                                entry['data']['indexer'] ?? 'Unknown Indexer',
                            ));
                            break;
                        }
                        default: {
                            _entries.add(SonarrHistoryEntryGeneric(
                                entry['seriesId'] ?? -1,
                                entry['series']['title'] ?? 'Unknown Series Title',
                                entry['episode']['title'] ?? 'Unknown Episode Title',
                                entry['episode']['episodeNumber'] ?? 0,
                                entry['episode']['seasonNumber'] ?? 0,
                                entry['date'] ?? '',
                                entry['eventType'] ?? 'Unknown Event Type',
                            ));
                            break;
                        }
                    }
                }
                return _entries;
            } else {
                logError('getHistory', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getHistory', 'Failed to fetch history', e);
            return null;
        }
        logWarning('getHistory', 'Failed to fetch history');
        return null;
    }

    static Future<Map> getEpisodes(int seriesID, int seasonNumber) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            Map _queue = await getQueue() ?? {};
            Map entries = {};
            String uri = '${values[1]}/api/episode?apikey=${values[2]}&seriesId=$seriesID';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                for(var entry in body) {
                    if(seasonNumber == -1 || entry['seasonNumber'] == seasonNumber) {
                        if(!entries.containsKey(entry['seasonNumber'])) {
                            entries[entry['seasonNumber']] = [];
                            entries[-1] = body.length;
                        }
                        String quality = '';
                        bool cutoffMet = false;
                        int size = 0;
                        SonarrQueueEntry _queueEntry;
                        if(entry['hasFile']) {
                            quality = entry['episodeFile']['quality']['quality']['name'];
                            cutoffMet = entry['episodeFile']['qualityCutoffNotMet'];
                            size = entry['episodeFile']['size'];
                        }
                        if(_queue.containsKey(entry['id'])) {
                            _queueEntry = _queue[entry['id']];
                        }
                        entries[entry['seasonNumber']].add(SonarrEpisodeEntry(
                            entry['title'] ?? 'Unknown Title',
                            entry['seasonNumber'] ?? 0,
                            entry['episodeNumber'] ?? 0,
                            entry['airDateUtc'] ?? '',
                            entry['id'] ?? -1,
                            entry['episodeFileId'] ?? -1,
                            entry['monitored'] ?? false,
                            entry['hasFile'] ?? false,
                            quality ?? 'Unknown Quality',
                            cutoffMet ?? false,
                            size ?? 0,
                            _queueEntry ?? null,
                        ));
                    }
                }
                return entries;
            } else {
                logError('getEpisodes', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getEpisodes', 'Failed to fetch episodes ($seriesID, $seasonNumber)', e);
            return null;
        }
        logWarning('getEpisodes', 'Failed to fetch episodes ($seriesID, $seasonNumber)');
        return null;
    }

    static Future<Map> getQueue() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = "${values[1]}/api/queue?apikey=${values[2]}";
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                Map entries = {};
                for(var entry in body) {
                    entries[entry['episode']['id']] = SonarrQueueEntry(
                        entry['episode']['id'] ?? 0,
                        entry['size'] ?? 0.0,
                        entry['sizeleft'] ?? 0.9,
                        entry['status'] ?? 'Unknown Status',
                    );
                }
                return entries;
            } else {
                logError('getQueue', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getQueue', 'Failed to fetch queue', e);
            return null;
        }
        logWarning('getQueue', 'Failed to fetch queue');
        return null;
    }

    static Future<List<SonarrMissingEntry>> getMissing() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            List<SonarrMissingEntry> entries = [];
            String uri = "${values[1]}/api/wanted/missing?apikey=${values[2]}&pageSize=200";
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                Map body = json.decode(response.body);
                for(var entry in body['records']) {
                    entries.add(SonarrMissingEntry(
                        entry['series']['title'] ?? 'Unknown Series Title',
                        entry['title'] ?? 'Unknown Episode Title',
                        entry['seasonNumber'] ?? 0,
                        entry['episodeNumber'] ?? 0,
                        entry['airDateUtc'] ?? '',
                        entry['series']['id'] ?? -1,
                        entry['id'] ?? -1,
                    ));
                }
                return entries;
            } else {
                logError('getMissing', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getMissing', 'Failed to fetch missing episodes', e);
            return null;
        }
        logWarning('getMissing', 'Failed to fetch missing episodes');
        return null;
    }

    static Future<bool> searchAllMissing() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/command?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'name': 'missingEpisodeSearch',
                }),
            );
            if(response.statusCode == 201) {
                Map body = json.decode(response.body);
                if(body.containsKey('status')) {
                    return true;
                }
            } else {
                logError('searchAllMissing', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('searchAllMissing', 'Failed to search for all missing episodes', e);
            return false;
        }
        logWarning('searchAllMissing', 'Failed to search for all missing episodes');
        return false;
    }

    static Future<bool> updateLibrary() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/command?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'name': 'refreshSeries',
                }),
            );
            if(response.statusCode == 201) {
                Map body = json.decode(response.body);
                if(body.containsKey('status')) {
                    return true;
                }
            } else {
                logError('updateLibrary', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('updateLibrary', 'Failed to update library', e);
            return false;
        }
        logWarning('updateLibrary', 'Failed to update library');
        return false;
    }

    static Future<bool> triggerRssSync() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/command?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'name': 'RssSync',
                }),
            );
            if(response.statusCode == 201) {
                Map body = json.decode(response.body);
                if(body.containsKey('status')) {
                    return true;
                }
            } else {
                logError('triggerRssSync', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('triggerRssSync', 'Failed to trigger RSS sync', e);
            return false;
        }
        logWarning('triggerRssSync', 'Failed to trigger RSS sync');
        return false;
    }

    static Future<bool> triggerBackup() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/command?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'name': 'Backup',
                }),
            );
            if(response.statusCode == 201) {
                Map body = json.decode(response.body);
                if(body.containsKey('status')) {
                    return true;
                }
            } else {
                logError('triggerBackup', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('triggerBackup', 'Failed to backup database', e);
            return false;
        }
        logWarning('triggerBackup', 'Failed to backup database');
        return false;
    }

    static Future<bool> searchSeason(int seriesID, int season) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/command?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'name': 'SeasonSearch',
                    'seriesId': seriesID,
                    'seasonNumber': season,
                }),
            );
            if(response.statusCode == 201) {
                Map body = json.decode(response.body);
                if(body.containsKey('status')) {
                    return true;
                }
            } else {
                logError('searchSeason', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('searchSeason', 'Failed to search for season ($seriesID, $season)', e);
            return false;
        }
        logWarning('searchSeason', 'Failed to search for season ($seriesID, $season)');
        return false;
    }

    static Future<bool> searchEpisodes(List<int> episodeIDs) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uri = '${values[1]}/api/command?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'name': 'EpisodeSearch',
                    'episodeIds': episodeIDs,
                }),
            );
            if(response.statusCode == 201) {
                Map body = json.decode(response.body);
                if(body.containsKey('status')) {
                    return true;
                }
            } else {
                logError('searchEpisodes', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('searchEpisodes', 'Failed to search for episodes (${episodeIDs.toString()})', e);
            return false;
        }
        logWarning('searchEpisodes', 'Failed to search for episodes (${episodeIDs.toString()})');
        return false;
    }

    static Future<bool> toggleSeriesMonitored(int seriesID, bool status) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uriGet = '${values[1]}/api/series/$seriesID?apikey=${values[2]}';
            String uriPut = '${values[1]}/api/series?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uriGet),
            );
            if(response.statusCode == 200) {
                Map body = json.decode(response.body);
                body['monitored'] = status;
                response = await http.put(
                    Uri.encodeFull(uriPut),
                    body: json.encode(body),
                    headers: {
                        "Content-Type": "application/json",
                    },
                );
                if(response.statusCode == 202) {
                    return true;
                } else {
                    logError('toggleSeriesMonitored', '<PUT> HTTP Status Code (${response.statusCode})', null);
                }
            } else {
                logError('toggleSeriesMonitored', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('toggleSeriesMonitored', 'Failed to toggle series monitored ($seriesID)', e);
            return false;
        }
        logWarning('toggleSeriesMonitored', 'Failed to toggle series monitored ($seriesID)');
        return false;
    }

    static Future<bool> toggleSeasonMonitored(int seriesID, int seasonID, bool status) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uriGet = '${values[1]}/api/series/$seriesID?apikey=${values[2]}';
            String uriPut = '${values[1]}/api/series?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uriGet),
            );
            if(response.statusCode == 200) {
                Map body = json.decode(response.body);
                for(var season in body['seasons']) {
                    if(season['seasonNumber'] == seasonID) {
                        season['monitored'] = status;
                    }
                }
                response = await http.put(
                    Uri.encodeFull(uriPut),
                    body: json.encode(body),
                    headers: {
                        "Content-Type": "application/json",
                    },
                );
                if(response.statusCode == 202) {
                    return true;
                } else {
                    logError('toggleSeasonMonitored', '<PUT> HTTP Status Code (${response.statusCode})', null);
                }
            } else {
                logError('toggleSeasonMonitored', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('toggleSeasonMonitored', 'Failed to toggle season monitored ($seriesID, $seasonID)', e);
            return false;
        }
        logWarning('toggleSeasonMonitored', 'Failed to toggle season monitored ($seriesID, $seasonID)');
        return false;
    }

    static Future<List<SonarrRootFolder>> getRootFolders() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/rootfolder?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                List<SonarrRootFolder> _entries = [];
                for(var entry in body) {
                    _entries.add(SonarrRootFolder(
                        entry['id'] ?? -1,
                        entry['path'] ?? 'Unknown Root Folder',
                    ));
                }
                return _entries;
            } else {
                logError('getRootFolders', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getRootFolders', 'Failed to fetch root folders', e);
            return null;
        }
        logWarning('getRootFolders', 'Failed to fetch root folders');
        return null;
    }

    static Future<Map<int, SonarrQualityProfile>> getQualityProfiles() async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/profile?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                var _entries = new Map<int, SonarrQualityProfile>();
                for(var entry in body) {
                    _entries[entry['id']] = SonarrQualityProfile(
                        entry['id'] ?? -1,
                        entry['name'] ?? 'Unknown Quality Profile',
                    );
                }
                return _entries;
            } else {
                logError('getQualityProfiles', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getQualityProfiles', 'Failed to fetch quality profiles', e);
            return null;
        }
        logWarning('getQualityProfiles', 'Failed to fetch quality profiles');
        return null;
    }

    static Future<List<SonarrReleaseEntry>> getReleases(int episodeId) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return null;
        }
        try {
            String uri = '${values[1]}/api/release?apikey=${values[2]}&episodeId=$episodeId';
            http.Response response = await http.get(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                List body = json.decode(response.body);
                List<SonarrReleaseEntry> _entries = [];
                for(var entry in body) {
                    _entries.add(SonarrReleaseEntry(
                        entry['title'] ?? 'Unknown Release Title',
                        entry['guid'] ?? '',
                        entry['quality']['quality']['name'] ?? 'Unknown',
                        entry['protocol'] ?? 'Unknown Protocol',
                        entry['indexer'] ?? 'Unknown Indexer',
                        entry['infoUrl'] ?? '',
                        entry['approved'] ?? false,
                        entry['releaseWeight'] ?? 0,
                        entry['size'] ?? 0,
                        entry['indexerId'] ?? 0,
                        entry['ageHours'] ?? 0,
                        entry['rejections'] ?? [],
                        entry['seeders'] ?? 0,
                        entry['leechers'] ?? 0,
                    ));
                }
                return _entries;
            } else {
                logError('getReleases', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('getReleases', 'Failed to fetch releases ($episodeId)', e);
            return null;
        }
        logWarning('getReleases', 'Failed to fetch releases ($episodeId)');
        return null;
    }

    static Future<bool> downloadRelease(String guid, int indexerId) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uri = '${values[1]}/api/release?apikey=${values[2]}';
            http.Response response = await http.post(
                Uri.encodeFull(uri),
                headers: {
                    'Content-Type': 'application/json',
                },
                body: json.encode({
                    'guid': guid,
                    'indexerId': indexerId,
                })
            );
            if(response.statusCode == 200) {
                return true;
            } else {
                logError('downloadRelease', '<POST> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('downloadRelease', 'Failed to download release ($guid)', e);
            return false;
        }
        logWarning('downloadRelease', 'Failed to download release ($guid)');
        return false;
    }

    static Future<bool> toggleEpisodeMonitored(int episodeID, bool status) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uriGet = '${values[1]}/api/episode/$episodeID?apikey=${values[2]}';
            String uriPut = '${values[1]}/api/episode?apikey=${values[2]}';
            http.Response response = await http.get(
                Uri.encodeFull(uriGet),
            );
            if(response.statusCode == 200) {
                Map body = json.decode(response.body);
                body['monitored'] = status;
                response = await http.put(
                    Uri.encodeFull(uriPut),
                    body: json.encode(body),
                    headers: {
                        "Content-Type": "application/json",
                    },
                );
                if(response.statusCode == 202) {
                    return true;
                } else {
                    logError('toggleSeasonMonitored', '<PUT> HTTP Status Code (${response.statusCode})', null);
                }
            } else {
                logError('toggleSeasonMonitored', '<GET> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('toggleEpisodeMonitored', 'Failed to toggle episode monitored state ($episodeID, $status)', e);
            return false;
        }
        logWarning('toggleEpisodeMonitored', 'Failed to toggle episode monitored state ($episodeID, $status)');
        return false;
    }

    static Future<bool> deleteEpisodeFile(int episodeFileID) async {
        List<dynamic> values = Values.sonarrValues;
        if(values[0] == false) {
            return false;
        }
        try {
            String uri = '${values[1]}/api/episodefile/$episodeFileID?apikey=${values[2]}';
            http.Response response = await http.delete(
                Uri.encodeFull(uri),
            );
            if(response.statusCode == 200) {
                return true;
            } else {
                logError('deleteEpisodeFile', '<DELETE> HTTP Status Code (${response.statusCode})', null);
            }
        } catch (e) {
            logError('deleteEpisodeFile', 'Failed to delete episode file ($episodeFileID)', e);
            return false;
        }
        logWarning('deleteEpisodeFile', 'Failed to delete episode file ($episodeFileID)');
        return false;
    }
}
