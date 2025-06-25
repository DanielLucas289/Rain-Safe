import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/map_screen.dart';  // make sure WeatherInfo is in a separate file or import properly

class WeatherForecastList extends StatelessWidget {
  final List<WeatherInfo> forecasts;

  const WeatherForecastList({super.key, required this.forecasts});

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          "Nenhuma previsão disponível para esta rota.",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: forecasts.length,
      itemBuilder: (context, index) {
        final forecast = forecasts[index];
        return WeatherForecastCard(forecast: forecast);
      },
    );
  }
}

class WeatherForecastCard extends StatelessWidget {
  final WeatherInfo forecast;

  const WeatherForecastCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/${forecast.iconCode}@2x.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (_, __, ___) => const Icon(Icons.cloud_off, size: 40),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.cityName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        forecast.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${forecast.temperature.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (forecast.arrivalTime != null && forecast.forecastTime != null)
              Column(
                children: [
                  const Divider(),
                  _forecastDetailRow(
                    context,
                    label: 'Chegada prevista:',
                    value: DateFormat.Hm().format(forecast.arrivalTime!),
                  ),
                  _forecastDetailRow(
                    context,
                    label: 'Previsão para:',
                    value: DateFormat.MMMEd().add_Hm().format(forecast.forecastTime!),
                  ),
                  if (forecast.travelTime != null)
                    _forecastDetailRow(
                      context,
                      label: 'Tempo de viagem:',
                      value:
                      '${forecast.travelTime!.inHours}h ${forecast.travelTime!.inMinutes.remainder(60)}min',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _forecastDetailRow(BuildContext context,
      {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
