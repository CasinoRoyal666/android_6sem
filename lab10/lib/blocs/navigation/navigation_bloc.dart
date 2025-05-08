import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationState(currentPageIndex: 0)) {
    on<NavigateToPageEvent>(_onNavigateToPage);
  }

  FutureOr<void> _onNavigateToPage(
      NavigateToPageEvent event,
      Emitter<NavigationState> emit
      ) {
    emit(NavigationState(currentPageIndex: event.pageIndex));
  }
}