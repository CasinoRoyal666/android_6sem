import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/learning_hub_repository.dart';
import 'learning_hub_event.dart';
import 'learning_hub_state.dart';

class LearningHubBloc extends Bloc<LearningHubEvent, LearningHubState> {
  final LearningHubRepository repository;

  LearningHubBloc({required this.repository}) : super(LearningHubInitial()) {
    on<FetchTodayActivitiesEvent>(_onFetchTodayActivities);
  }

  FutureOr<void> _onFetchTodayActivities(
      FetchTodayActivitiesEvent event,
      Emitter<LearningHubState> emit
      ) async {
    emit(LearningHubLoading());

    try {
      final activities = await repository.getTodayActivities();
      emit(LearningHubLoaded(activities: activities));
    } catch (e) {
      emit(LearningHubError(message: e.toString()));
    }
  }
}