class Question {
  final String state;
  final String category;
  final String question;
  final List<String> options;
  final int answer;

  const Question({
    required this.state,
    required this.category,
    required this.question,
    required this.options,
    required this.answer,
  });
}