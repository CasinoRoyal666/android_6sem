import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/dashboard/dashboard_event.dart';
import 'blocs/learning_hub/learning_hub_bloc.dart';
import 'blocs/learning_hub/learning_hub_event.dart';
import 'blocs/navigation/navigation_bloc.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/learning_hub_repository.dart';
import 'ui/screens/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => DashboardRepository()),
        RepositoryProvider(create: (context) => LearningHubRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => NavigationBloc(),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              repository: context.read<DashboardRepository>(),
            )..add(FetchNextClassEvent()),
          ),
          BlocProvider(
            create: (context) => LearningHubBloc(
              repository: context.read<LearningHubRepository>(),
            )..add(FetchTodayActivitiesEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'Student Dashboard',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            fontFamily: 'Arial',
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}