import '../../models/class_info.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final ClassInfo nextClass;

  DashboardLoaded({required this.nextClass});
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});
}