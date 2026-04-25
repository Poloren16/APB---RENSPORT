import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_colors.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});
  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng _selectedLocation = const LatLng(-6.2088, 106.8456);
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(Marker(markerId: const MarkerId('loc'), position: _selectedLocation, draggable: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 12),
        onTap: (pos) => setState(() {
          _selectedLocation = pos;
          _markers.clear();
          _markers.add(Marker(markerId: const MarkerId('loc'), position: pos));
        }),
        markers: _markers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, {
          'lat': _selectedLocation.latitude,
          'lng': _selectedLocation.longitude,
        }),
        label: const Text('Gunakan Lokasi'),
        icon: const Icon(Icons.check),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
