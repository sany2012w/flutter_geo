import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoder/geocoder.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MyStatefulWidget(),
      //MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(59.844001699271985, 30.329139456152916),
    zoom: 14.4746,
  );

  static final CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  int markerIdVal = 0;
  var appBarText = 'Setting points';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          markers: Set<Marker>.of(markers.values),
          onTap: (LatLng) {
            markerIdVal = (markerIdVal + 1) % 2;
            final MarkerId markerId = MarkerId(markerIdVal.toString());

            setState(() {
              // adding a new marker to map
              markers[markerId] = Marker(
                  markerId: markerId,
                  position: LatLng,
                  icon: BitmapDescriptor.defaultMarker);
            });
          },
        ),
      ),
      appBar: AppBar(title: Text(appBarText)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInfo,
        label: Text('Show'),
        icon: Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<void> _showInfo() async {

    List<LatLng> allPoints = new List();

    double latDiff = markers[MarkerId("0")].position.latitude - markers[MarkerId("1")].position.latitude;
    double longDiff = markers[MarkerId("0")].position.longitude - markers[MarkerId("1")].position.longitude;

    print(sqrt(latDiff*latDiff + longDiff*longDiff).toString());

    int countPoints = sqrt(latDiff*latDiff*4 + longDiff*longDiff*4).toInt();
    if (countPoints == 0) {
      countPoints ++;
    }
    print(countPoints);

    latDiff = latDiff / countPoints;
    longDiff = longDiff / countPoints;
    var counterAll = 0,
        pollen = 0;

    LatLng newPoint = markers[MarkerId("1")].position;
    for (var counter = 0; counter <=countPoints; counter++) {
      // отправляем запросы в каждой точке
      var position = LatLng(newPoint.latitude + latDiff * counter,
          newPoint.longitude + longDiff * counter);
      print(position.longitude.toString() + " " + position.latitude.toString());
      var url = 'https://api.breezometer.com/pollen/v2/forecast/daily?lat=' +
          position.latitude.toString() +
          '&lon=' + position.longitude.toString() +
          '&days=1&key=xxxxxxxxxxxxxxx&features=types_information,plants_information';
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var type = data['data'][0]['types'];
        var plant = data['data'][0]['plants'];

        for (var types in type.entries) {
          if (types.value['in_season'] == true) {
            pollen++;
          }
          counterAll++;
        }

        for (var plants in plant.entries) {
          if (plants.value['in_season'] == true) {
            pollen++;
          }
          counterAll++;
        }

        print(pollen.toString() + " " + counterAll.toString());
      }
    }

    setState(() {
      if (counterAll == 0) {
        appBarText = 'Sorry, service now not allowed';
      } else {
        var pollenStatus = pollen * 10 / counterAll;
        var newPollen = pollenStatus.toInt();
        appBarText = 'Pollen: ' + newPollen.toString();
      }
    });
      //allPoints.add(LatLng(newPoint.latitude + latDiff*counter, newPoint.longitude + longDiff*counter));

//      final MarkerId markerId = MarkerId(counter.toString());
//      markers[markerId] = Marker(
//          markerId: markerId,
//          position: allPoints[counter],
//          icon: BitmapDescriptor.defaultMarker,
//      );


//    setState(() {
//      appBarText = 'test';
//    });

//    pollen(markers[MarkerId("0")].position).then((point) {
//      if (point[0] != 200){
//        setState(() {
//          appBarText = 'Sorry, service now not allowed';
//        });
//      } else {
//
//        var pollenStasus = point[1] * 10 / point[2];
//
//        setState(() {
//          appBarText = 'Pollen: ' + pollenStasus.toString();
//        });
//      }
//    });

  }

  Widget searchAndNavigate() {
    print('searchAndNavigate');
  }
}

Future<List<int>> pollen(LatLng position) async {

  print(position.longitude.toString() + " " + position.latitude.toString());
  var url = 'https://api.breezometer.com/pollen/v2/forecast/daily?lat=' + position.latitude.toString() +
      '&lon=' + position.longitude.toString() + '&days=1&key=xxxxxxxxxxxxxxx&features=types_information,plants_information';
  var response = await http.get(url);

  List<int> answer = new List();
  answer.add(response.statusCode);

  var counter = 0,
      poland = 0;

  if (response.statusCode == 200) {

    var data = json.decode(response.body);
    var type = data['data'][0]['types'];
    var plant = data['data'][0]['plants'];

    for (var types in type.entries) {
      if (types.value['in_season'] == true) {
        poland++;
      }
      counter++;
    }

    for (var plants in plant.entries) {
      if (plants.value['in_season'] == true) {
        poland++;
      }
      counter++;
    }

    answer.add(poland);
    answer.add(counter);
  }

  return answer;
}

