import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:iatros/src/features/search/bloc/search_bloc.dart';
import 'package:iatros/src/features/search/bloc/search_event.dart';
import 'package:iatros/src/features/search/bloc/search_state.dart';
import 'package:iatros/src/features/search/response/medication.dart';
import 'package:iatros/src/features/search/response/medication_result.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late SearchBloc searchBloc;
  final TextEditingController searchController = TextEditingController();
  final GlobalKey _textFieldKey = GlobalKey();
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      print("after 600ms");
      searchBloc.add(Search(query));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    searchBloc = context.read<SearchBloc>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Search", style: TextStyle(fontSize: 30)),
        SizedBox(height: 30),
        FTextField(
          key: _textFieldKey,
          controller: searchController,
          clearable: (value) => value.text.isNotEmpty,
          enabled: true,
          hint: 'enter medicine',
          textCapitalization: TextCapitalization.none,
          maxLines: 1,
          onChange: _onSearchChanged,
        ),
        SizedBox(height: 30),
        BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is Searching) {
              MedicationResult result = state.result;
              return SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: result.results.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: ListTile(title: Text(result.results[index].name), onTap: () {
                        context.go("/add", extra: {
                          'name':result.results[index].name,
                          'rxcui': result.results[index].rxcui
                        });
                      },),
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}
