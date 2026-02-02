import 'package:equatable/equatable.dart';

class ActiveContextState extends Equatable {
  final String? activeGrade;
  final String? activeSubject;
  final int? studentCount;
  final bool isInitialized;
  final bool isLoading;

  const ActiveContextState({
    this.activeGrade,
    this.activeSubject,
    this.studentCount,
    this.isInitialized = false,
    this.isLoading = true, // Start as loading
  });

  ActiveContextState copyWith({
    String? activeGrade,
    String? activeSubject,
    int? studentCount,
    bool? isInitialized,
    bool? isLoading,
  }) {
    return ActiveContextState(
      activeGrade: activeGrade ?? this.activeGrade,
      activeSubject: activeSubject ?? this.activeSubject,
      studentCount: studentCount ?? this.studentCount,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props =>
      [activeGrade, activeSubject, studentCount, isInitialized, isLoading];
}