class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My app'),
      ),
      body: myBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            title: Text('Search'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            title: Text('Map'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget myBody() {
    if (_selectedIndex == 0) {
      return mapHome();
    } else if (_selectedIndex == 1) {
      return mapSearch();
    } else if (_selectedIndex == 2) {
      return MapSample();
    }
  }
}

class mapSearch extends StatefulWidget {
  @override
  mapSearchState createState() => new mapSearchState();
}

class mapSearchState extends State<mapSearch> {

  var firstAdr = "";
  var secondAdr = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: <Widget>[
        TextField(
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
              hintText: "Ваш адрес",
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: searchMyAdress,
                iconSize: 30.0,
              )),
          onChanged: (firstText) {
            firstAdr = firstText;
          },
        ),
        TextField(
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
              hintText: "Адрес прибытия",
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: searchArrivedAdress,
                iconSize: 30.0,
              )),
          onChanged: (secondText) {
            secondAdr = secondText;
          },
        ),
      ],
    ));
  }

  void searchMyAdress() async{
    print('searchMyAdress');
    var addresses = await Geocoder.local.findAddressesFromQuery(firstAdr);
    var first = addresses.first;
    print("${first.featureName} : ${first.coordinates}");

  }

  void searchArrivedAdress() async{
    print('searchArrivedAdr');

    var addresses = await Geocoder.local.findAddressesFromQuery(secondAdr);
    var first = addresses.first;
    print("${first.featureName} : ${first.coordinates}");
  }
}

class mapHome extends StatefulWidget {
  @override
  mapHomeState createState() => new mapHomeState();
}

class mapHomeState extends State<mapHome> {
  List<Widget> _weather = [];

  int statusRequest = 0;
  var cityName = 'Saint Petersburg';

  @override
  Widget build(BuildContext context) {
    if (statusRequest == 1) {
      return Scaffold(
        body: Column(
          children: <Widget>[
            TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                  hintText: "Вы находитесь в " + cityName,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _showInfo,
                    iconSize: 30.0,
                  )),
              onChanged: (text) {
                cityName = text;
              },
            ),
            Container(
              padding: EdgeInsets.only(bottom: 40),
            ),
            _weather[0],
            _weather[1],
            _weather[2],
            _weather[3],
            _weather[4],
          ],
        ),
      );
    } else {
      _showInfo();
      return Scaffold(
        body: Column(
          children: <Widget>[
            TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                  hintText: "Вы находитесь в " + cityName,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: searchMyAdress,
                    iconSize: 30.0,
                  )),
            ),
          ],
        ),
//      floatingActionButton: FloatingActionButton.extended(
//        onPressed: _showInfo,
//        label: Text('Show'),
//        icon: Icon(Icons.directions_boat),
//      ),
      );
    }
  }

  void _showInfo() async {
    var url = "https://api.openweathermap.org/data/2.5/weather" +
        "?q=" +
        cityName +
        "&appid=хххххххххххххххххххх" +
        "&units=metric" +
        "&lang=en";

    var response = await http.get(url);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    var data = json.decode(response.body);

    print("Weather in " + data['name'].toString() + " is ");
    print(data['main']['humidity'].toString());
    print("Temperature: " + data['main']['temp'].toString());
    print("It feels like: " + data['main']['feels_like'].toString());
    print("Wind speed: " + data['wind']['speed'].toString());
    print("Visibility: " + data['visibility'].toString());

    setState(() {
      statusRequest = 1;
      _weather.clear();

      _weather.add(
          Container(
            padding: const EdgeInsets.only(bottom: 30),
            child: Text("Weather in " + data['name'].toString() + " is ",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
          )
      );

      _weather.add(
          Container(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text("Temperature: " + data['main']['temp'].toString(),
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
          )
      );

      _weather.add(
          Container(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text("It feels like: " + data['main']['feels_like'].toString(),
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
          )
      );

      _weather.add(
          Container(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text("Wind speed: " + data['wind']['speed'].toString() + " m/sec",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
          )
      );


//      _weather.add(Text("Temperature: " + data['main']['temp'].toString()));
//      _weather.add(Text("It feels like: " + data['main']['feels_like'].toString()));
//      _weather.add(Text("Wind speed: " + data['wind']['speed'].toString() + " m/sec"));
//      _weather.add(Text("Visibility: " + data['visibility'].toString() + "m"));

    });

//      city: "Weather in " + response.name + " is ",
//      main: response.weather[0].description,
//      Temperature: "Temperature: " + response.main.temp,
//      Pressure: "Pressure: " + response.main.pressure,
//      Windspeed: "Wind speed: " + response.wind.speed,
//      Humidity: "Humidity: " + response.main.humidity,
//      Clouds: "Clouds: " + response.clouds.all,
//      Visibility: "Visibility: " + response.visibility;
  }

  Widget searchMyAdress() {
    print(cityName);
  }

  Widget searchArrivedAdress() {
    print('searchArrivedAdr');
  }
}
