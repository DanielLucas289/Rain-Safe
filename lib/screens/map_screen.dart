import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';  // Add this import
import 'package:http/http.dart' as http;  // Add this import
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart';
import 'places_autocomplete_field.dart';
import '../database/rota_database.dart';
import '../models/rota_model.dart';
import '../widgets/weather_widgets.dart';



const String googleApiKey = "AIzaSyBTjnWuXP5xLrcqJ5JxgwVlHMqKM8T2p7o";
const String openWeatherApiKey = "1d4b1e2dd58fffd123300d0d756fd7c1";

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map controllers and data
  late GoogleMapController mapController;
  final LatLng _initialPosition = const LatLng(37.7749, -122.4194);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<RotaModel> savedTrips = [];
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  LatLng? originLatLng;
  LatLng? destinationLatLng;

  // Weather data
  List<WeatherInfo> _weatherForecasts = [];
  bool _isLoadingWeather = false;
  final _weatherCache = <String, List<Weather>>{};
  DateTime? _routeStartTime;

  // Weather factory initialization
  late final WeatherFactory _weatherFactory;

  @override
  void initState() {
    super.initState();
    _weatherFactory = WeatherFactory(openWeatherApiKey);
  }

  Future<void> _loadTripsFromDatabase() async {
    final trips = await RouteDatabase.instance.readAllRoutes();
    setState(() {
      savedTrips = trips;
    });
  }

  Future<Duration> _getTravelDuration({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'key=$googleApiKey',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final durationInSeconds = data['routes'][0]['legs'][0]['duration']['value'];
        return Duration(seconds: durationInSeconds);
      }
    } catch (e) {
      debugPrint("Error getting travel duration: $e");
    }

    return Duration.zero; // Fallback value
  }

  Future<void> getWeatherForRoute(List<LatLng> routePoints) async {
    if (routePoints.isEmpty || routePoints.length < 2) return;

    List<WeatherInfo> forecasts = [];
    DateTime? estimatedDepartureTime = DateTime.now();
    final pointsToCheck = _getSampledRoutePoints(routePoints);

    for (int i = 0; i < pointsToCheck.length; i++) {
      final point = pointsToCheck[i];
      Duration? durationToPoint;

      if (i < pointsToCheck.length - 1) {
        durationToPoint = await _getTravelDuration(
          origin: point,
          destination: pointsToCheck[i + 1],
        );
      }

      try {
        Weather g;
        // First get weather data
        final weatherForecasts = await _weatherFactory.fiveDayForecastByLocation(
          point.latitude,
          point.longitude,
        );


        // Use weather API's location name as primary source
        String cityName = weatherForecasts.first.areaName ?? 'Local Desconhecido';
        double rain = weatherForecasts.first.rainLast3Hours ?? 0.0;
        print("PRECIPITATIONNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN $rain");

        DateTime? estimatedArrival;
        if (durationToPoint != null && estimatedDepartureTime != null) {
          estimatedArrival = estimatedDepartureTime.add(durationToPoint);
        }

        final matchingForecast = _findBestMatchingForecast(
          weatherForecasts,
          estimatedArrival ?? DateTime.now(),
        );

        if (matchingForecast != null) {
          forecasts.add(
              WeatherInfo.fromWeather(
                matchingForecast,
                cityName: cityName,
                travelTime: durationToPoint,
                arrivalTime: estimatedArrival,
              )
          );
        }

        estimatedDepartureTime = estimatedArrival;
      } catch (e) {
        debugPrint("Error processing point: $e");
      }
    }

    final Map<String, WeatherInfo> uniqueCityForecasts = {};
    for (var forecast in forecasts) {
      if (!uniqueCityForecasts.containsKey(forecast.cityName)) {
        uniqueCityForecasts[forecast.cityName] = forecast;
      }
    }
    setState(() {
      _weatherForecasts = uniqueCityForecasts.values.toList();
    });
  }

  List<LatLng> _getSampledRoutePoints(List<LatLng> routePoints) {
    final points = <LatLng>[];
    for (int i = 0; i < routePoints.length; i += 20) {
      points.add(routePoints[i]);
    }
    if (!points.contains(routePoints.last)) {
      points.add(routePoints.last);
    }
    return points;
  }

  Future<List<Weather>?> _getWeatherForecast(LatLng point) async {
    final cacheKey = '${point.latitude},${point.longitude}';

    try {
      if (_weatherCache.containsKey(cacheKey)) {
        return _weatherCache[cacheKey];
      }

      final forecasts = await _weatherFactory.fiveDayForecastByLocation(
        point.latitude,
        point.longitude,
      );

      _weatherCache[cacheKey] = forecasts;
      return forecasts;
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
      return null;
    }
  }

  Future<void> _loadAndDisplayTrip(RotaModel trip) async {
    // Clear previous data
    setState(() {
      _weatherForecasts.clear();
      _isLoadingWeather = true;
    });

    try {
      // 1. Get coordinates for start and end points
      final originLoc = await locationFromAddress(trip.partida);
      final destLoc = await locationFromAddress(trip.destino);

      if (originLoc.isEmpty || destLoc.isEmpty) {
        print("⚠️ Geocoding failed for: ${trip.partida} or ${trip.destino}");
        return;
      }

      // 2. Update state with new locations
      setState(() {
        originLatLng = LatLng(originLoc[0].latitude, originLoc[0].longitude);
        destinationLatLng = LatLng(destLoc[0].latitude, destLoc[0].longitude);

        // Update markers
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: originLatLng!,
            infoWindow: InfoWindow(title: trip.partida),
          ),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destinationLatLng!,
            infoWindow: InfoWindow(title: trip.destino),
          ),
        );
      });

      // 3. Draw route and get forecasts if both points exist
      if (originLatLng != null && destinationLatLng != null) {
        await _drawRouteWithForecast();
      }

      // 4. Center map on starting point
      if (mapController != null && originLatLng != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(originLatLng!, 12),
        );
      }

    } catch (e) {
      print("Error loading trip: $e");
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _drawRouteWithForecast() async {
    if (originLatLng == null || destinationLatLng == null) return;

    try {
      // Get route polyline
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey,
        PointLatLng(originLatLng!.latitude, originLatLng!.longitude),
        PointLatLng(destinationLatLng!.latitude, destinationLatLng!.longitude),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> routePoints = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Update polylines
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: routePoints,
            ),
          );
        });

        // Get weather forecasts along route
        await getWeatherForRoute(routePoints);
      }
    } catch (e) {
      print("Error drawing route: $e");
      rethrow;
    }
  }

  Future<Duration?> _getTravelDurationToNextPoint({
    required LatLng currentPoint,
    required LatLng? nextPoint,
    required DateTime? currentTime,
  }) async {
    if (nextPoint == null || currentTime == null) return null;

    try {
      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${currentPoint.latitude},${currentPoint.longitude}&'
            'destination=${nextPoint.latitude},${nextPoint.longitude}&'
            'departure_time=${currentTime.millisecondsSinceEpoch ~/ 1000}&'
            'key=$googleApiKey',
      ));

      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return Duration(seconds: data['routes'][0]['legs'][0]['duration']['value']);
      }
    } catch (e) {
      debugPrint('Error getting duration: $e');
    }
    return null;
  }

  Weather? _findBestMatchingForecast(List<Weather> forecasts, DateTime arrivalTime) {
    // Find first forecast after arrival time
    for (final forecast in forecasts) {
      if (forecast.date?.isAfter(arrivalTime) ?? false) {
        return forecast;
      }
    }
    // Fallback to closest forecast
    Weather? closest;
    Duration? smallestDiff;

    for (final forecast in forecasts) {
      if (forecast.date == null) continue;

      final diff = forecast.date!.difference(arrivalTime).abs();
      if (smallestDiff == null || diff < smallestDiff) {
        smallestDiff = diff;
        closest = forecast;
      }
    }

    return closest;
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
                                      await _loadAndDisplayTrip(trip);
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
                        _drawRouteWithForecast();
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
                        _drawRouteWithForecast();
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
                      // Determine precipitation text based on whether data is available
                      String precipitationText = '';
                      if (forecast.precipitation != null) {
                        precipitationText = 'Precipitação: ${forecast.precipitation!.toStringAsFixed(1)} mm';
                      } else {
                        precipitationText = 'Sem precipitação prevista'; // Or "Nenhuma precipitação"
                      }

                      return Card(
                        child: ListTile(
                          tileColor: Colors.yellow[800],
                          leading: Image.network(
                            'https://openweathermap.org/img/wn/${forecast.iconCode}@2x.png',
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.cloud_off, size: 40),
                          ),
                          title: Text(forecast.cityName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${forecast.description}, ${forecast.temperature.toStringAsFixed(1)}°C"),
                              Text(precipitationText), // Added precipitation
                              if (forecast.arrivalTime != null)
                                Text("Chegada: ${DateFormat.Hm().format(forecast.arrivalTime!)}"),
                              // Removed:
                              // if (forecast.travelTime != null)
                              //   Text("Duração: ${forecast.travelTime!.inHours}h ${forecast.travelTime!.inMinutes.remainder(60)}min"),
                            ],
                          ),
                        ),
                      );
                    },
                  )
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

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Previsão de Chuva por Cidade",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.lightBlueAccent,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: WeatherForecastList(forecasts: _weatherForecasts)),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Calculando previsão do tempo...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }


}

