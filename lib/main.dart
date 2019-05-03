import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Set up transparent status bar with dark icons
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Fillarit Demo',
      theme: ThemeData(
        primaryColor: Color(0xFFFCBC19),
        accentColor: Color(0xFFFCBC19),
      ),
      home: FillaritHomePage(),
    );
  }
}

class FillaritHomePage extends StatefulWidget {
  @override
  State<FillaritHomePage> createState() => FillaritHomePageState();
}

class FillaritHomePageState extends State<FillaritHomePage> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set();
  bool _myLocationEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blue,
        child: GoogleMap(
          myLocationButtonEnabled: _myLocationEnabled,
          myLocationEnabled: _myLocationEnabled,
          cameraTargetBounds: CameraTargetBounds(
            LatLngBounds(
              northeast: LatLng(60.350423, 25.099244),
              southwest: LatLng(60.054357, 24.441989),
            ),
          ),
          minMaxZoomPreference: MinMaxZoomPreference(13, 18),
          initialCameraPosition: CameraPosition(
            zoom: 15,
            target: LatLng(60.1699, 24.9384),
          ),
          onMapCreated: (controller) {
            _controller.complete(controller);
            _loadMarkers();
            _requestPermissions();
          },
          markers: _markers,
        ),
      ),
    );
  }

  Future _requestPermissions() async {
    final Map<PermissionGroup, PermissionStatus> permissions =
        await PermissionHandler()
            .requestPermissions([PermissionGroup.location]);
    print(permissions);
    if (permissions.containsKey(PermissionGroup.location)) {
      setState(() {
        _myLocationEnabled =
            permissions[PermissionGroup.location] == PermissionStatus.granted;
      });
    }
  }

  Future _loadMarkers() async {
    final stations = await _fetchStations();
    final markerFutures = stations.map((station) async {
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.x, station.y),
        icon: await _getMarkerIcon(station.bikesAvailable),
      );
    });
    final markers = await Future.wait(markerFutures);
    print("Markers: ${markers.length}");
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  Future<BitmapDescriptor> _getMarkerIcon(int bikes) {
    // TODO show number of available bikes
    final assetName =
        bikes > 0 ? "assets/ic_some_bikes.png" : "assets/ic_no_bikes.png";
    return BitmapDescriptor.fromAssetImage(ImageConfiguration(), assetName);
  }

  Future<List<Station>> _fetchStations() async {
    final response = await http
        .get("https://api.digitransit.fi/routing/v1/routers/hsl/bike_rental");

    if (response.statusCode != 200) return List<Station>();

    final parsedJson = json.decode(response.body);
    return (parsedJson['stations'] as List)
        .map((stationJson) => Station.fromJson(stationJson))
        .toList();
  }
}

class Station {
  final int bikesAvailable;
  final int spacesAvailable;

  final String id;
  final String name;

  final double x;
  final double y;

  Station({
    @required this.bikesAvailable,
    @required this.spacesAvailable,
    @required this.id,
    @required this.name,
    @required this.x,
    @required this.y,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        bikesAvailable: json['bikesAvailable'],
        spacesAvailable: json['spacesAvailable'],
        id: json['id'],
        name: json['name'],
        x: json['y'],
        y: json['x'],
      );

  @override
  String toString() => "Station{$id $name $x, $y}";
}
