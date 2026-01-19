import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iatros/src/features/home/bloc/home_event.dart';
import 'package:iatros/src/features/home/bloc/home_state.dart';
import 'package:iatros/src/features/home/models/medication_model.dart';
import 'package:iatros/src/utils/api_client.dart';

import 'package:iatros/src/utils/notification_service.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiClient apiClient;
  final NotificationService notificationService;

  HomeBloc(this.apiClient, this.notificationService) : super(HomeInitial()) {
    on<HomeLoadMedications>(_onLoadMedications);
    on<HomeRefreshMedications>(_onRefreshMedications);
    on<HomeDeleteMedication>(_onDeleteMedication);
  }

  Future<void> _onLoadMedications(
    HomeLoadMedications event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    await _fetchMedications(emit);
  }

  Future<void> _onRefreshMedications(
    HomeRefreshMedications event,
    Emitter<HomeState> emit,
  ) async {
    await _fetchMedications(emit);
  }

  Future<void> _onDeleteMedication(
    HomeDeleteMedication event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final response = await apiClient.delete('/medications/${event.medicationId}');

      if (response.statusCode == 200) {
        // Refresh the medications list after successful deletion
        await _fetchMedications(emit);
      } else {
        emit(HomeError('Failed to delete medication: ${response.statusCode}'));
      }
    } catch (e) {
      emit(HomeError('Error deleting medication: $e'));
    }
  }

  Future<void> _fetchMedications(Emitter<HomeState> emit) async {
    try {
      final response = await apiClient.get('/medications');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final medications = data
            .map((json) => Medication.fromJson(json as Map<String, dynamic>))
            .toList();

        // Calculate statistics
        final totalMedications = medications.length;
        final todayDoses = _calculateTodayDoses(medications);
        final nextDoseTime = _getNextDoseTime(medications);

        // Schedule notifications
        await notificationService.cancelAll();
        for (final med in medications) {
          await notificationService.scheduleMedication(med);
        }

        emit(HomeLoaded(
          medications: medications,
          totalMedications: totalMedications,
          todayDoses: todayDoses,
          nextDoseTime: nextDoseTime,
        ));
      } else {
        emit(HomeError('Failed to load medications: ${response.statusCode}'));
      }
    } catch (e) {
      emit(HomeError('Error loading medications: $e'));
    }
  }

  int _calculateTodayDoses(List<Medication> medications) {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    int count = 0;

    for (final med in medications) {
      for (final schedule in med.schedules) {
        // If dayOfWeek is null, it's daily (count it)
        if (schedule.dayOfWeek == null) {
          count++;
        } else if (schedule.dayOfWeek == dayName) {
          // If dayOfWeek matches today, count it
          count++;
        }
      }
    }

    return count;
  }

  DateTime? _getNextDoseTime(List<Medication> medications) {
    DateTime? earliest;

    for (final med in medications) {
      final nextTime = med.getNextScheduledTime();
      if (nextTime != null) {
        if (earliest == null || nextTime.isBefore(earliest)) {
          earliest = nextTime;
        }
      }
    }

    return earliest;
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
}
