import 'dart:ui';

class IndiaState {
  final String name;
  final String capital;
  final String food;
  final String language;
  final String monument;
  final List<String> facts;
  final Offset mapPosition;
  final String region;

  const IndiaState({
    required this.name,
    required this.capital,
    required this.food,
    required this.language,
    required this.monument,
    required this.facts,
    required this.mapPosition,
    required this.region,
  });
}

const List<IndiaState> indiaStates = [

  // ============================
  // NORTH INDIA
  // ============================

  IndiaState(
    name: "Jammu & Kashmir",
    capital: "Srinagar / Jammu",
    food: "Rogan Josh",
    language: "Kashmiri, Dogri",
    monument: "Dal Lake",
    facts: [
      "The world-famous Dal Lake is called the 'Jewel in the crown of Kashmir'.",
      "Gulmarg has one of the highest golf courses in the world.",
    ],
    mapPosition: Offset(0.35, 0.05),
    region: "North India",
  ),

  IndiaState(
    name: "Punjab",
    capital: "Chandigarh",
    food: "Makki di Roti & Sarson da Saag",
    language: "Punjabi",
    monument: "Golden Temple",
    facts: [
      "The Golden Temple in Amritsar serves free food to over 100,000 people daily.",
      "Punjab is called the 'Granary of India' for its huge wheat production.",
    ],
    mapPosition: Offset(0.32, 0.09),
    region: "North India",
  ),

  IndiaState(
    name: "Himachal Pradesh",
    capital: "Shimla",
    food: "Dham (Chana dal rice)",
    language: "Hindi, Pahari",
    monument: "Kullu Valley",
    facts: [
      "Himachal Pradesh is known as the 'Land of Gods' due to its many temples.",
      "The Kalka-Shimla railway is a UNESCO World Heritage Site.",
    ],
    mapPosition: Offset(0.38, 0.09),
    region: "North India",
  ),

  IndiaState(
    name: "Uttarakhand",
    capital: "Dehradun",
    food: "Kafuli",
    language: "Hindi, Garhwali",
    monument: "Kedarnath Temple",
    facts: [
      "Uttarakhand is home to the Char Dham, four sacred pilgrimage sites.",
      "Jim Corbett National Park, India's oldest national park, is here.",
    ],
    mapPosition: Offset(0.44, 0.09),
    region: "North India",
  ),

  IndiaState(
    name: "Haryana",
    capital: "Chandigarh",
    food: "Kadhi Pakora",
    language: "Haryanvi",
    monument: "Sultanpur Bird Sanctuary",
    facts: [
      "Haryana is famous for its wrestling culture in Akharas.",
      "The land of the Mahabharata's Kurukshetra is in Haryana.",
    ],
    mapPosition: Offset(0.35, 0.14),
    region: "North India",
  ),

  IndiaState(
    name: "Delhi",
    capital: "New Delhi",
    food: "Chaat & Chole Bhature",
    language: "Hindi, English",
    monument: "India Gate",
    facts: [
      "Delhi has been the capital of many empires for over 1000 years.",
      "Qutub Minar, the tallest brick minaret in the world, is here.",
    ],
    mapPosition: Offset(0.38, 0.16),
    region: "North India",
  ),

  IndiaState(
    name: "Rajasthan",
    capital: "Jaipur",
    food: "Dal Baati Churma",
    language: "Hindi, Marwari",
    monument: "Hawa Mahal",
    facts: [
      "Rajasthan is home to the Thar Desert, one of the largest deserts in the world.",
      "The Pink City Jaipur is a UNESCO World Heritage Site.",
    ],
    mapPosition: Offset(0.25, 0.18),
    region: "West India",
  ),

  IndiaState(
    name: "Uttar Pradesh",
    capital: "Lucknow",
    food: "Tunday Kebab",
    language: "Hindi",
    monument: "Taj Mahal",
    facts: [
      "The Taj Mahal in Agra is one of the Seven Wonders of the World.",
      "Uttar Pradesh is India's most populous state.",
    ],
    mapPosition: Offset(0.40, 0.19),
    region: "North India",
  ),

  // ============================
  // WEST INDIA
  // ============================

  IndiaState(
    name: "Gujarat",
    capital: "Gandhinagar",
    food: "Dhokla",
    language: "Gujarati",
    monument: "Statue of Unity",
    facts: [
      "The Statue of Unity is the world's tallest statue at 182 meters.",
      "Gujarat has the longest coastline in India at 1600 km.",
    ],
    mapPosition: Offset(0.18, 0.25),
    region: "West India",
  ),

  IndiaState(
    name: "Goa",
    capital: "Panaji",
    food: "Fish Curry Rice",
    language: "Konkani",
    monument: "Basilica of Bom Jesus",
    facts: [
      "Goa is India's smallest state by area.",
      "It was a Portuguese colony for over 450 years.",
    ],
    mapPosition: Offset(0.24, 0.46),
    region: "West India",
  ),

  IndiaState(
    name: "Maharashtra",
    capital: "Mumbai",
    food: "Vada Pav",
    language: "Marathi",
    monument: "Gateway of India",
    facts: [
      "Mumbai is the financial capital of India.",
      "The Bollywood film industry is based in Mumbai.",
    ],
    mapPosition: Offset(0.25, 0.38),
    region: "West India",
  ),

  // ============================
  // CENTRAL INDIA
  // ============================

  IndiaState(
    name: "Madhya Pradesh",
    capital: "Bhopal",
    food: "Poha Jalebi",
    language: "Hindi",
    monument: "Khajuraho Temples",
    facts: [
      "Khajuraho temples are famous for their intricate sculptures.",
      "The Kanha National Park inspired Rudyard Kipling's 'Jungle Book'.",
    ],
    mapPosition: Offset(0.32, 0.29),
    region: "Central India",
  ),

  IndiaState(
    name: "Chhattisgarh",
    capital: "Raipur",
    food: "Chila",
    language: "Chhattisgarhi",
    monument: "Chitrakote Falls",
    facts: [
      "Chitrakote Falls is called the 'Niagara Falls of India'.",
      "Chhattisgarh is rich in waterfalls, caves and forests.",
    ],
    mapPosition: Offset(0.42, 0.31),
    region: "Central India",
  ),

  // ============================
  // EAST INDIA
  // ============================

  IndiaState(
    name: "Bihar",
    capital: "Patna",
    food: "Litti Chokha",
    language: "Hindi, Bhojpuri",
    monument: "Mahabodhi Temple",
    facts: [
      "Bodh Gaya in Bihar is where Buddha attained enlightenment.",
      "Nalanda University, one of the world's oldest, is here.",
    ],
    mapPosition: Offset(0.48, 0.22),
    region: "East India",
  ),

  IndiaState(
    name: "Jharkhand",
    capital: "Ranchi",
    food: "Dhuska",
    language: "Hindi",
    monument: "Dassam Falls",
    facts: [
      "Jharkhand is called the 'Land of Forests' with 29% forest cover.",
      "Dhanbad is the coal capital of India.",
    ],
    mapPosition: Offset(0.50, 0.29),
    region: "East India",
  ),

  IndiaState(
    name: "West Bengal",
    capital: "Kolkata",
    food: "Rasgulla & Fish Curry",
    language: "Bengali",
    monument: "Victoria Memorial",
    facts: [
      "Kolkata was the capital of British India until 1911.",
      "The Sundarbans, world's largest mangrove forest, is here.",
    ],
    mapPosition: Offset(0.54, 0.32),
    region: "East India",
  ),

  IndiaState(
    name: "Odisha",
    capital: "Bhubaneswar",
    food: "Pakhala Bhata",
    language: "Odia",
    monument: "Konark Sun Temple",
    facts: [
      "The Konark Sun Temple is designed as a giant chariot.",
      "Puri's Ratha Yatra attracts millions of devotees every year.",
    ],
    mapPosition: Offset(0.48, 0.37),
    region: "East India",
  ),

  // ============================
  // NORTH-EAST INDIA
  // ============================

  IndiaState(
    name: "Sikkim",
    capital: "Gangtok",
    food: "Thukpa (Noodle Soup)",
    language: "Nepali, Sikkimese",
    monument: "Tsomgo Lake",
    facts: [
      "Sikkim is India's first fully organic state.",
      "Kangchenjunga, the third-highest mountain, is here.",
    ],
    mapPosition: Offset(0.56, 0.20),
    region: "North-East India",
  ),

  IndiaState(
    name: "Assam",
    capital: "Dispur",
    food: "Assam Tea",
    language: "Assamese",
    monument: "Kaziranga National Park",
    facts: [
      "Kaziranga is home to two-thirds of the world's one-horned rhinos.",
      "Assam produces more than half of India's tea.",
    ],
    mapPosition: Offset(0.60, 0.23),
    region: "North-East India",
  ),

  IndiaState(
    name: "Meghalaya",
    capital: "Shillong",
    food: "Jadoh (Spiced Rice)",
    language: "Khasi, Garo",
    monument: "Living Root Bridges",
    facts: [
      "Mawsynram in Meghalaya is the wettest place on Earth.",
      "Living root bridges are made from tree roots, growing for centuries.",
    ],
    mapPosition: Offset(0.58, 0.25),
    region: "North-East India",
  ),

  IndiaState(
    name: "Arunachal Pradesh",
    capital: "Itanagar",
    food: "Thukpa",
    language: "Monpa, Nyishi",
    monument: "Tawang Monastery",
    facts: [
      "Arunachal Pradesh is known as the 'Land of the Dawn-Lit Mountains'.",
      "Tawang Monastery is the largest monastery in India.",
    ],
    mapPosition: Offset(0.64, 0.16),
    region: "North-East India",
  ),

  IndiaState(
    name: "Nagaland",
    capital: "Kohima",
    food: "Smoked Pork with Bamboo Shoot",
    language: "English, Ao, Konyak",
    monument: "Kohima War Cemetery",
    facts: [
      "The Hornbill Festival showcases 16 major Naga tribes.",
      "Nagaland is known as the 'Land of Festivals'.",
    ],
    mapPosition: Offset(0.66, 0.20),
    region: "North-East India",
  ),

  IndiaState(
    name: "Manipur",
    capital: "Imphal",
    food: "Eromba",
    language: "Manipuri (Meitei)",
    monument: "Loktak Lake",
    facts: [
      "Loktak Lake has the world's only floating national park.",
      "Manipur is the birthplace of the polo game.",
    ],
    mapPosition: Offset(0.66, 0.24),
    region: "North-East India",
  ),

  IndiaState(
    name: "Mizoram",
    capital: "Aizawl",
    food: "Bai (Vegetable Stew)",
    language: "Mizo",
    monument: "Vantawng Falls",
    facts: [
      "Mizoram has the highest literacy rate in India after Kerala.",
      "The Blue Mountain is the highest peak in Mizoram.",
    ],
    mapPosition: Offset(0.64, 0.29),
    region: "North-East India",
  ),

  IndiaState(
    name: "Tripura",
    capital: "Agartala",
    food: "Mui Borok",
    language: "Kokborok, Bengali",
    monument: "Ujjayanta Palace",
    facts: [
      "The Ujjayanta Palace is a stunning royal palace in Agartala.",
      "Tripura has the largest Buddhist circuit in the north-east.",
    ],
    mapPosition: Offset(0.60, 0.29),
    region: "North-East India",
  ),

  // ============================
  // SOUTH INDIA
  // ============================

  IndiaState(
    name: "Karnataka",
    capital: "Bengaluru",
    food: "Bisi Bele Bath",
    language: "Kannada",
    monument: "Hampi Ruins",
    facts: [
      "Bengaluru is known as the 'Silicon Valley of India'.",
      "Hampi was the capital of the mighty Vijayanagara Empire.",
    ],
    mapPosition: Offset(0.30, 0.48),
    region: "South India",
  ),

  IndiaState(
    name: "Kerala",
    capital: "Thiruvananthapuram",
    food: "Appam & Ishtew",
    language: "Malayalam",
    monument: "Alleppey Backwaters",
    facts: [
      "Kerala is known as 'God's Own Country' for its tropical beauty.",
      "It achieved 100% literacy in the early 1990s.",
    ],
    mapPosition: Offset(0.32, 0.60),
    region: "South India",
  ),

  IndiaState(
    name: "Tamil Nadu",
    capital: "Chennai",
    food: "Dosa & Sambhar",
    language: "Tamil",
    monument: "Meenakshi Temple",
    facts: [
      "Tamil is one of the oldest surviving classical languages.",
      "Rameswaram sits close to the southernmost tip of India.",
    ],
    mapPosition: Offset(0.38, 0.55),
    region: "South India",
  ),

  IndiaState(
    name: "Andhra Pradesh",
    capital: "Amaravati",
    food: "Gongura Pachadi",
    language: "Telugu",
    monument: "Tirupati Balaji Temple",
    facts: [
      "Tirupati Balaji is the richest and most visited temple in the world.",
      "Andhra Pradesh is known as the 'Rice Bowl of India'.",
    ],
    mapPosition: Offset(0.36, 0.43),
    region: "South India",
  ),

  IndiaState(
    name: "Telangana",
    capital: "Hyderabad",
    food: "Hyderabadi Biryani",
    language: "Telugu, Urdu",
    monument: "Charminar",
    facts: [
      "The Charminar was built in 1591 to mark the end of a plague.",
      "Hyderabad is a global hub for IT and pharma industries.",
    ],
    mapPosition: Offset(0.34, 0.39),
    region: "South India",
  ),

  // ============================
  // HERITAGE TRAIL
  // ============================

  IndiaState(
    name: "Mumbai",
    capital: "Maharashtra",
    food: "Vada Pav",
    language: "Marathi",
    monument: "Gateway of India",
    facts: [
      "Mumbai is the dream city of millions of Indians.",
      "The Gateway of India was built to mark King George V's visit.",
    ],
    mapPosition: Offset(0.23, 0.38),
    region: "Heritage Trail",
  ),

  IndiaState(
    name: "Jaipur",
    capital: "Rajasthan",
    food: "Ghevar",
    language: "Hindi",
    monument: "Amber Fort",
    facts: [
      "Jaipur is known as the 'Pink City' for its pink-coloured buildings.",
      "It is part of India's 'Golden Triangle' tourist circuit.",
    ],
    mapPosition: Offset(0.23, 0.16),
    region: "Heritage Trail",
  ),

  IndiaState(
    name: "Agra",
    capital: "Uttar Pradesh",
    food: "Petha Sweets",
    language: "Hindi",
    monument: "Taj Mahal",
    facts: [
      "The Taj Mahal was built by Emperor Shah Jahan for his wife Mumtaz.",
      "Agra Fort is another UNESCO World Heritage Site.",
    ],
    mapPosition: Offset(0.38, 0.18),
    region: "Heritage Trail",
  ),

  IndiaState(
    name: "Kolkata",
    capital: "West Bengal",
    food: "Mishti Doi",
    language: "Bengali",
    monument: "Howrah Bridge",
    facts: [
      "Kolkata is known as the 'City of Joy'.",
      "It was the first capital of British India.",
    ],
    mapPosition: Offset(0.55, 0.33),
    region: "Heritage Trail",
  ),
];

List<IndiaState> statesByRegion(String region) {
  return indiaStates.where((s) => s.region == region).toList();
}