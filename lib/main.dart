import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
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

PermissionHandler permissionHandler = PermissionHandler();

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
    final PermissionStatus locationPersmissionStatus =
        await permissionHandler.checkPermissionStatus(PermissionGroup.location);
    print('location permission status: $locationPersmissionStatus');
    if (locationPersmissionStatus == PermissionStatus.denied ||
        locationPersmissionStatus == PermissionStatus.disabled ||
        locationPersmissionStatus == PermissionStatus.restricted) {
      // TODO: Prompt user to open settings and update the denied/disabled/restricted permission
      // https://pub.dev/packages/permission_handler#open-app-settings
      // bool isOpened = await PermissionHandler().openAppSettings();
    } else if (locationPersmissionStatus == PermissionStatus.unknown) {
      var permissions = await permissionHandler
          .requestPermissions([PermissionGroup.location]);
      if (permissions.containsKey(PermissionGroup.location)) {
        setState(() {
          _myLocationEnabled = true;
        });
      }
    } else {
      setState(() {
        _myLocationEnabled = true;
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
    String assetName;

    print("Foo $bikes");
    if (bikes < 0) {
      assetName = "assets/ic_no_bikes.png";
    } else {
      switch (bikes) {
        case 0:
          assetName = "assets/ic_no_bikes.png";
          break;
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
        case 10:
          assetName = "assets/ic_${bikes.abs()}_bikes.png";
          break;
        default:
          assetName = "assets/ic_many_bikes.png";
          break;
      }
    }

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
