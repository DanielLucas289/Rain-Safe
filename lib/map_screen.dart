// ARQUIVO: lib/screens/map_screen.dart (VERSÃO CORRIGIDA E COMPLETA)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
// As importações corrigidas estão aqui:
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

import 'places_autocomplete_field.dart';
import '../database/rota_database.dart';
import '../models/rota_model.dart';

const String googleApiKey = "AIzaSyBTjnWuXP5xLrcqJ5JxgwVlHMqKM8T2p7o";
const String openWeatherApiKey = "1d4b1e2dd58fffd123300d0d756fd7c1";

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<RotaModel> savedTrips = [];
  late GoogleMapController mapController;
  final LatLng _initialPosition = const LatLng(37.7749, -122.4194);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  List<WeatherInfo> _weatherForecasts = [];

  Future<void> getWeatherForRoute(List<LatLng> routePoints) async {

    if (routePoints.isEmpty) {
      print("⚠️ Route empty.");
      return;
    }
    if (routePoints.length < 2) {
      print("⚠️ Route too short to check weather.");
      return;
    }

    List<WeatherInfo> forecasts = [];
    List<LatLng> pointsToCheck = [];

    for (int i = 0; i < routePoints.length; i += 80) {

      pointsToCheck.add(routePoints[i]);
    }

    // Ensure the last point is always included
    if (!pointsToCheck.contains(routePoints.last)) {
      pointsToCheck.add(routePoints.last);
    }

    for (var point in pointsToCheck) {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${point.latitude}&lon=${point.longitude}&appid=$openWeatherApiKey&units=metric&lang=pt_br',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("✅ Weather data received: ${data['name']}");

          forecasts.add(
            WeatherInfo(
              cityName: data['name'],
              description: data['weather'][0]['description'],
              temperature: data['main']['temp'].toDouble(),
              iconCode: data['weather'][0]['icon'],
            ),
          );
        } else {
          print("❌ Weather API error ${response.statusCode}: ${response.body}");
        }
      } catch (e) {
        print("Erro ao buscar previsão do tempo: $e");
      }
    }

    final Map<String, WeatherInfo> uniqueCityForecasts = {
      for (var forecast in forecasts) forecast.cityName: forecast
    };

    setState(() {
      _weatherForecasts = uniqueCityForecasts.values.toList();
    });
  }

  LatLng? originLatLng;
  LatLng? destinationLatLng;

  final places.GoogleMapsPlaces _places = places.GoogleMapsPlaces(
    apiKey: googleApiKey,
  );

  Future<void> _loadTripsFromDatabase() async {
    final trips = await RouteDatabase.instance.readAllRoutes();
    setState(() {
      savedTrips = trips;
    });
  }

  Future<void> _drawRoute() async {
    if (originLatLng == null || destinationLatLng == null) return;

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(originLatLng!.latitude, originLatLng!.longitude),
      PointLatLng(destinationLatLng!.latitude, destinationLatLng!.longitude),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoords =
          result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

      await getWeatherForRoute(polylineCoords);

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            width: 5,
            points: polylineCoords,
          ),
        );
      });
    } else {
      print(
        "⚠️ Polyline API returned empty route. Status: ${result.status}, Error: ${result.errorMessage}",
      );
      return;
    }
  }

  Future<void> _handleTripLoad(RotaModel trip) async {
    final originLoc = await geo.locationFromAddress(trip.partida);
    final destLoc = await geo.locationFromAddress(trip.destino);

    if (originLoc.isEmpty || destLoc.isEmpty) {
      print("⚠️ Geocoding failed for: ${trip.partida} or ${trip.destino}");
      return;
    }

    originLatLng = LatLng(originLoc[0].latitude, originLoc[0].longitude);
    destinationLatLng = LatLng(destLoc[0].latitude, destLoc[0].longitude);

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: originLatLng!,
          infoWindow: const InfoWindow(title: 'Origin'),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationLatLng!,
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    });

    await _drawRoute(); // This might silently fail
    mapController.animateCamera(CameraUpdate.newLatLngZoom(originLatLng!, 12));
  }

  void _showTripMenu(BuildContext context) async {
    await _loadTripsFromDatabase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Suas viagens",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Salvar viagem atual"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final origin = _originController.text.trim();
                  final destination = _destinationController.text.trim();

                  if (origin.isEmpty || destination.isEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Partida ou destino não pode estar vazio.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (context) {
                      final TextEditingController nameController =
                          TextEditingController();

                      return AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text(
                          'Salvar viagem',
                          style: TextStyle(color: Colors.lightBlueAccent),
                        ),
                        content: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da viagem',
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.lightBlueAccent),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: const Text(
                              'Salvar',
                              style: TextStyle(color: Colors.amberAccent),
                            ),
                            onPressed: () async {
                              final nomeViagem = nameController.text.trim();
                              if (nomeViagem.isEmpty) return;

                              await RouteDatabase.instance.create(
                                RotaModel(
                                  name: nomeViagem,
                                  partida: origin,
                                  destino: destination,
                                ),
                              );

                              Navigator.pop(context);
                              Navigator.pop(context);
                              await _loadTripsFromDatabase();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Viagem salva com sucesso!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              if (savedTrips.isEmpty)
                const Text("Nenhuma viagem salva.")
              else
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    itemCount: savedTrips.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final trip = savedTrips[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${trip.partida} ➔ ${trip.destino}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      _originController.text = trip.partida;
                                      _destinationController.text =
                                          trip.destino;
                                      Navigator.pop(context);
                                      await _handleTripLoad(trip);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.lightBlueAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Carregar"),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await RouteDatabase.instance.delete(
                                        trip.id!,
                                      );
                                      Navigator.pop(context);
                                      _showTripMenu(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amberAccent,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text("Excluir"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) => mapController = controller,
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              child: Column(
                children: [
                  PlacesAutocompleteField(
                    apiKey: googleApiKey,
                    label: "Partida",
                    controller: _originController,
                    onPlaceSelected: (description, lat, lng) {
                      _originController.text = description;
                      setState(() {
                        originLatLng = LatLng(lat, lng);
                        _markers.add(
                          Marker(
                            markerId: const MarkerId('origin'),
                            position: originLatLng!,
                            infoWindow: const InfoWindow(title: 'Partida'),
                          ),
                        );
                      });
                      if (originLatLng != null && destinationLatLng != null) {
                        _drawRoute();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  PlacesAutocompleteField(
                    apiKey: googleApiKey,
                    label: "Destino",
                    controller: _destinationController,
                    onPlaceSelected: (description, lat, lng) {
                      _destinationController.text = description;
                      setState(() {
                        destinationLatLng = LatLng(lat, lng);
                        _markers.add(
                          Marker(
                            markerId: const MarkerId('destination'),
                            position: destinationLatLng!,
                            infoWindow: const InfoWindow(title: 'Destino'),
                          ),
                        );
                      });
                      if (originLatLng != null && destinationLatLng != null) {
                        _drawRoute();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Previsão de Chuva por Cidade",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _weatherForecasts.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          "Nenhuma previsão disponível para esta rota.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _weatherForecasts.length,
                        itemBuilder: (context, index) {
                          final forecast = _weatherForecasts[index];
                          return Card(
                            child: ListTile(
                              leading: Image.network(
                                'https://openweathermap.org/img/wn/${forecast.iconCode}@2x.png',
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.cloud_off, size: 40),
                              ),
                              title: Text(forecast.cityName),
                              subtitle: Text(
                                "${forecast.description}, ${forecast.temperature.toStringAsFixed(1)}°C",
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amberAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.list_alt),
        label: const Text("Viagens"),
        onPressed: () => _showTripMenu(context),
      ),
    );
  }
}

class WeatherInfo {
  final String cityName;
  final String description;
  final double temperature;
  final String iconCode;

  WeatherInfo({
    required this.cityName,
    required this.description,
    required this.temperature,
    required this.iconCode,
  });
}
