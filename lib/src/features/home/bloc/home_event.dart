abstract class HomeEvent {}

class HomeLoadMedications extends HomeEvent {}

class HomeRefreshMedications extends HomeEvent {}

class HomeDeleteMedication extends HomeEvent {
  final String medicationId;

  HomeDeleteMedication(this.medicationId);
}
