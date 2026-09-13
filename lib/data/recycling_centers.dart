import 'package:flutter/material.dart';

class RecyclingCenter {
  final String name;
  final String municipality;
  final String address;
  final String materials;
  final String hours;
  final Color color;
  final double latitude;
  final double longitude;

  const RecyclingCenter({
    required this.name,
    required this.municipality,
    required this.address,
    required this.materials,
    required this.hours,
    required this.color,
    required this.latitude,
    required this.longitude,
  });
}

const List<RecyclingCenter> lagunaRecyclingCenters = [
  // ============================================================
  // CALAMBA
  // ============================================================

  RecyclingCenter(
    name: 'Integrated Recycling Industries Philippines, Inc.',
    municipality: 'Calamba',
    address:
        'Lot C4-5B, Carmelray Industrial Park 2, Brgy. Punta, Calamba City, Laguna',
    materials: 'Industrial and electronic recyclable materials',
    hours: 'Contact facility for current hours',
    color: Colors.green,
    latitude: 14.17889,
    longitude: 121.12519,
  ),

  RecyclingCenter(
    name: 'HMR Envirocycle Philippines Inc.',
    municipality: 'Calamba',
    address:
        'C.A. Yulo Avenue, Silangan Industrial Park, Canlubang, Calamba City, Laguna',
    materials: 'Waste and recyclable materials',
    hours: 'Monday - Saturday\n7:00 AM - 4:00 PM',
    color: Colors.blue,
    latitude: 14.27464,
    longitude: 121.08368,
  ),

  RecyclingCenter(
    name: 'Maritrans Recycler, Inc.',
    municipality: 'Calamba',
    address:
        'Unit 3 D.M. Ragasa Warehouse, 763 National Highway, Parian, Calamba City, Laguna',
    materials:
        'Electronic scraps, used batteries and other recoverable industrial wastes',
    hours: 'Monday - Friday\n8:00 AM - 6:15 PM',
    color: Colors.teal,
    latitude: 14.21766950414476,
    longitude: 121.1438714288363,
  ),

  RecyclingCenter(
    name: 'TMC Metal Philippines Inc.',
    municipality: 'Calamba',
    address:
        'Lot C2-3, Unit 1, Carmelray Industrial Park 2, Punta, Calamba City, Laguna',
    materials: 'Metal and recyclable materials',
    hours: 'Monday - Friday\n8:30 AM - 5:30 PM',
    color: Colors.orange,
    latitude: 14.176050647803253,
    longitude: 121.1250808288363,
  ),

  RecyclingCenter(
    name: 'Recycle Plus Inc.',
    municipality: 'Calamba',
    address: 'Calamba, Laguna',
    materials: 'Recyclable materials',
    hours: 'Monday - Sunday\n8:00 AM - 5:00 PM',
    color: Colors.indigo,
    latitude: 14.2139691,
    longitude: 121.1292795,
  ),

  // ============================================================
  // SANTA ROSA
  // ============================================================

  RecyclingCenter(
    name: 'Envirocycle Philippines, Inc.',
    municipality: 'Santa Rosa',
    address:
        'Daystar Industrial Park, Pulong, Santa Rosa, Laguna',
    materials: 'Recycling and waste management',
    hours: 'Contact facility for current hours',
    color: Colors.purple,
    latitude: 14.308220206847626,
    longitude: 121.10806354232734,
  ),

  // ============================================================
  // CABUYAO
  // ============================================================

  RecyclingCenter(
    name: 'Junk Shop',
    municipality: 'Cabuyao',
    address: 'Pulo-Diezmo Road, Cabuyao City, Laguna',
    materials: 'Recyclable and scrap materials',
    hours: 'Contact facility for current hours',
    color: Colors.blue,
    latitude: 14.246291672954655,
    longitude: 121.1287119288363,
  ),

  // ============================================================
  // SAN PEDRO
  // ============================================================

  RecyclingCenter(
    name: 'Tritek Reverse Logistics Corporation',
    municipality: 'San Pedro',
    address:
        '7270 Narra Road, San Antonio, San Pedro, Laguna',
    materials: 'Recycling and reverse logistics',
    hours: 'Monday - Saturday\n8:00 AM - 5:00 PM',
    color: Colors.teal,
    latitude: 14.34580226022469,
    longitude: 121.01860498650896,
  ),

  // ============================================================
  // PAGSANJAN
  // ============================================================

  RecyclingCenter(
    name: 'sansidro resiklo',
    municipality: 'Pagsanjan',
    address:
        'Purok 1, Brgy. San Isidro, Pagsanjan, Laguna',
    materials: 'Recyclable materials',
    hours: 'Contact facility for current hours',
    color: Colors.green,
    latitude: 14.173088150859693,
    longitude: 121.18196631534526,
  ),

  // ============================================================
  // PILA
  // ============================================================

  RecyclingCenter(
    name: 'Plastic Recycling Factory',
    municipality: 'Pila',
    address: 'Bukal, Pila, Laguna',
    materials: 'Plastic recycling',
    hours: 'Contact facility for current hours',
    color: Colors.orange,
    latitude: 14.214626104385387,
    longitude: 121.37382500185423,
  ),

  // ============================================================
  // SANTA CRUZ
  // ============================================================

  RecyclingCenter(
    name: 'Junk Shop BIGBOSS',
    municipality: 'Santa Cruz',
    address:
        'Zone 6, National Highway, Patimbao, Santa Cruz, Laguna',
    materials: 'Scrap and recyclable materials',
    hours: 'Open 24 hours',
    color: Colors.red,
    latitude: 14.267910246434793,
    longitude: 121.41430392883628,
  ),

  // ============================================================
  // BAY
  // ============================================================

  RecyclingCenter(
    name: 'Phileco Laguna',
    municipality: 'Bay',
    address: 'F.T. San Luis Avenue, Bay, Laguna',
    materials: 'Waste management',
    hours: 'Contact facility for current hours',
    color: Colors.blue,
    latitude: 14.118065321866812,
    longitude: 121.24320815767264,
  ),
];