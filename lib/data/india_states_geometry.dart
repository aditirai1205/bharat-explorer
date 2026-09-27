import 'dart:ui';
import 'india_states_data.dart';

/// Simplified, geographically-sensible polygon for one Indian state.
///
/// Coordinates are normalized 0..1 with x = west→east and y = north→south,
/// matching the map screen's drawing space. They are derived from real
/// latitude/longitude bounds so the union of states reads as the real shape
/// of India.
class StateShape {
  final String name;
  final List<Offset> points;

  const StateShape({required this.name, required this.points});
}

/// A small marker (city / heritage site) dropped on top of its parent state.
class HeritagePin {
  final String name;
  final String? state;
  final Offset normalized;

  const HeritagePin({required this.name, this.state, required this.normalized});
}

/// Projection box (decimal degrees).
const double _minLon = 68.0;
const double _maxLon = 97.6;
const double _maxLat = 37.0;
const double _minLat = 8.0;

Offset _p(double lon, double lat) => Offset(
      (lon - _minLon) / (_maxLon - _minLon),
      (_maxLat - lat) / (_maxLat - _minLat),
    );

// ======================== INDIA OUTLINE ========================
//
// A real, recognizable vector outline of India: the Kashmir kite, the
// north-west frontier, the Kathiawar & Kutch bulges, the peninsula tapering
// to Kanyakumari, the east coast, the Bengal delta, the Siliguri corridor
// and the north-east block.
final List<Offset> indiaOutline = [
  // ---- Kashmir / west frontier ----
  _p(77.15, 35.60), _p(75.9, 35.15), _p(74.7, 34.75), _p(74.2, 34.25),
  _p(74.0, 33.6), _p(74.1, 33.0), _p(74.6, 32.35),
  // ---- Punjab → Rajasthan → Kutch (Pakistan border) ----
  _p(74.9, 31.8), _p(74.55, 31.05), _p(74.05, 30.4), _p(73.5, 29.7),
  _p(72.95, 28.95), _p(72.35, 28.15), _p(71.75, 27.35), _p(71.05, 26.55),
  _p(70.4, 25.8), _p(70.1, 25.0), _p(70.05, 24.3), _p(69.4, 23.9),
  _p(68.5, 23.85), _p(68.2, 23.65),
  // ---- Gujarat coastline (Saurashtra + Gulf of Khambhat) ----
  _p(68.85, 23.15), _p(69.45, 22.95), _p(70.1, 22.4), _p(70.0, 21.85),
  _p(70.55, 21.2), _p(71.4, 20.95), _p(72.35, 21.3), _p(72.5, 20.6),
  // ---- Konkan / Malabar coast ----
  _p(72.85, 20.3), _p(72.9, 19.6), _p(72.85, 19.05), _p(73.0, 18.3),
  _p(73.4, 17.6), _p(73.7, 16.7), _p(74.05, 16.0), _p(74.1, 15.3),
  _p(74.0, 14.85), _p(74.35, 14.2), _p(74.65, 13.7), _p(74.9, 13.15),
  _p(75.2, 12.5), _p(75.6, 11.9), _p(76.2, 11.1), _p(76.75, 10.2),
  _p(77.2, 9.2), _p(77.55, 8.07),
  // ---- East / Coromandel coast ----
  _p(78.3, 8.9), _p(79.3, 9.3), _p(79.85, 10.3), _p(80.1, 10.9),
  _p(80.05, 11.7), _p(80.3, 12.7), _p(80.25, 13.4), _p(79.95, 14.3),
  _p(80.15, 15.0), _p(80.5, 15.9), _p(81.0, 16.4), _p(81.8, 16.95),
  // ---- Andhra → Odisha coast ----
  _p(82.8, 17.6), _p(83.5, 18.1), _p(84.4, 18.8), _p(85.3, 19.6),
  _p(85.9, 19.9), _p(86.4, 20.5), _p(86.8, 21.2), _p(87.35, 21.6),
  _p(88.0, 21.8), _p(88.45, 21.7), _p(88.75, 21.95),
  // ---- West Bengal ↔ Bangladesh frontier ----
  _p(89.4, 22.5), _p(89.5, 23.3), _p(89.25, 24.05), _p(89.0, 24.75),
  _p(88.85, 25.45), _p(88.6, 26.15),
  // ---- Siliguri corridor + phulbari buldge ----
  _p(89.2, 26.55), _p(90.05, 26.6), _p(90.65, 26.35), _p(90.35, 25.95),
  _p(90.1, 25.5),
  // ---- Meghalaya → Tripura → Mizoram ----
  _p(90.95, 25.2), _p(91.4, 24.65), _p(91.55, 23.9), _p(92.0, 23.05),
  _p(92.7, 22.15),
  // ---- Myanmar frontier (Mizoram → Arunachal tip) ----
  _p(92.9, 22.7), _p(93.1, 23.45), _p(93.4, 24.25), _p(94.05, 25.0),
  _p(94.5, 25.6), _p(95.1, 26.25), _p(95.9, 26.9), _p(96.8, 27.7),
  _p(97.4, 28.35),
  // ---- Arunachal / Tibet frontier → Bhutan ----
  _p(96.5, 28.8), _p(95.5, 28.6), _p(94.4, 28.2), _p(93.2, 27.6),
  _p(92.1, 26.8), _p(91.5, 26.85), _p(90.5, 26.95), _p(89.5, 26.9),
  _p(88.7, 26.75),
  // ---- Sikkim / Darjeeling → Nepal frontier ----
  _p(88.12, 26.95), _p(88.0, 26.55),
  // ---- Nepal frontier (over the Terai) ----
  _p(87.5, 26.6), _p(86.6, 26.7), _p(85.6, 26.75), _p(84.7, 26.9),
  _p(83.9, 26.95), _p(83.0, 27.0), _p(82.2, 27.2), _p(81.4, 27.7),
  _p(80.7, 28.3), _p(80.2, 28.9), _p(80.05, 29.75), _p(80.35, 30.4),
  // ---- Tibet frontier (Uttarakhand → Himachal → Ladakh) ----
  _p(80.0, 30.8), _p(79.55, 31.0), _p(79.0, 31.6), _p(78.4, 31.7),
  _p(78.35, 32.2), _p(78.85, 32.9), _p(79.0, 33.4), _p(78.6, 33.5),
  _p(79.2, 34.1), _p(79.6, 34.6), _p(78.9, 34.9), _p(77.9, 35.4),
];

