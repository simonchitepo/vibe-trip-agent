import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/plan/presentation/plan_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'plan',
          builder: (context, state) => const PlanScreen(),
        ),
      ],
    ),
  ],
);
