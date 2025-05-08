import '../../models/activity.dart';

abstract class LearningHubState {}

class LearningHubInitial extends LearningHubState {}

class LearningHubLoading extends LearningHubState {}

class LearningHubLoaded extends LearningHubState {
  final List<Activity> activities;

  LearningHubLoaded({required this.activities});
}

class LearningHubError extends LearningHubState {
  final String message;

  LearningHubError({required this.message});
}