import '../models/question.dart';
import 'india_states_data.dart';
import 'journeys_data.dart';

/// Quiz banks for the State Selection adventure.
///
/// Every playable state gets EXACTLY 15 questions built from its own real
/// data (capital, famous food, language, landmark and hand-picked trivia),
/// with distractors drawn from OTHER states' data for believable options.
/// The 🇮🇳 India Challenge mixes one big pool from every state's bank.
///
/// Banks are deterministic — the same build order and fixed math produce the
/// same question set on every run, so saves, tests and memory usage are all
/// stable.

/// Four short, accurate trivia lines per state used to fill the True/False
/// slots. Kept deliberately factual and colloquial for younger explorers.
const Map<String, List<String>> stateTrivia = {
  "Andhra Pradesh": [
    "The Tirupati temple is one of the richest temples in the world.",
    "Andhra Pradesh is one of India's biggest producers of chilli.",
    "Kuchipudi, a famous classical dance, comes from Andhra Pradesh.",
    "The Krishna and Godavari rivers flow through Andhra Pradesh.",
  ],
  "Arunachal Pradesh": [
    "Arunachal Pradesh is called the 'Land of the Rising Sun'.",
    "It is the easternmost state of India and sees the very first sunrise.",
    "The Tawang Monastery is one of the largest monasteries in the world.",
    "Snow leopards live in the high mountain valleys of Arunachal Pradesh.",
  ],
  "Assam": [
    "Assam is one of the world's largest tea-growing regions.",
    "The one-horned rhino of Kaziranga lives in Assam.",
    "Assam is famous for the golden silk called Muga.",
    "The mighty Brahmaputra River flows through Assam.",
  ],
  "Bihar": [
    "Bodh Gaya in Bihar is where Buddha attained enlightenment.",
    "The ancient university of Nalanda once stood in Bihar.",
    "The Mahatma Gandhi Setu, one of India's longest bridges, is in Bihar.",
    "The great festival of Chhath Puja is celebrated across Bihar.",
  ],
  "Chhattisgarh": [
    "Chhattisgarh has one of the largest tribal populations in India.",
    "Chitrakote Waterfall in Chhattisgarh is called the Niagara of India.",
    "Chhattisgarh is rich in forests and minerals like iron and coal.",
    "Chhattisgarh is known as the 'Rice Bowl of India'.",
  ],
  "Goa": [
    "Goa was a Portuguese colony for more than 450 years.",
    "Goa is famous for its beaches and colourful carnivals.",
    "The Basilica of Bom Jesus in Goa holds the tomb of St. Francis Xavier.",
    "Goa is the smallest state of India by area.",
  ],
  "Gujarat": [
    "Gujarat is the birthplace of Mahatma Gandhi.",
    "The white salt desert of Kutch lies in Gujarat.",
    "The last Asiatic lions in the wild live in the Gir Forest of Gujarat.",
    "The Statue of Unity, the world's tallest statue, stands in Gujarat.",
  ],
  "Haryana": [
    "The great Mahabharata battle was fought at Kurukshetra in Haryana.",
    "Haryana is called the 'Milk Pail of India' for its dairy farms.",
    "Chandigarh is the shared capital of Punjab and Haryana.",
    "The city of Panipat, site of famous battles, lies in Haryana.",
  ],
  "Himachal Pradesh": [
    "Himachal Pradesh is known as 'Dev Bhoomi', the Land of Gods.",
    "Shimla in Himachal Pradesh was the summer capital of the British.",
    "The toy train of the Kalka-Shimla railway is a World Heritage Site.",
    "Himachal Pradesh is famous for its apples and hill stations.",
  ],
  "Jharkhand": [
    "Jharkhand holds some of India's biggest coal and iron reserves.",
    "The Chota Nagpur Plateau covers most of Jharkhand.",
    "The holy town of Deoghar in Jharkhand has the Baidyanath Temple.",
    "Jharkhand's Patratu Valley is dotted with beautiful waterfalls.",
  ],
  "Karnataka": [
    "Bengaluru, India's Silicon Valley, is in Karnataka.",
    "The ruins of Hampi in Karnataka are a World Heritage Site.",
    "Karnataka is a major producer of coffee and sandalwood.",
    "The grand Mysuru Dasara festival is held in Karnataka.",
  ],
  "Kerala": [
    "Kerala is lovingly called 'God's Own Country'.",
    "The famous backwaters of Alleppey are in Kerala.",
    "Kerala has one of the highest literacy rates in India.",
    "Kathakali and Mohiniyattam are classical dances of Kerala.",
  ],
  "Madhya Pradesh": [
    "The Khajuraho temples in Madhya Pradesh are a World Heritage Site.",
    "Kanha and Bandhavgarh national parks protect tigers in Madhya Pradesh.",
    "Madhya Pradesh lies in the very heart of India.",
    "The great Buddhist Stupa of Sanchi stands in Madhya Pradesh.",
  ],
  "Maharashtra": [
    "Mumbai is the capital of Maharashtra and India's film capital.",
    "The beautiful Ajanta and Ellora caves are in Maharashtra.",
    "Maharashtra is the second most populous state of India.",
    "The Shaniwarwada Fort stands in Pune, Maharashtra.",
  ],
  "Manipur": [
    "Manipur is famous for the graceful Manipuri dance.",
    "Loktak Lake in Manipur has floating islands called phumdis.",
    "Ancient polo, the game on horseback, began in Manipur.",
    "The Ima Keithel in Imphal is the world's largest all-women market.",
  ],
  "Meghalaya": [
    "Meghalaya is called the 'Abode of Clouds'.",
    "Mawsynram in Meghalaya is one of the wettest places on Earth.",
    "Meghalaya has living bridges that grow from tree roots.",
    "Shillong in Meghalaya is nicknamed the 'Scotland of the East'.",
  ],
  "Mizoram": [
    "Mizoram is one of the Seven Sisters of Northeast India.",
    "The colourful spring festival of Chapchar Kut is celebrated in Mizoram.",
    "Aizawl, the capital of Mizoram, sits high on a mountain ridge.",
    "Phawngpui, the highest peak of Mizoram, is called the Blue Mountain.",
  ],
  "Nagaland": [
    "Nagaland is called the 'Land of Festivals'.",
    "The Hornbill Festival is the biggest festival of Nagaland.",
    "Kohima in Nagaland is remembered for a great World War II battle.",
    "The people of Nagaland play the famous game of log drums.",
  ],
  "Odisha": [
    "The Sun Temple of Konark in Odisha is a World Heritage Site.",
    "The grand Rath Yatra of Puri is celebrated in Odisha.",
    "The classical Odissi dance comes from Odisha.",
    "Chilika Lake in Odisha is home to dolphins and migratory birds.",
  ],
  "Punjab": [
    "The Golden Temple at Amritsar in Punjab feeds thousands daily.",
    "Bhangra and Giddha are lively folk dances of Punjab.",
    "The exciting Wagah border ceremony takes place at Amritsar.",
    "Ludhiana in Punjab is known as the Manchester of India.",
  ],
  "Rajasthan": [
    "The Hawa Mahal in Jaipur is called the Palace of Winds.",
    "The great Thar Desert stretches across Rajasthan.",
    "The famous Pushkar Camel Fair is held in Rajasthan.",
    "The hill forts of Rajasthan are a World Heritage Site.",
  ],
  "Sikkim": [
    "Kanchenjunga, the world's third-highest peak, towers over Sikkim.",
    "Sikkim is India's first fully organic farming state.",
    "Gurudongmar Lake in Sikkim is one of the highest lakes on Earth.",
    "Nathu La is a mountain pass of Sikkim on the India-China border.",
  ],
  "Tamil Nadu": [
    "The Meenakshi Temple of Madurai is a famous Tamil Nadu landmark.",
    "Tamil Nadu is the home of the classical Bharatanatyam dance.",
    "Kumbakonam in Tamil Nadu is a city of ancient temples.",
    "The Brihadeeswarar Temple of Thanjavur is a World Heritage Site.",
  ],
  "Telangana": [
    "Hyderabad is called the City of Pearls.",
    "The Charminar was built in Hyderabad long ago in 1591.",
    "The mighty Golconda Fort stands in Telangana.",
    "Pochampally in Telangana is known for its ikat handloom.",
  ],
  "Tripura": [
    "The royal Ujjayanta Palace is a landmark of Tripura.",
    "Unakoti in Tripura holds giant rock carvings of Hindu gods.",
    "The Neermahal water palace sits in the middle of a lake in Tripura.",
    "Tripura is one of the smallest states of Northeast India.",
  ],
  "Uttar Pradesh": [
    "The Taj Mahal of Agra, in Uttar Pradesh, is a Wonder of the World.",
    "Varanasi, on the Ganges, is one of the world's oldest living cities.",
    "The giant Kumbh Mela is held at Prayagraj in Uttar Pradesh.",
    "Uttar Pradesh is the most populous state of India.",
  ],
  "Uttarakhand": [
    "Uttarakhand is called the 'Land of the Gods'.",
    "The holy shrines of Kedarnath and Badrinath lie in Uttarakhand.",
    "Jim Corbett National Park, India's oldest tiger reserve, is in Uttarakhand.",
    "The Ganges and Yamuna rivers rise in the mountains of Uttarakhand.",
  ],
  "West Bengal": [
    "The Sundarbans of West Bengal shelter the royal Bengal tiger.",
    "Darjeeling's hills in West Bengal grow famous teas.",
    "The great Howrah Bridge spans the Hooghly in Kolkata.",
    "Rabindranath Tagore's Santiniketan lies in West Bengal.",
  ],
};

