import 'dart:ui';
import 'india_states_data.dart';

/// Simplified, geographically-sensible polygon for one Indian state.
///
/// Coordinates are normalized 0..1 with x = west→east and y = north→south,
/// matching the map screen's drawing space.
class StateShape {
  final String name;
  final List<Offset> points;

  const StateShape({required this.name, required this.points});
}

/// A small marker (city / heritage site) dropped on top of its parent state.
class HeritagePin {
  final String name;
  final Offset normalized;

  const HeritagePin({required this.name, required this.normalized});
}

// ============================ STATE SHAPES ============================

const List<StateShape> indiaStateShapes = [
  // ------------------------------ NORTH ------------------------------
  StateShape(name: "Jammu & Kashmir", points: [
    Offset(0.40, 0.03), Offset(0.52, 0.03), Offset(0.56, 0.08),
    Offset(0.54, 0.11), Offset(0.44, 0.13), Offset(0.38, 0.10),
    Offset(0.36, 0.06),
  ]),
  StateShape(name: "Himachal Pradesh", points: [
    Offset(0.44, 0.13), Offset(0.54, 0.10), Offset(0.57, 0.14),
    Offset(0.52, 0.18), Offset(0.45, 0.17), Offset(0.42, 0.15),
  ]),
  StateShape(name: "Punjab", points: [
    Offset(0.30, 0.11), Offset(0.40, 0.10), Offset(0.44, 0.13),
    Offset(0.42, 0.17), Offset(0.34, 0.18), Offset(0.29, 0.15),
  ]),
  StateShape(name: "Uttarakhand", points: [
    Offset(0.52, 0.17), Offset(0.58, 0.13), Offset(0.62, 0.17),
    Offset(0.60, 0.21), Offset(0.55, 0.22), Offset(0.51, 0.19),
  ]),
  StateShape(name: "Haryana", points: [
    Offset(0.33, 0.19), Offset(0.43, 0.18), Offset(0.46, 0.23),
    Offset(0.41, 0.26), Offset(0.33, 0.24), Offset(0.31, 0.21),
  ]),
  StateShape(name: "Delhi", points: [
    Offset(0.38, 0.20), Offset(0.42, 0.20), Offset(0.42, 0.23),
    Offset(0.38, 0.23),
  ]),
  StateShape(name: "Rajasthan", points: [
    Offset(0.13, 0.14), Offset(0.27, 0.17), Offset(0.32, 0.23),
    Offset(0.30, 0.32), Offset(0.24, 0.37), Offset(0.17, 0.35),
    Offset(0.12, 0.28), Offset(0.10, 0.20),
  ]),
  StateShape(name: "Uttar Pradesh", points: [
    Offset(0.45, 0.22), Offset(0.58, 0.20), Offset(0.65, 0.24),
    Offset(0.62, 0.31), Offset(0.53, 0.35), Offset(0.46, 0.32),
    Offset(0.43, 0.26),
  ]),

  // ------------------------------- WEST -------------------------------
  StateShape(name: "Gujarat", points: [
    Offset(0.05, 0.20), Offset(0.15, 0.18), Offset(0.20, 0.24),
    Offset(0.18, 0.34), Offset(0.12, 0.38), Offset(0.06, 0.34),
    Offset(0.04, 0.27),
  ]),
  StateShape(name: "Goa", points: [
    Offset(0.12, 0.60), Offset(0.17, 0.60), Offset(0.17, 0.63),
    Offset(0.12, 0.63),
  ]),
  StateShape(name: "Maharashtra", points: [
    Offset(0.11, 0.42), Offset(0.23, 0.40), Offset(0.30, 0.45),
    Offset(0.28, 0.56), Offset(0.20, 0.60), Offset(0.11, 0.56),
    Offset(0.07, 0.49),
  ]),

  // ---------------------------- CENTRAL -------------------------------
  StateShape(name: "Madhya Pradesh", points: [
    Offset(0.23, 0.34), Offset(0.36, 0.32), Offset(0.45, 0.35),
    Offset(0.43, 0.42), Offset(0.35, 0.45), Offset(0.27, 0.44),
    Offset(0.22, 0.39),
  ]),
  StateShape(name: "Chhattisgarh", points: [
    Offset(0.47, 0.44), Offset(0.57, 0.43), Offset(0.60, 0.47),
    Offset(0.58, 0.53), Offset(0.51, 0.52), Offset(0.46, 0.48),
  ]),

  // ------------------------------- EAST -------------------------------
  StateShape(name: "Bihar", points: [
    Offset(0.60, 0.30), Offset(0.70, 0.28), Offset(0.73, 0.33),
    Offset(0.69, 0.38), Offset(0.62, 0.36), Offset(0.58, 0.33),
  ]),
  StateShape(name: "Jharkhand", points: [
    Offset(0.58, 0.40), Offset(0.70, 0.39), Offset(0.72, 0.45),
    Offset(0.66, 0.50), Offset(0.58, 0.47), Offset(0.55, 0.43),
  ]),
  StateShape(name: "West Bengal", points: [
    Offset(0.72, 0.28), Offset(0.80, 0.30), Offset(0.79, 0.38),
    Offset(0.73, 0.40), Offset(0.70, 0.35), Offset(0.71, 0.30),
  ]),
  StateShape(name: "Odisha", points: [
    Offset(0.58, 0.50), Offset(0.70, 0.49), Offset(0.73, 0.53),
    Offset(0.70, 0.58), Offset(0.63, 0.60), Offset(0.57, 0.55),
  ]),

  // --------------------------- NORTH-EAST ---------------------------
  StateShape(name: "Sikkim", points: [
    Offset(0.54, 0.20), Offset(0.58, 0.19), Offset(0.60, 0.22),
    Offset(0.57, 0.25), Offset(0.53, 0.23),
  ]),
  StateShape(name: "Arunachal Pradesh", points: [
    Offset(0.62, 0.10), Offset(0.76, 0.14), Offset(0.82, 0.20),
    Offset(0.78, 0.26), Offset(0.68, 0.24), Offset(0.62, 0.17),
  ]),
  StateShape(name: "Assam", points: [
    Offset(0.60, 0.22), Offset(0.71, 0.25), Offset(0.75, 0.31),
    Offset(0.68, 0.36), Offset(0.60, 0.33), Offset(0.56, 0.27),
  ]),
  StateShape(name: "Nagaland", points: [
    Offset(0.72, 0.26), Offset(0.80, 0.26), Offset(0.83, 0.30),
    Offset(0.77, 0.34), Offset(0.72, 0.31),
  ]),
  StateShape(name: "Meghalaya", points: [
    Offset(0.56, 0.36), Offset(0.66, 0.37), Offset(0.67, 0.42),
    Offset(0.61, 0.44), Offset(0.56, 0.41),
  ]),
  StateShape(name: "Manipur", points: [
    Offset(0.73, 0.34), Offset(0.81, 0.34), Offset(0.84, 0.39),
    Offset(0.79, 0.43), Offset(0.74, 0.40), Offset(0.72, 0.37),
  ]),
  StateShape(name: "Tripura", points: [
    Offset(0.55, 0.44), Offset(0.64, 0.43), Offset(0.66, 0.47),
    Offset(0.61, 0.51), Offset(0.55, 0.49),
  ]),
  StateShape(name: "Mizoram", points: [
    Offset(0.60, 0.51), Offset(0.70, 0.50), Offset(0.71, 0.55),
    Offset(0.66, 0.58), Offset(0.61, 0.56), Offset(0.59, 0.53),
  ]),

  // ------------------------------- SOUTH -------------------------------
  StateShape(name: "Telangana", points: [
    Offset(0.28, 0.46), Offset(0.39, 0.44), Offset(0.43, 0.50),
    Offset(0.38, 0.56), Offset(0.31, 0.54), Offset(0.28, 0.50),
  ]),
  StateShape(name: "Andhra Pradesh", points: [
    Offset(0.33, 0.56), Offset(0.44, 0.55), Offset(0.48, 0.61),
    Offset(0.44, 0.68), Offset(0.37, 0.68), Offset(0.32, 0.62),
  ]),
  StateShape(name: "Karnataka", points: [
    Offset(0.13, 0.62), Offset(0.26, 0.62), Offset(0.30, 0.70),
    Offset(0.25, 0.76), Offset(0.16, 0.76), Offset(0.12, 0.70),
  ]),
  StateShape(name: "Kerala", points: [
    Offset(0.18, 0.76), Offset(0.28, 0.77), Offset(0.29, 0.84),
    Offset(0.23, 0.88), Offset(0.17, 0.83),
  ]),
  StateShape(name: "Tamil Nadu", points: [
    Offset(0.34, 0.68), Offset(0.46, 0.67), Offset(0.48, 0.76),
    Offset(0.42, 0.83), Offset(0.37, 0.78), Offset(0.33, 0.73),
  ]),
];

/// City / heritage pins overlaid on the state map.
const List<HeritagePin> indiaHeritagePins = [
  HeritagePin(name: "Mumbai", normalized: Offset(0.155, 0.52)),
  HeritagePin(name: "Jaipur", normalized: Offset(0.19, 0.21)),
  HeritagePin(name: "Agra", normalized: Offset(0.52, 0.245)),
  HeritagePin(name: "Kolkata", normalized: Offset(0.74, 0.33)),
];

/// Celebrated festival for every data entry (states + heritage trail).
const Map<String, String> stateFestivals = {
  "Jammu & Kashmir": "Tulip Festival & Eid",
  "Punjab": "Baisakhi",
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