// ============================ STATE SHAPES ============================
//
// Simplified but geographically correct polygons (real lat/lon bounds). The
// map painter clips every state inside the national outline, so the country
// always reads as the real shape of India.

final List<StateShape> indiaStateShapes = [
  // ------------------------------ NORTH ------------------------------
  StateShape(name: "Jammu & Kashmir", points: [
    _p(77.15, 35.6), _p(75.9, 35.15), _p(74.7, 34.75), _p(74.2, 34.25),
    _p(74.0, 33.6), _p(74.6, 32.35), _p(75.4, 32.5), _p(76.3, 32.75),
    _p(77.5, 32.9), _p(78.3, 32.6), _p(77.9, 33.7), _p(77.5, 34.5),
  ]),
  StateShape(name: "Ladakh", points: [
    _p(77.15, 35.6), _p(77.9, 35.4), _p(78.9, 34.9), _p(79.6, 34.6),
    _p(79.2, 34.1), _p(79.0, 33.4), _p(79.0, 33.0), _p(78.3, 32.6),
    _p(77.9, 33.7), _p(77.5, 34.5),
  ]),
  StateShape(name: "Punjab", points: [
    _p(74.6, 32.35), _p(75.4, 32.5), _p(76.3, 32.75), _p(76.35, 31.7),
    _p(76.3, 30.0), _p(75.4, 30.0), _p(73.5, 29.7), _p(74.05, 30.4),
    _p(74.55, 31.05), _p(74.9, 31.8),
  ]),
  StateShape(name: "Chandigarh", points: [
    _p(76.5, 30.55), _p(77.0, 30.55), _p(77.0, 30.95), _p(76.5, 30.95),
  ]),
  StateShape(name: "Himachal Pradesh", points: [
    _p(76.3, 32.75), _p(77.5, 32.9), _p(78.3, 32.6), _p(78.3, 30.9),
    _p(77.4, 30.7), _p(76.5, 30.4), _p(76.35, 31.7),
  ]),
  StateShape(name: "Uttarakhand", points: [
    _p(78.3, 32.6), _p(78.4, 31.7), _p(79.0, 31.6), _p(79.55, 31.0),
    _p(80.0, 30.8), _p(80.35, 30.4), _p(80.15, 28.9), _p(79.3, 28.95),
    _p(78.7, 29.3), _p(78.3, 30.9),
  ]),
  StateShape(name: "Haryana", points: [
    _p(76.3, 30.0), _p(76.5, 30.4), _p(77.4, 30.7), _p(77.4, 28.1),
    _p(76.5, 27.7), _p(74.9, 27.7), _p(75.2, 29.3), _p(74.85, 29.9),
  ]),
  StateShape(name: "Delhi", points: [
    _p(76.8, 28.4), _p(77.3, 28.4), _p(77.3, 28.9), _p(76.8, 28.9),
  ]),
  StateShape(name: "Rajasthan", points: [
    _p(73.5, 29.7), _p(72.95, 28.95), _p(72.35, 28.15), _p(71.75, 27.35),
    _p(71.05, 26.55), _p(70.4, 25.8), _p(70.1, 25.0), _p(70.05, 24.3),
    _p(71.1, 23.9), _p(71.9, 23.8), _p(72.4, 24.4), _p(73.3, 24.6),
    _p(74.3, 24.9), _p(75.0, 25.6), _p(76.4, 27.2), _p(77.4, 28.1),
    _p(76.9, 29.9), _p(76.1, 30.0),
  ]),
  StateShape(name: "Uttar Pradesh", points: [
    _p(80.15, 28.75), _p(80.7, 28.3), _p(81.4, 27.7), _p(82.2, 27.2),
    _p(83.0, 27.0), _p(83.9, 26.95), _p(84.65, 26.9), _p(84.5, 27.5),
    _p(84.1, 28.1), _p(83.2, 28.4), _p(81.9, 27.8), _p(80.9, 28.1),
    _p(80.2, 27.9), _p(79.5, 28.3), _p(78.7, 28.6), _p(77.4, 28.0),
    _p(77.4, 28.6), _p(78.7, 29.3),
  ]),

  // ------------------------------- WEST -------------------------------
  StateShape(name: "Gujarat", points: [
    _p(70.05, 24.3), _p(71.1, 23.9), _p(71.9, 23.8), _p(72.4, 24.4),
    _p(73.3, 24.6), _p(74.2, 24.2), _p(73.9, 22.5), _p(73.5, 21.5),
    _p(73.1, 20.9), _p(72.5, 20.6), _p(72.35, 21.3), _p(71.4, 20.95),
    _p(70.55, 21.2), _p(70.0, 21.85), _p(70.1, 22.4), _p(69.45, 22.95),
    _p(68.85, 23.15), _p(68.2, 23.65), _p(68.5, 23.85), _p(69.4, 23.9),
  ]),
  StateShape(name: "Goa", points: [
    _p(74.0, 14.85), _p(74.2, 15.0), _p(74.35, 15.55), _p(74.1, 15.6),
    _p(73.98, 15.35),
  ]),
  StateShape(name: "Maharashtra", points: [
    _p(72.85, 19.05), _p(72.9, 20.3), _p(73.1, 20.9), _p(73.5, 21.5),
    _p(73.9, 22.5), _p(74.2, 24.2), _p(77.6, 22.6), _p(79.6, 21.6),
    _p(80.9, 20.5), _p(80.0, 18.9), _p(79.5, 17.7), _p(77.6, 16.9),
    _p(76.4, 16.5), _p(75.3, 16.3), _p(74.7, 17.0), _p(73.4, 17.6),
    _p(73.0, 18.3),
  ]),

  // ---------------------------- CENTRAL -------------------------------
  StateShape(name: "Madhya Pradesh", points: [
    _p(74.2, 24.2), _p(73.3, 24.6), _p(74.3, 24.9), _p(75.0, 25.6),
    _p(76.4, 27.2), _p(77.6, 28.0), _p(79.0, 26.5), _p(80.5, 24.0),
    _p(81.2, 22.7), _p(80.5, 21.9), _p(77.0, 22.3), _p(74.9, 22.0),
    _p(73.9, 22.5),
  ]),
  StateShape(name: "Chhattisgarh", points: [
    _p(80.5, 21.9), _p(81.2, 22.7), _p(80.5, 24.0), _p(79.0, 26.5),
    _p(81.4, 26.8), _p(81.9, 24.6), _p(83.2, 23.2), _p(82.9, 21.9),
    _p(81.6, 20.9), _p(80.2, 18.9),
  ]),

  // ------------------------------- EAST -------------------------------
  StateShape(name: "Bihar", points: [
    _p(84.65, 26.9), _p(85.6, 26.75), _p(86.6, 26.7), _p(87.5, 26.6),
    _p(87.8, 27.0), _p(87.65, 25.7), _p(87.3, 25.1), _p(86.9, 24.5),
    _p(85.9, 24.3), _p(85.0, 24.4), _p(84.25, 24.5), _p(84.1, 25.0),
    _p(84.2, 25.8), _p(84.5, 26.2),
  ]),
  StateShape(name: "Jharkhand", points: [
    _p(83.9, 24.2), _p(84.25, 24.5), _p(85.0, 24.4), _p(85.9, 24.3),
    _p(86.9, 24.5), _p(87.5, 25.2), _p(87.9, 24.4), _p(87.6, 23.5),
    _p(86.9, 22.4), _p(86.0, 21.9), _p(85.0, 22.2), _p(84.2, 22.7),
    _p(83.9, 23.4),
  ]),
  StateShape(name: "West Bengal", points: [
    _p(88.45, 21.7), _p(88.75, 21.95), _p(89.4, 22.5), _p(89.5, 23.3),
    _p(89.25, 24.05), _p(89.0, 24.75), _p(88.85, 25.45), _p(88.6, 26.15),
    _p(89.4, 26.75), _p(90.6, 26.75), _p(90.45, 26.0), _p(90.1, 25.4),
    _p(88.9, 25.9), _p(88.5, 25.3), _p(87.9, 25.4), _p(87.4, 24.1),
    _p(86.9, 22.7), _p(86.9, 21.9),
  ]),
  StateShape(name: "Odisha", points: [
    _p(81.6, 20.9), _p(82.9, 21.9), _p(84.2, 21.5), _p(85.3, 21.4),
    _p(86.4, 21.3), _p(87.0, 21.0), _p(86.9, 22.2), _p(86.9, 22.7),
    _p(85.5, 22.5), _p(84.2, 21.8),
  ]),

  // --------------------------- NORTH-EAST ---------------------------
  StateShape(name: "Sikkim", points: [
    _p(88.1, 27.05), _p(88.75, 27.3), _p(88.85, 28.0), _p(88.15, 28.05),
    _p(88.05, 27.5),
  ]),
  StateShape(name: "Arunachal Pradesh", points: [
    _p(92.1, 26.8), _p(93.2, 27.6), _p(94.4, 28.2), _p(95.5, 28.6),
    _p(96.5, 28.8), _p(97.4, 28.35), _p(96.8, 27.7), _p(95.9, 26.9),
    _p(95.0, 26.9), _p(94.0, 27.0), _p(93.0, 27.0),
  ]),
  StateShape(name: "Assam", points: [
    _p(90.15, 25.4), _p(90.6, 26.75), _p(91.5, 26.85), _p(92.1, 26.8),
    _p(93.4, 27.2), _p(94.8, 27.6), _p(94.7, 26.5), _p(94.6, 25.6),
    _p(94.0, 24.9), _p(93.0, 24.6), _p(92.2, 24.3), _p(91.2, 24.9),
  ]),
  StateShape(name: "Nagaland", points: [
    _p(94.7, 26.5), _p(95.25, 26.5), _p(95.2, 25.7), _p(94.7, 25.5),
    _p(94.4, 25.9),
  ]),
  StateShape(name: "Meghalaya", points: [
    _p(90.1, 25.5), _p(90.4, 26.0), _p(91.2, 26.2), _p(92.7, 25.9),
    _p(92.5, 25.3), _p(92.0, 25.1), _p(91.4, 24.95), _p(90.9, 25.0),
  ]),
  StateShape(name: "Manipur", points: [
    _p(93.9, 24.6), _p(94.5, 25.35), _p(94.85, 24.4), _p(94.4, 23.9),
    _p(93.75, 24.1), _p(93.5, 24.5),
  ]),
  StateShape(name: "Tripura", points: [
    _p(91.2, 23.8), _p(92.15, 23.1), _p(92.25, 23.9), _p(91.95, 24.5),
    _p(91.5, 24.3), _p(91.35, 23.5),
  ]),
  StateShape(name: "Mizoram", points: [
    _p(92.2, 24.1), _p(93.2, 24.0), _p(93.35, 22.9), _p(92.85, 22.15),
    _p(92.6, 22.5), _p(92.65, 23.3), _p(92.2, 23.4),
  ]),

  // ------------------------------- SOUTH -------------------------------
  StateShape(name: "Telangana", points: [
    _p(77.6, 15.9), _p(80.4, 16.1), _p(81.0, 18.4), _p(80.9, 19.9),
    _p(79.3, 19.6), _p(78.5, 19.4), _p(77.6, 16.9),
  ]),
  StateShape(name: "Andhra Pradesh", points: [
    _p(80.4, 16.1), _p(83.0, 18.2), _p(84.6, 18.0), _p(84.55, 15.9),
    _p(83.6, 15.1), _p(82.4, 14.6), _p(81.2, 14.3), _p(80.3, 13.9),
    _p(79.6, 14.6), _p(78.9, 15.0), _p(77.9, 15.6),
  ]),
  StateShape(name: "Karnataka", points: [
    _p(74.7, 17.0), _p(76.4, 16.5), _p(77.6, 15.9), _p(77.3, 14.8),
    _p(76.9, 13.8), _p(76.8, 13.2), _p(76.4, 12.4), _p(75.9, 12.8),
    _p(75.2, 12.8), _p(74.9, 13.15), _p(74.65, 13.7), _p(74.7, 14.6),
    _p(75.0, 15.6),
  ]),
  StateShape(name: "Kerala", points: [
    _p(75.2, 12.4), _p(76.4, 12.5), _p(77.0, 11.5), _p(77.3, 9.6),
    _p(76.9, 9.0), _p(76.4, 9.3), _p(75.6, 10.9), _p(75.25, 12.0),
  ]),
  StateShape(name: "Tamil Nadu", points: [
    _p(77.3, 13.0), _p(78.4, 13.6), _p(79.8, 13.7), _p(80.3, 13.9),
    _p(80.3, 12.7), _p(80.05, 11.7), _p(80.1, 10.9), _p(79.85, 10.3),
    _p(79.3, 9.3), _p(78.3, 8.9), _p(77.55, 8.07), _p(77.2, 9.2),
    _p(76.75, 10.2), _p(76.2, 11.1), _p(76.4, 12.4),
  ]),
];