final List<String> _capitalPool = [
  for (final s in indiaStates) s.capital,
];

final List<String> _foodPool = [
  for (final s in indiaStates) s.food,
];

final List<String> _stateNamesPool = [
  for (final s in playableStates) s.name,
];

/// Friendly fallback used only if a data pool is ever too small.
String _slotAt(List<String> pool, int seed, int slot) =>
    pool[(seed * 7 + slot * 11).abs() % pool.length];

List<String> _distinct(List<String> pool, Set<String> exclude, int seed, int n) {
  final out = <String>[];
  for (var slot = 0; out.length < n && slot < pool.length * 4; slot++) {
    final cand = _slotAt(pool, seed, slot);
    if (exclude.contains(cand) || out.contains(cand)) continue;
    out.add(cand);
  }
  // Blunt guarantee of `n` unique options even against a tiny pool.
  for (var i = 0; out.length < n; i++) {
    out.add("Option ${i + 1}");
  }
  return out;
}

List<String> _otherCapitals(String capital, int seed, int n) =>
    _distinct(_capitalPool, {capital}, seed, n);

List<String> _otherFoods(String food, int seed, int n) =>
    _distinct(_foodPool, {food}, seed, n);

List<String> _otherStates(String stateName, int seed, int n) =>
    _distinct(_stateNamesPool, {stateName}, seed, n);

