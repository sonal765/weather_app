import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(const WeatherApp());

class WeatherApp extends StatefulWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int? temperature;
  String location = 'Kolkata'; // initial location
  int woeid = 2487956; //where on earth id

  String weather = 'clear';
  String abbreviation = '';
  String errorMessage = '';

  List<int> minTemperatureForecast = List.filled(7, 0);
  List<int> maxTemperatureForecast = List.filled(7, 0);
  List<String> abbreviationForecast = List.filled(7, '');

  @override
  initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  fetchSearch(String input) async {
    try {
      final searchUrl = Uri.parse(
          'https://www.metaweather.com/api/location/search/?query=$input');

      var searchResult = await http.get(searchUrl);
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
        errorMessage =
            "Sorry, we don't have data about this city. Try another one.";
      });
    }
  }

  fetchLocation() async {
    final locationUrl = Uri.parse(
        'https://www.metaweather.com/api/location/${woeid.toString()}');

    var locationResult = await http.get(locationUrl);
    var result = json.decode(locationResult.body);
    var consolidatedweather = result["consolidated_weather"];
    var data = consolidatedweather[0];

    setState(() {
      temperature = data["the_temp"].round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbreviation = data["weather_state_abbr"];
    });
  }

  fetchLocationDay() async {
    var today = DateTime.now();
    final DateFormat formatter = DateFormat('y/M/d');
    for (var i = 0; i < 7; i++) {
      final locationUrl = Uri.parse(
          'https://www.metaweather.com/api/location/${woeid.toString()}/${formatter.format(today.add(Duration(days: i + 1))).toString()}');

      var locationDayResult = await http.get(locationUrl);
      var result = json.decode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data["min_temp"].round();
        maxTemperatureForecast[i] = data["max_temp"].round();
        abbreviationForecast[i] = data["weather_state_abbr"];
      });
    }
  }

  onTextFieldSubmitted(String input) async {
    // function invoke when input is provided
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/$weather.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode( // more focus on text rather than background
              Colors.black.withOpacity(0.6),
              BlendMode.dstATop,
            ), 
          ),
        ),
        child: temperature == null
            ? const Center(
                child:
                    CircularProgressIndicator(),) //initially showing loading indicator while opening for the first time
            : Scaffold(
                appBar: AppBar(
                  title: const Text('WEATHER  FORECAST'),
                  backgroundColor: Colors.transparent, //transparent appbar
                  elevation: 0.0,
                ),
                resizeToAvoidBottomInset:
                    false, // to avoid overlapping the keyboard
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          width: 300,
                          child: TextField(
                            onSubmitted: (String input) =>
                              onTextFieldSubmitted(input),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 28),
                            decoration: const InputDecoration(
                              hintText: 'Search another location...',
                              hintStyle: TextStyle(
                                  color: Colors.white, fontSize: 20.0),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0, left: 32.0),
                      child: Text(errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: Platform.isAndroid ? 15.0 : 20.0)),
                    ),
                    Column(
                      children: <Widget>[
                        Center(
                          child: Image.network(
                            'https://www.metaweather.com/static/img/weather/png/' +
                                abbreviation +
                                '.png',
                            width: 100,
                          ),
                        ),
                        Center(
                          child: Text(
                            temperature.toString() + ' °C',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 50.0),
                          ),
                        ),
                        Center(
                          child: Text(
                            location,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 30.0),
                          ),
                        ),
                      ],
                    ),
                    SingleChildScrollView( 
                      // to scroll the row showing different days of week
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          for (var i = 0; i < 7; i++)
                            forecastElement(
                                i + 1,
                                abbreviationForecast[i],
                                minTemperatureForecast[i],
                                maxTemperatureForecast[i]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
 
// widget to display weather forecast of 7 days of weeks
Widget forecastElement(
    daysFromNow, abbreviation, minTemperature, maxTemperature) {
  var now = DateTime.now();
  var oneDayFromNow = now.add(Duration(days: daysFromNow));
  return Padding(
    padding: const EdgeInsets.only(left: 16.0),
    child: Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              DateFormat.E().format(oneDayFromNow),
              style: const TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              DateFormat.MMMd().format(oneDayFromNow),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/' +
                    abbreviation +
                    '.png',
                width: 50,
              ),
            ),
            Text(
              'High: ' + maxTemperature.toString() + ' °C',
              style: const TextStyle(color: Colors.white, fontSize: 20.0),
            ),
            Text(
              'Low: ' + minTemperature.toString() + ' °C',
              style: const TextStyle(color: Colors.white, fontSize: 20.0),
            ),
          ],
        ),
      ),
    ),
  );
}
