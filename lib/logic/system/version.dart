import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:copularr/core.dart';

class System {
    System._();

    static Future<List> getChangelog() async {
        try {
            http.Response response = await http.get(
                Uri.encodeFull('https://www.copularr.app/changelog.json'),
            );
            if(response.statusCode == 200) {
                return json.decode(response.body);
            }
        } catch (e) {}
        return Constants.EMPTY_CHANGELOG;
    }
}