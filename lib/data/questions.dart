import '../models/question.dart';

final List<Question> allQuestions = [
  // ===========================
  // SOUTH INDIA
  // ===========================

  Question(
    state: "Tamil Nadu",
    category: "Capital",
    question: "What is the capital of Tamil Nadu?",
    options: ["Chennai", "Coimbatore", "Madurai", "Salem"],
    answer: 0,
  ),
  Question(
    state: "Tamil Nadu",
    category: "Food",
    question: "Which breakfast is most famous in Tamil Nadu?",
    options: ["Dosa", "Dhokla", "Litti Chokha", "Momos"],
    answer: 0,
  ),
  Question(
    state: "Kerala",
    category: "Monument",
    question: "Kerala's famous backwaters are in which city?",
    options: ["Kochi", "Alleppey", "Thrissur", "Kozhikode"],
    answer: 1,
  ),
  Question(
    state: "Kerala",
    category: "Food",
    question: "Which dish is a Kerala breakfast favourite?",
    options: ["Appam", "Dhokla", "Biryani", "Kachori"],
    answer: 0,
  ),
  Question(
    state: "Karnataka",
    category: "Monument",
    question: "The ancient Hampi ruins are in which state?",
    options: ["Karnataka", "Tamil Nadu", "Telangana", "Goa"],
    answer: 0,
  ),
  Question(
    state: "Telangana",
    category: "Monument",
    question: "The Charminar is located in which city?",
    options: ["Hyderabad", "Bengaluru", "Chennai", "Vijayawada"],
    answer: 0,
  ),

  // ===========================
  // WEST INDIA
  // ===========================

  Question(
    state: "Maharashtra",
    category: "Capital",
    question: "What is the capital of Maharashtra?",
    options: ["Mumbai", "Pune", "Nagpur", "Nashik"],
    answer: 0,
  ),
  Question(
    state: "Maharashtra",
    category: "Food",
    question: "Which snack is famous in Maharashtra?",
    options: ["Vada Pav", "Dhokla", "Litti Chokha", "Momos"],
    answer: 0,
  ),
  Question(
    state: "Maharashtra",
    category: "Monument",
    question: "Gateway of India is located in?",
    options: ["Pune", "Mumbai", "Nagpur", "Kolhapur"],
    answer: 1,
  ),
  Question(
    state: "Gujarat",
    category: "Capital",
    question: "What is the capital of Gujarat?",
    options: ["Ahmedabad", "Rajkot", "Gandhinagar", "Surat"],
    answer: 2,
  ),
  Question(
    state: "Gujarat",
    category: "Food",
    question: "Which food is famous in Gujarat?",
    options: ["Dhokla", "Biryani", "Idli", "Poha"],
    answer: 0,
  ),
  Question(
    state: "Gujarat",
    category: "Monument",
    question: "Statue of Unity is in which state?",
    options: ["Maharashtra", "Gujarat", "Punjab", "Kerala"],
    answer: 1,
  ),
  Question(
    state: "Goa",
    category: "Food",
    question: "Which dish is a Goa speciality?",
    options: ["Fish Curry Rice", "Dhokla", "Kadhi", "Momos"],
    answer: 0,
  ),
  Question(
    state: "Rajasthan",
    category: "Monument",
    question: "Hawa Mahal is located in which city?",
    options: ["Jaipur", "Udaipur", "Jodhpur", "Bikaner"],
    answer: 0,
  ),

  // ===========================
  // NORTH INDIA
  // ===========================

  Question(
    state: "Uttar Pradesh",
    category: "Monument",
    question: "The Taj Mahal is located in which city?",
    options: ["Lucknow", "Agra", "Varanasi", "Kanpur"],
    answer: 1,
  ),
  Question(
    state: "Punjab",
    category: "Monument",
    question: "The Golden Temple is in which city?",
    options: ["Amritsar", "Ludhiana", "Patiala", "Jalandhar"],
    answer: 0,
  ),
  Question(
    state: "Delhi",
    category: "Monument",
    question: "India Gate is located in?",
    options: ["New Delhi", "Mumbai", "Kolkata", "Chennai"],
    answer: 0,
  ),

  // ===========================
  // EAST INDIA
  // ===========================

  Question(
    state: "West Bengal",
    category: "Monument",
    question: "Victoria Memorial is in which city?",
    options: ["Kolkata", "Darjeeling", "Howrah", "Siliguri"],
    answer: 0,
  ),
  Question(
    state: "Odisha",
    category: "Monument",
    question: "The Konark Sun Temple is in which state?",
    options: ["Odisha", "Bihar", "Andhra Pradesh", "Rajasthan"],
    answer: 0,
  ),
  Question(
    state: "Bihar",
    category: "Monument",
    question: "Where did Buddha attain enlightenment?",
    options: ["Bodh Gaya", "Patna", "Gaya", "Rajgir"],
    answer: 0,
  ),

  // ===========================
  // NORTH-EAST INDIA
  // ===========================

  Question(
    state: "Assam",
    category: "Monument",
    question: "The one-horned rhino is protected in which park?",
    options: ["Kaziranga", "Jim Corbett", "Bandipur", "Sundarbans"],
    answer: 0,
  ),
  Question(
    state: "Assam",
    category: "Food",
    question: "Which world-famous beverage is grown in Assam?",
    options: ["Tea", "Coffee", "Cocoa", "Sugarcane"],
    answer: 0,
  ),
  Question(
    state: "Meghalaya",
    category: "Monument",
    question: "Meghalaya's famous Living Root Bridges are made from?",
    options: ["Tree Roots", "Bamboo", "Stone", "Wood"],
    answer: 0,
  ),

  // ===========================
  // HERITAGE TRAIL
  // ===========================

  Question(
    state: "Jaipur",
    category: "Monument",
    question: "Jaipur is also known as the?",
    options: ["Pink City", "Blue City", "Green City", "Golden City"],
    answer: 0,
  ),
  Question(
    state: "Agra",
    category: "Monument",
    question: "Who built the Taj Mahal?",
    options: ["Shah Jahan", "Akbar", "Aurangzeb", "Humayun"],
    answer: 0,
  ),
  Question(
    state: "Kolkata",
    category: "Food",
    question: "Mishti Doi is a famous sweet from which city?",
    options: ["Kolkata", "Mumbai", "Chennai", "Delhi"],
    answer: 0,
  ),

  // ===========================
  // MIXED KNOWLEDGE
  // ===========================

  Question(
    state: "India",
    category: "General",
    question: "How many states does India have?",
    options: ["28", "27", "29", "25"],
    answer: 0,
  ),
  Question(
    state: "India",
    category: "General",
    question: "Which is the national animal of India?",
    options: ["Tiger", "Lion", "Elephant", "Leopard"],
    answer: 0,
  ),
  Question(
    state: "India",
    category: "General",
    question: "Which is the national bird of India?",
    options: ["Peacock", "Parrot", "Sparrow", "Crow"],
    answer: 0,
  ),
  Question(
    state: "India",
    category: "General",
    question: "What is the national flower of India?",
    options: ["Lotus", "Rose", "Lily", "Sunflower"],
    answer: 0,
  ),
  Question(
    state: "India",
    category: "General",
    question: "Which is India's national fruit?",
    options: ["Mango", "Banana", "Apple", "Orange"],
    answer: 0,
  ),

  // ===========================
  // EXTENDED POOL — one more per quiz tile so revisits stay fresh
  // ===========================

  Question(
    state: "Karnataka",
    category: "Capital",
    question: "Which city is the capital of Karnataka?",
    options: ["Bengaluru", "Mysuru", "Hubballi", "Mangaluru"],
    answer: 0,
  ),
  Question(
    state: "Karnataka",
    category: "Dance",
    question: "Which folk theatre is famously associated with Karnataka?",
    options: ["Yakshagana", "Garba", "Bhangra", "Odissi"],
    answer: 0,
  ),
  Question(
    state: "Telangana",
    category: "Festival",
    question: "Bathukamma is a flower festival of which state?",
    options: ["Telangana", "Kerala", "Punjab", "Goa"],
    answer: 0,
  ),
  Question(
    state: "Telangana",
    category: "Language",
    question: "Telugu is the official language of which state?",
    options: ["Telangana", "Tamil Nadu", "Maharashtra", "Odisha"],
    answer: 0,
  ),
  Question(
    state: "Goa",
    category: "Language",
    question: "Konkani is the official language of which state?",
    options: ["Goa", "Bihar", "Assam", "Punjab"],
    answer: 0,
  ),
  Question(
    state: "Goa",
    category: "Festival",
    question: "Which state hosts a famous Carnival parade every year?",
    options: ["Goa", "Rajasthan", "Sikkim", "Meghalaya"],
    answer: 0,
  ),
  Question(
    state: "Rajasthan",
    category: "Food",
    question: "Dal Baati Churma is a signature dish of which state?",
    options: ["Rajasthan", "Odisha", "Kerala", "Assam"],
    answer: 0,
  ),
  Question(
    state: "Rajasthan",
    category: "Dance",
    question: "The Ghoomar folk dance belongs to which state?",
    options: ["Rajasthan", "Gujarat", "Punjab", "Manipur"],
    answer: 0,
  ),
  Question(
    state: "Uttar Pradesh",
    category: "River",
    question: "The holy city of Varanasi lies on which river?",
    options: ["Ganga", "Yamuna", "Brahmaputra", "Godavari"],
    answer: 0,
  ),
  Question(
    state: "Uttar Pradesh",
    category: "History",
    question: "Prayagraj, host of the grand Kumbh Mela, is in which state?",
    options: ["Uttar Pradesh", "Bihar", "Madhya Pradesh", "Haryana"],
    answer: 0,
  ),
  Question(
    state: "Punjab",
    category: "Dance",
    question: "Bhangra is the energetic folk dance of which state?",
    options: ["Punjab", "Gujarat", "Assam", "Kerala"],
    answer: 0,
  ),
  Question(
    state: "Punjab",
    category: "Food",
    question: "Sarson da Saag and Makki di Roti are traditional foods of which state?",
    options: ["Punjab", "Rajasthan", "West Bengal", "Tamil Nadu"],
    answer: 0,
  ),
  Question(
    state: "Delhi",
    category: "Monument",
    question: "The Red Fort is located in which city?",
    options: ["Delhi", "Agra", "Lucknow", "Jaipur"],
    answer: 0,
  ),
  Question(
    state: "Delhi",
    category: "Monument",
    question: "The Qutub Minar stands in which city?",
    options: ["Delhi", "Mumbai", "Hyderabad", "Bhopal"],
    answer: 0,
  ),
  Question(
    state: "West Bengal",
    category: "Festival",
    question: "Durga Puja is celebrated with the greatest grandeur in which city?",
    options: ["Kolkata", "Mumbai", "Chennai", "Varanasi"],
    answer: 0,
  ),
  Question(
    state: "West Bengal",
    category: "Food",
    question: "Rosogolla, a soft syrupy sweet, originated in which state?",
    options: ["West Bengal", "Odisha", "Rajasthan", "Karnataka"],
    answer: 0,
  ),
  Question(
    state: "Odisha",
    category: "Dance",
    question: "Odissi is the classical dance of which state?",
    options: ["Odisha", "Tamil Nadu", "Kerala", "Assam"],
    answer: 0,
  ),
  Question(
    state: "Odisha",
    category: "Festival",
    question: "The Rath Yatra at Puri is celebrated in which state?",
    options: ["Odisha", "Bihar", "Uttar Pradesh", "Madhya Pradesh"],
    answer: 0,
  ),
  Question(
    state: "Bihar",
    category: "Food",
    question: "Litti Chokha is the traditional food of which state?",
    options: ["Bihar", "Punjab", "Goa", "Kerala"],
    answer: 0,
  ),
  Question(
    state: "Bihar",
    category: "Festival",
    question: "Chhath Puja, honouring the Sun God, is most closely linked to which state?",
    options: ["Bihar", "Assam", "Kerala", "Gujarat"],
    answer: 0,
  ),
];