/// Difficulty spread cycles per state so the "Difficulty" stars on cards are
/// not identical everywhere: 1★ states skew easy, 3★ states skew hard.
(int easy, int medium, int hard) _profile(int stateIndex) => switch (stateIndex % 3) {
      0 => (8, 6, 1),
      1 => (5, 5, 5),
      _ => (1, 6, 8),
    };

List<Question> _buildStateBank(IndiaState s, int stateIndex) {
  final name = s.name;
  final capital = s.capital;
  final food = s.food;
  final language = s.language;
  final monument = s.monument;
  final facts = s.facts.length >= 2
      ? [s.facts[0], s.facts[1]]
      : const <String>[];
  final trivia = stateTrivia[name] ?? const <String>[];
  const fallbackFacts = [
    "It is a colourful and historic state of India.",
    "It has delicious food and welcoming people.",
  ];
  final factPool = facts.length >= 2 ? facts : fallbackFacts;

  final profile = _profile(stateIndex);
  final used = <String>{};
  final questions = <Question>[];

  Question make({
    required String text,
    required List<String> options,
    required int answer,
    required int difficulty,
    String type = 'Multiple Choice',
  }) {
    var finalText = text;
    if (used.contains(finalText)) finalText = 'In $name, $finalText';
    used.add(finalText);
    return Question(
      state: name,
      category: name,
      type: type,
      difficulty: difficulty,
      question: finalText,
      options: options,
      answer: answer,
    );
  }

  // Slot difficulty is assigned by the state's profile so tier the board asks
  // for (by tile) always has a live pool.
  int slot = 0;
  int difficultyForSlot() {
    final d = slot < profile.$1
        ? 1
        : slot < profile.$1 + profile.$2
            ? 2
            : 3;
    slot++;
    return d;
  }

  // 1. Which city is the capital?
  {
    final distractors = _otherCapitals(capital, stateIndex + 1, 3);
    final insertAt = (stateIndex * 5) % 4;
    final options = List<String>.of(distractors)
      ..insert(insertAt, capital);
    questions.add(make(
      text: "What is the capital of $name?",
      options: options,
      answer: insertAt,
      difficulty: difficultyForSlot(),
    ));
  }

  // 2 + 3. True/False pair on the capital.
  questions.add(make(
    text: "$capital is the capital of $name.",
    options: const ["True", "False"],
    answer: 0,
    difficulty: difficultyForSlot(),
    type: 'True or False',
  ));
  questions.add(make(
    text: "${_otherCapitals(capital, stateIndex + 2, 1).first} is the capital of $name.",
    options: const ["True", "False"],
    answer: 1,
    difficulty: difficultyForSlot(),
    type: 'True or False',
  ));

  // 4. Famous dish → state. 5 + 6. True/False pair on food.
  {
    final distractors = _otherStates(name, stateIndex + 3, 3);
    final insertAt = (stateIndex + 1) % 4;
    final options = List<String>.of(distractors)..insert(insertAt, name);
    questions.add(make(
      text: "Which state is famous for the dish $food?",
      options: options,
      answer: insertAt,
      difficulty: difficultyForSlot(),
    ));
  }
  questions.add(make(
    text: "$food is a famous dish of $name.",
    options: const ["True", "False"],
    answer: 0,
    difficulty: difficultyForSlot(),
    type: 'True or False',
  ));
  questions.add(make(
    text: "${_otherFoods(food, stateIndex + 4, 1).first} is a famous dish of $name.",
    options: const ["True", "False"],
    answer: 1,
    difficulty: difficultyForSlot(),
    type: 'True or False',
  ));

  // 7. Language spoken. 8. Landmark location.
  {
    final backgrounds = _otherStates(name, stateIndex + 5, 3);
    final insertAt = (stateIndex + 2) % 4;
    final options = List<String>.of(backgrounds)..insert(insertAt, name);
    questions.add(make(
      text: "$language is one of the languages spoken where?",
      options: options,
      answer: insertAt,
      difficulty: difficultyForSlot(),
    ));
    final landmarks = _otherStates(name, stateIndex + 6, 3);
    final at = (stateIndex + 3) % 4;
    final opts = List<String>.of(landmarks)..insert(at, name);
    questions.add(make(
      text: "Where is the famous $monument located?",
      options: opts,
      answer: at,
      difficulty: difficultyForSlot(),
    ));
  }

  // 9. False landmark: the monument attributed to another state.
  questions.add(make(
    text: "The famous $monument monument lies in ${_otherStates(name, stateIndex + 7, 1).first}.",
    options: const ["True", "False"],
    answer: 1,
    difficulty: difficultyForSlot(),
    type: 'True or False',
  ));

  // 10 + 11. Facts from the state data.
  questions.add(make(
    text: factPool[0],
    options: const ["True", "False"],
    answer: 0,
    difficulty: difficultyForSlot(),
    type: 'True or False',
  ));
  questions.add(make(
    text: factPool[1],
    options: const ["True", "False"],
    answer: 0,
    difficulty: difficultyForSlot(),
    type: 'True or False',
  ));

  // 12–15. Hand-picked trivia as True/False.
  final triviaPool = trivia.length >= 4 ? trivia : fallbackFacts;
  for (var i = 0; i < 4; i++) {
    questions.add(make(
      text: triviaPool[i],
      options: const ["True", "False"],
      answer: 0,
      difficulty: difficultyForSlot(),
      type: 'True or False',
    ));
  }

  return questions;
}