/// City / heritage pins overlaid on the state map. Every pin is linked to its
/// parent state (used for hit-testing and the state popup).
final List<HeritagePin> indiaHeritagePins = [
  HeritagePin(name: "Mumbai", state: "Maharashtra", normalized: _p(72.8, 19.1)),
  HeritagePin(name: "Delhi", state: "Delhi", normalized: _p(77.1, 28.6)),
  HeritagePin(name: "Jaipur", state: "Rajasthan", normalized: _p(75.8, 26.9)),
  HeritagePin(name: "Kolkata", state: "West Bengal", normalized: _p(88.3, 22.6)),
  HeritagePin(name: "Chennai", state: "Tamil Nadu", normalized: _p(80.3, 13.1)),
  HeritagePin(name: "Bengaluru", state: "Karnataka", normalized: _p(77.6, 13.0)),
  HeritagePin(name: "Hyderabad", state: "Telangana", normalized: _p(78.5, 17.4)),
  HeritagePin(name: "Srinagar", state: "Jammu & Kashmir", normalized: _p(74.8, 34.1)),
  HeritagePin(name: "Gangtok", state: "Sikkim", normalized: _p(88.6, 27.3)),
  HeritagePin(name: "Agra", state: "Uttar Pradesh", normalized: _p(78.05, 27.18)),
  HeritagePin(name: "Guwahati", state: "Assam", normalized: _p(91.74, 26.14)),
];

