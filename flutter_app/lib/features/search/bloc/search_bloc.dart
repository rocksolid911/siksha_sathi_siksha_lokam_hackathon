import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/search_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _repository;

  SearchBloc({SearchRepository? repository})
      : _repository = repository ?? SearchRepository(),
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<SearchFilterChanged>(_onSearchFilterChanged);
    on<SearchReset>(_onSearchReset);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());

    try {
      final results = await _repository.search(event.query);
      emit(SearchSuccess(
        results: results,
        query: event.query,
      ));
    } catch (e) {
      emit(SearchFailure(message: e.toString()));
    }
  }

  void _onSearchFilterChanged(
    SearchFilterChanged event,
    Emitter<SearchState> emit,
  ) {
    if (state is SearchSuccess) {
      emit((state as SearchSuccess).copyWith(activeFilter: event.filter));
    }
  }

  void _onSearchReset(
    SearchReset event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchInitial());
  }
}