/// Every playable state → its own 15-question bank.
final Map<String, List<Question>> stateQuestionBanks = _buildBanks();

Map<String, List<Question>> _buildBanks() {
  final banks = <String, List<Question>>{};
  for (var i = 0; i < playableStates.length; i++) {
    banks[playableStates[i].name] = _buildStateBank(playableStates[i], i);
  }
  return banks;
}

/// Always 15 for a playable state; 0 for anything else.
int stateQuestionCount(String stateName) =>
    stateQuestionBanks[stateName]?.length ?? 0;

/// Difficulty shown as stars on a state card (1–3) from its own bank.
int stateDifficulty(String stateName) {
  final qs = stateQuestionBanks[stateName];
  if (qs == null || qs.isEmpty) return 2;
  final avg = qs.fold<int>(0, (sum, q) => sum + q.difficulty) / qs.length;
  if (avg >= 2.2) return 3;
  if (avg >= 1.8) return 2;
  return 1;
}

/// Total questions across every state bank — the India Challenge pool size.
int get totalStateQuestions =>
    stateQuestionBanks.values.fold(0, (sum, qs) => sum + qs.length);

/// Every question from every state — the mixed 🇮🇳 INDIA CHALLENGE pool.
List<Question> get allStateBankQuestions =>
    [for (final bank in stateQuestionBanks.values) ...bank];