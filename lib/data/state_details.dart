import 'india_states_data.dart';

/// Traditional folk / classical dance shown on every state's detail page.
const Map<String, String> stateDances = {
  "Jammu & Kashmir": "Rouf & Kud",
  "Punjab": "Bhangra & Giddha",
  "Himachal Pradesh": "Nati",
  "Uttarakhand": "Chholiya",
  "Haryana": "Saang",
  "Delhi": "Kathak",
  "Rajasthan": "Ghoomar & Kalbeliya",
  "Uttar Pradesh": "Kathak",
  "Gujarat": "Garba & Dandiya Raas",
  "Goa": "Dekhni & Fugdi",
  "Maharashtra": "Lavani",
  "Madhya Pradesh": "Gaur & Karma",
  "Chhattisgarh": "Panthi",
  "Bihar": "Jat-Jatin",
  "Jharkhand": "Seraikela Chhau",
  "West Bengal": "Chhau & Rabindra Nritya",
  "Odisha": "Odissi",
  "Sikkim": "Singhi Chaam",
  "Arunachal Pradesh": "Aji Lhamu (Monpa)",
  "Assam": "Sattriya & Bihu",
  "Nagaland": "Chang Lo",
  "Meghalaya": "Shad Suk Mynsiem",
  "Manipur": "Manipuri Ras Leela",
  "Mizoram": "Cheraw (Bamboo Dance)",
  "Tripura": "Hojagiri",
  "Telangana": "Perini Shivatandavam",
  "Andhra Pradesh": "Kuchipudi",
  "Karnataka": "Yakshagana",
  "Kerala": "Kathakali & Mohiniyattam",
  "Tamil Nadu": "Bharatanatyam",
  "Mumbai": "Lavani",
  "Jaipur": "Ghoomar",
  "Agra": "Kathak",
  "Kolkata": "Rabindra Nritya",
};

/// The famous dance (or dance form) associated with a state.
String danceFor(IndiaState state) => stateDances[state.name] ?? "Folk dance";