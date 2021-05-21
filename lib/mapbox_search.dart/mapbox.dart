import 'dart:convert';

import 'package:address_field/addres_model.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:http/http.dart' as http;

class Location {
  double lat;
  double lng;

  Location({required this.lat, required this.lng});
}

mixin AddressSearch {
  Future<List<Address>> search(String text);
}

class MapBoxSearch implements AddressSearch {
  MapBoxSearch({required this.apiKey, this.language, this.limit, this.country});

  @override
  Future<List<Address>> search(String text) async {
    final places = await getPlaces(text);

    String findInContext(MapBoxPlace place, String key) {
      final contexts = place.context.where((element) => element.id.contains(key));
      return contexts.isEmpty ? '' : contexts.first.text;
    }

    return [
      for (final place in places)
        Address(
          text: place.placeName,
          line1: place.text + ' ' + (place.addressNumber ?? ''),
          line2: '',
          city: findInContext(place, 'place'),
          country: findInContext(place, 'country'),
          state: findInContext(place, 'region'),
          postalCode: findInContext(place, 'postcode'),
        ),
    ];
  }

  /// API Key of the MapBox.
  final String apiKey;

  /// Specify the user’s language. This parameter controls the language of the text supplied in responses.
  ///
  /// Check the full list of [supported languages](https://docs.mapbox.com/api/search/#language-coverage) for the MapBox API
  final String? language;

  ///Limit results to one or more countries. Permitted values are ISO 3166 alpha 2 country codes separated by commas.
  ///
  /// Check the full list of [supported countries](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) for the MapBox API
  final String? country;

  /// Specify the maximum number of results to return. The default is 5 and the maximum supported is 10.
  final int? limit;

  final String _url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/';

  String _createUrl(String queryText, [Location? location]) {
    String finalUrl = '$_url${Uri.encodeFull(queryText)}.json?';
    finalUrl += 'access_token=$apiKey';

    finalUrl += "&types=address&autocomplete=true";

    if (location != null) {
      finalUrl += '&proximity=${location.lng}%2C${location.lat}';
    }

    if (country != null) {
      finalUrl += "&country=$country";
    }

    if (limit != null) {
      finalUrl += "&limit=$limit";
    }

    if (language != null) {
      finalUrl += "&language=$language";
    }

    return finalUrl;
  }

  Future<List<MapBoxPlace>> getPlaces(String queryText) async {
    String url = _createUrl(queryText);
    final response = await http.get(Uri.parse(url));

    if (response.body.contains('message')) {
      throw Exception(json.decode(response.body)['message']);
    }
    return Predictions.fromRawJson(response.body).features;
  }
}


