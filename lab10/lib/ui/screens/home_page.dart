import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/navigation/navigation_bloc.dart';
import '../../blocs/navigation/navigation_event.dart';
import '../../blocs/navigation/navigation_state.dart';
import 'dashboard_screen.dart';
import 'learning_hub_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: PageView(
              controller: PageController(initialPage: state.currentPageIndex),
              onPageChanged: (index) {
                context.read<NavigationBloc>().add(NavigateToPageEvent(index));
              },
              children: const [
                DashboardScreen(),
                LearningHubScreen(),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: state.currentPageIndex,
            onTap: (index) {
              context.read<NavigationBloc>().add(NavigateToPageEvent(index));
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Learning Hub',
              ),
            ],
          ),
        );
      },
    );
  }
}