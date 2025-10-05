import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/primary_button.dart';
import '../widgets/terminal_request_trike_modal.dart';
import 'signin_screen_terminal.dart';

class TerminalHome extends StatefulWidget {
  final String terminalName;
  final String terminalId;

  const TerminalHome({
    super.key,
    this.terminalName = 'Terminal 1',
    this.terminalId = 'terminal_1',
  });

  @override
  State<TerminalHome> createState() => _TerminalHomeState();
}

class _TerminalHomeState extends State<TerminalHome> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  Future<BitmapDescriptor> _getResizedMarker(String path, int targetWidth) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final Uint8List resizedData =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resizedData);
  }

  void _updateMarkers() async {
    final List<LatLng> terminalLocations = [
      const LatLng(15.116888, 120.615710),
      const LatLng(15.117600, 120.614200),
      const LatLng(15.118200, 120.617200),
      const LatLng(15.115600, 120.613500),
      const LatLng(15.115900, 120.616000),
    ];

    final BitmapDescriptor terminalIcon = await _getResizedMarker(
      'assets/icons/terminal.png',
      120,
    );

    setState(() {
      _markers.clear();
      for (int i = 0; i < terminalLocations.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('terminal_${i + 1}'),
            position: terminalLocations[i],
            icon: terminalIcon,
            infoWindow: InfoWindow(
              title: "Tricycle Terminal ${i + 1}",
              snippet: "Telabastagan",
            ),
          ),
        );
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreenTerminal()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final LatLngBounds telabastaganBounds = LatLngBounds(
      southwest: const LatLng(15.1140, 120.6125),
      northeast: const LatLng(15.1195, 120.6185),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(15.116888, 120.615710),
              zoom: 16.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            cameraTargetBounds: CameraTargetBounds(telabastaganBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(16, 20),
            zoomControlsEnabled: true,
            markers: _markers,
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0097B2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                      ),
                      onPressed: () => _logout(context),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0097B2).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      widget.terminalName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: 208,
                  height: 61,
                  child: PrimaryButton(
                    text: "Ride Request",
                    icon: SvgPicture.asset(
                      "assets/icons/person_search.svg",
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => TerminalRequestTrikeModal(
                          terminalId: widget.terminalId,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}