class WeatherInfo {
  final String cityName;
  final String description;
  final double temperature;
  final String iconCode;
  final DateTime? arrivalTime;
  final DateTime? forecastTime;
  final Duration? travelTime;
  final double precipitation;  // Non-nullable with default value
  final double? windSpeed;
  final double? humidity;

  WeatherInfo({
    required this.cityName,
    required this.description,
    required this.temperature,
    required this.iconCode,
    this.arrivalTime,
    this.forecastTime,
    this.travelTime,
    required this.precipitation,  // Now required
    this.windSpeed,
    this.humidity,
  });

  factory WeatherInfo.fromWeather(Weather weather, {
    required String cityName,
    Duration? travelTime,
    DateTime? arrivalTime,
  }) {
    return WeatherInfo(
      cityName: cityName,
      description: weather.weatherDescription ?? 'N/A',
      temperature: weather.temperature?.celsius ?? 0,
      iconCode: _mapWeatherConditionToIcon(weather.weatherConditionCode),
      arrivalTime: arrivalTime,
      forecastTime: weather.date,
      travelTime: travelTime,
      precipitation: weather.rainLast3Hours ?? 0.0, // Guaranteed non-null
      windSpeed: weather.windSpeed,
      humidity: weather.humidity,
    );
  }

  // In your _mapWeatherConditionToIcon function:
  static String _mapWeatherConditionToIcon(int? code) {
    const codes = {
      200: '11d', // Thunderstorm
      300: '09d', // Drizzle
      500: '10d', // Rain
      600: '13d', // Snow
      800: '01d', // Clear
      801: '02d', // Few clouds
      802: '03d', // Scattered clouds
      803: '04d', // Broken clouds
      804: '04d', // Overcast clouds
    };
    return codes[code ?? 800] ?? '01d';
  }
}