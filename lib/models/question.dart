class Question {
  final String state;
  final String category;
  final String question;
  final List<String> options;
  final int answer;

  /// Difficulty tier used by the board: 1 = easy, 2 = medium, 3 = hard.
  final int difficulty;

  /// Question flavour shown on the quiz card: "Multiple Choice",
  /// "True or False", "Odd One Out", "Riddle", "Complete the Sentence",
  /// "Capital City", "Guess the Monument", "Match the State".
  final String type;

  const Question({
    required this.state,
    required this.category,
    required this.question,
    required this.options,
    required this.answer,
    this.difficulty = 1,
    this.type = 'Multiple Choice',
  });
}