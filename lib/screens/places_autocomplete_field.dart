import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlacesAutocompleteField extends StatefulWidget {
  final String apiKey;
  final String label;
  final TextEditingController? controller;
  final Function(String description, double lat, double lng) onPlaceSelected;

  const PlacesAutocompleteField({
    required this.apiKey,
    required this.label,
    required this.onPlaceSelected,
    this.controller,
    Key? key,
  }) : super(key: key);

  @override
  State<PlacesAutocompleteField> createState() => _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  late final TextEditingController _controller;
  bool _ownsController = false;


  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
  }


  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _getSuggestions(String input) async {
    if (input.isEmpty) return;
    setState(() => _isLoading = true);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=${widget.apiKey}&types=geocode&language=en',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        setState(() => _suggestions = data['predictions']);
      } else {
        setState(() => _suggestions = []);
        print('Google API error: ${data['status']} - ${data['error_message']}');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }

    setState(() => _isLoading = false);
  }



  Future<void> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${widget.apiKey}',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final description = data['result']['formatted_address'];
        widget.onPlaceSelected(description, location['lat'], location['lng']);
        _controller.text = description;
        setState(() => _suggestions = []);
      } else {
        print('Failed to fetch place details: ${data['error_message']}');
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _getSuggestions,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.location_on),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Material(
            elevation: 2,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  title: Text(item['description']),
                  onTap: () => _getPlaceDetails(item['place_id']),
                );
              },
            ),
          ),
      ],
    );
  }
}
