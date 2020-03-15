import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:copularr/routes/sonarr/subpages/details/show.dart';
import 'package:copularr/system.dart';
import 'package:copularr/core.dart';
import 'package:copularr/logic/abstracts.dart';

class CalendarSonarrEntry extends CalendarEntry {
    String episodeTitle;
    int seasonNumber;
    int episodeNumber;
    int seriesID;
    String airTime;
    bool hasFile;
    String fileQualityProfile;

    CalendarSonarrEntry({
        @required int id,
        @required String title,
        @required this.episodeTitle,
        @required this.seasonNumber,
        @required this.episodeNumber,
        @required this.seriesID,
        @required this.airTime,
        @required this.hasFile,
        @required this.fileQualityProfile,
    }) : super(id, title);

    @override
    TextSpan get subtitle => TextSpan(
        style: TextStyle(
            color: Colors.white70,
            fontSize: 14.0,
        ),
        children: <TextSpan>[
            TextSpan(
                text: 'Season $seasonNumber Episode $episodeNumber: ',
            ),
            TextSpan(
                text: episodeTitle,
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                ),
            ),
            if(!hasFile) TextSpan(
                text: '\nNot Downloaded',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                ),
            ),
            if(hasFile) TextSpan(
                text: '\nDownloaded ($fileQualityProfile)',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(Constants.ACCENT_COLOR),
                ),
            )
        ],
    );

    @override
    String get bannerURI {
        List values = Values.sonarrValues;
        return '${values[1]}/api/mediacover/$seriesID/banner-70.jpg?apikey=${values[2]}';
    }

    @override
    Future<void> enterContent(BuildContext context) async {
        await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => SonarrShowDetails(entry: null, seriesID: seriesID),
            ),
        );
    }

    @override
    IconButton get trailing => IconButton(
        icon: Text(
            airTimeString,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10.0,
            ),
        ),
        onPressed: null,
    );

    DateTime get airTimeObject {
        return DateTime.tryParse(airTime)?.toLocal();
    }

    String get airTimeString {
        if(airTimeObject != null) {
            return DateFormat('KK:mm\na').format(airTimeObject);
        }
        return 'N/A';
    }
}