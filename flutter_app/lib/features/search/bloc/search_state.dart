import 'package:equatable/equatable.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchSuccess extends SearchState {
  final List<Map<String, dynamic>> results;
  final String query;
  final String activeFilter;

  const SearchSuccess({
    required this.results,
    required this.query,
    this.activeFilter = 'All',
  });

  SearchSuccess copyWith({
    List<Map<String, dynamic>>? results,
    String? query,
    String? activeFilter,
  }) {
    return SearchSuccess(
      results: results ?? this.results,
      query: query ?? this.query,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [results, query, activeFilter];
}

class SearchFailure extends SearchState {
  final String message;

  const SearchFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
