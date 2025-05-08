import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<FetchNextClassEvent>(_onFetchNextClass);
  }

  FutureOr<void> _onFetchNextClass(
      FetchNextClassEvent event,
      Emitter<DashboardState> emit
      ) async {
    emit(DashboardLoading());

    try {
      final nextClass = await repository.getNextClass();
      emit(DashboardLoaded(nextClass: nextClass));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}