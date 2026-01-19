import 'package:iatros/src/features/search/response/medication_result.dart';

class SearchState{}

class Searching extends SearchState{
  final MedicationResult result;
  Searching(this.result);
}