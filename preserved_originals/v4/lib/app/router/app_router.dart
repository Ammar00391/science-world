import 'package:go_router/go_router.dart';
import '../../features/questions/presentation/question_detail_page.dart' as question_detail_page;
import '../../features/splash/presentation/splash_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/grades/presentation/grades_page.dart';
import '../../features/grades/presentation/grade_selection_page.dart';
import '../../features/subjects/presentation/subjects_page.dart';
import '../../features/lessons/presentation/lessons_page.dart';
import '../../features/lessons/presentation/lesson_detail_page.dart';
import '../../features/library/presentation/library_page.dart';
import '../../features/library/presentation/book_list_page.dart';
import '../../features/pdf/presentation/pdf_reader_page.dart';
import '../../features/quiz/presentation/quiz_bank_page.dart';
import '../../features/test/presentation/test_page.dart';
import '../../features/result/presentation/result_page.dart';
import '../../features/review/presentation/review_page.dart';
import '../../features/downloads/presentation/downloads_page.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/subscription/presentation/subscription_plans_page.dart';
import '../../features/subscription/presentation/activation_code_page.dart';
import '../../features/subscription/presentation/subscription_status_page.dart';
import '../../features/subscription/presentation/payment_help_page.dart';
import '../../features/subscription/presentation/subscription_result_page.dart';
import '../../features/assistant/presentation/assistant_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/student_progress_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/help/presentation/help_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/auth/presentation/verify_page.dart';
import '../../features/auth/presentation/reset_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/grades', builder: (_, __) => const GradesPage()),
    GoRoute(path: '/grade-selection', builder: (_, __) => const GradeSelectionPage()),
    GoRoute(path: '/subjects', builder: (_, __) => const SubjectsPage()),
    GoRoute(path: '/lessons', builder: (_, __) => const LessonsPage()),
    GoRoute(path: '/lesson-detail', builder: (_, __) => const LessonDetailPage()),
    GoRoute(path: '/library', builder: (_, __) => const LibraryPage()),
    GoRoute(path: '/books', builder: (_, __) => const BookListPage()),
    GoRoute(path: '/pdf-reader', builder: (_, __) => const PdfReaderPage()),
    GoRoute(path: '/quiz-bank', builder: (_, __) => const QuizBankPage()),
    GoRoute(
      path: '/question-detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return question_detail_page.QuestionDetailPage(questionId: id);
      },
    ),
    GoRoute(
      path: '/question-detail',
      builder: (_, __) => const question_detail_page.QuestionDetailPage(questionId: ''),
    ),
    GoRoute(path: '/test', builder: (_, __) => const TestPage()),
    GoRoute(path: '/result', builder: (_, __) => const ResultPage()),
    GoRoute(path: '/review', builder: (_, __) => const ReviewPage()),
    GoRoute(path: '/downloads', builder: (_, __) => const DownloadsPage()),
    GoRoute(path: '/favorites', builder: (_, __) => const FavoritesPage()),
    GoRoute(path: '/subscription-plans', builder: (_, __) => const SubscriptionPlansPage()),
    GoRoute(path: '/activate', builder: (_, __) => const ActivationCodePage()),
    GoRoute(path: '/subscription-status', builder: (_, __) => const SubscriptionStatusPage()),
    GoRoute(path: '/payment-help', builder: (_, __) => const PaymentHelpPage()),
    GoRoute(
      path: '/subscription-result',
      builder: (context, state) => SubscriptionResultPage(),
    ),
    GoRoute(path: '/assistant', builder: (_, __) => const AssistantPage()),
    GoRoute(path: '/progress', builder: (_, __) => const StudentProgressPage()),
    GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
    GoRoute(path: '/help', builder: (_, __) => const HelpPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
    GoRoute(path: '/verify', builder: (_, __) => const VerifyPage()),
    GoRoute(path: '/reset', builder: (_, __) => const ResetPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
  ],
);