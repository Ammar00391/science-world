import 'question_model.dart';
import 'question_repository.dart';

class QuestionService {
  final QuestionRepository _repo;

  QuestionService({QuestionRepository? repository})
      : _repo = repository ?? QuestionRepository();

  Future<List<QuestionModel>> getQuestions({
    String? grade,
    String? subject,
    String? type,
    String? difficulty,
    bool onlyFree = true,
  }) async {
    return _repo.fetchAll(
      grade: grade,
      subject: subject,
      type: type,
      difficulty: difficulty,
      onlyFree: onlyFree,
    );
  }

  Future<List<QuestionModel>> fetchQuestions({
    String? grade,
    String? subject,
    String? type,
    String? difficulty,
    bool onlyFree = true,
  }) {
    return getQuestions(
      grade: grade,
      subject: subject,
      type: type,
      difficulty: difficulty,
      onlyFree: onlyFree,
    );
  }

  Future<QuestionModel> getById(String id) async {
    return _repo.fetchById(id);
  }

  Future<QuestionModel> fetchQuestionById(String id) {
    return getById(id);
  }

  Future<QuestionAnswerResult> checkAnswer({
    required QuestionModel question,
    required String selectedAnswer,
  }) {
    return _repo.checkAnswer(
      question: question,
      selectedAnswer: selectedAnswer,
    );
  }

  Future<void> upsert(QuestionModel question) async {
    await _repo.upsert(question);
  }
}
