import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class LocationSearchScreen extends StatefulWidget {
  final Function(String, double, double) onSelectLocation;

  LocationSearchScreen({required this.onSelectLocation});

  @override
  _LocationSearchScreenState createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  List<Placemark> _places = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _noLocationFound = false; // Flag for no location found

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true; // Start loading
      _places = []; // Clear previous results
      _noLocationFound = false; // Reset no location found flag
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          locations.first.latitude, locations.first.longitude);

      setState(() {
        _places = placemarks;
        _noLocationFound = _places.isEmpty; // Set flag if no places found
      });
    } catch (e) {
      // Handle error (e.g., no results found)
      print('Error: $e');
      setState(() {
        _noLocationFound = true; // Set flag if error occurs
      });
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Location'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _searchLocation,
              decoration: InputDecoration(
                labelText: 'Search Location',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search, color: Colors.black),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_noLocationFound)
              Center(child: Text('No locations found.', style: TextStyle(color: Colors.red)))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(
                          place.locality ?? 'Unknown',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(place.country ?? 'Unknown'),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.black),
                        onTap: () async {
                          // Get coordinates of the selected place
                          List<Location> locations = await locationFromAddress(
                            '${place.locality}, ${place.country}',
                          );
                          final latitude = locations.first.latitude;
                          final longitude = locations.first.longitude;

                          // Call the onSelectLocation function with the selected values
                          widget.onSelectLocation(
                            place.locality ?? 'Unknown',
                            latitude,
                            longitude,
                          );
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
