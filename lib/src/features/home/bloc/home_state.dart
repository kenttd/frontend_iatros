import 'package:iatros/src/features/home/models/medication_model.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Medication> medications;
  final int totalMedications;
  final int todayDoses;
  final DateTime? nextDoseTime;

  HomeLoaded({
    required this.medications,
    required this.totalMedications,
    required this.todayDoses,
    this.nextDoseTime,
  });
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
