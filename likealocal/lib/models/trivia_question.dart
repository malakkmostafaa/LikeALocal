class TriviaQuestion {
  TriviaQuestion({
    required this.text,
    required this.choices,
    required this.correctIndex,
  });

  final String text;
  final List<String> choices;
  final int correctIndex;

  factory TriviaQuestion.fromMap(Map<String, dynamic> map) {
    return TriviaQuestion(
      text: (map['text'] ?? '').toString(),
      choices: List<String>.from(map['choices'] ?? const []),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'choices': choices,
      'correctIndex': correctIndex,
    };
  }
}