/// Celebrated festival for every data entry (states + heritage trail).
const Map<String, String> stateFestivals = {
  "Jammu & Kashmir": "Tulip Festival & Eid",
  "Ladakh": "Losar Festival",
  "Punjab": "Baisakhi",
  "Chandigarh": "Chandigarh Carnival",
  "Himachal Pradesh": "Kullu Dussehra",
  "Uttarakhand": "Nanda Devi Raj Jat",
  "Haryana": "Teej",
  "Delhi": "Republic Day & Diwali",
  "Rajasthan": "Pushkar Camel Fair",
  "Uttar Pradesh": "Kumbh Mela",
  "Gujarat": "Navratri & Uttarayan",
  "Goa": "Carnival",
  "Maharashtra": "Ganesh Chaturthi",
  "Madhya Pradesh": "Khajuraho Dance Festival",
  "Chhattisgarh": "Bastar Dussehra",
  "Bihar": "Chhath Puja",
  "Jharkhand": "Sarhul",
  "West Bengal": "Durga Puja",
  "Odisha": "Ratha Yatra",
  "Sikkim": "Losar",
  "Arunachal Pradesh": "Tawang Festival",
  "Assam": "Bihu",
  "Nagaland": "Hornbill Festival",
  "Meghalaya": "Nongkrem Dance",
  "Manipur": "Lai Haraoba",
  "Mizoram": "Chapchar Kut",
  "Tripura": "Kharchi Puja",
  "Telangana": "Bonalu",
  "Andhra Pradesh": "Makara Sankranti",
  "Karnataka": "Mysuru Dasara",
  "Kerala": "Onam",
  "Tamil Nadu": "Pongal",
  "Mumbai": "Ganesh Chaturthi",
  "Jaipur": "Teej",
  "Agra": "Taj Mahotsav",
  "Kolkata": "Durga Puja",
};

/// Festival shown in the state card.
String festivalFor(IndiaState state) => stateFestivals[state.name] ?? "Diwali";

/// The Indian state resolved from a pin name.
IndiaState? stateForPin(String pinName) {
  for (final pin in indiaHeritagePins) {
    if (pin.name == pinName) {
      return stateByName(pin.state ?? pinName);
    }
  }
  return stateByName(pinName);
}

/// The polygon for a state name or pin (null when the shape is missing).
StateShape? shapeForName(String name) {
  for (final s in indiaStateShapes) {
    if (s.name == name) return s;
  }
  return null;
}

/// The [IndiaState] resolved by shape/pin name.
IndiaState? stateByName(String name) {
  for (final s in indiaStates) {
    if (s.name == name) return s;
  }
  return null;
}