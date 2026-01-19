import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iatros/src/features/search/bloc/search_event.dart';
import 'package:iatros/src/features/search/bloc/search_state.dart';
import 'package:iatros/src/utils/api_client.dart';
import 'package:iatros/src/features/search/response/medication_result.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState>{
  SearchBloc(): super(SearchState()) {
    on<Search>((event, emit) async {
      try {
        final response = await ApiClient().get(
          '/medications/search',
          queryParameters: {'term': event.term},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final medicationResult = MedicationResult.fromJson(data);
          print("Response body: ${response.body}");

          emit(Searching(medicationResult));
        } else {
          print(response.statusCode);
        }
      } catch (e) {
        print(e);
      }
    });
  }
}