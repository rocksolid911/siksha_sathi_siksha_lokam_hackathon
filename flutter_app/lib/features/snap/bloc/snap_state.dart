part of 'snap_bloc.dart';

abstract class SnapState extends Equatable {
  const SnapState();

  @override
  List<Object?> get props => [];
}

class SnapInitial extends SnapState {}

class SnapScanning extends SnapState {
  final File? imageFile;
  const SnapScanning({this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

class SnapScanned extends SnapState {
  final File imageFile;
  final String extractedText;

  const SnapScanned({required this.imageFile, required this.extractedText});

  @override
  List<Object?> get props => [imageFile, extractedText];
}

class SnapSolutionLoading extends SnapState {
  final File imageFile;
  final String extractedText;

  const SnapSolutionLoading(
      {required this.imageFile, required this.extractedText});

  @override
  List<Object?> get props => [imageFile, extractedText];
}

class SnapOfflineQueued extends SnapState {
  final File? imageFile;
  const SnapOfflineQueued({this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

enum SaveStatus { initial, saving, success, error }

class SnapSolutionLoaded extends SnapState {
  final File imageFile;
  final String extractedText;
  final Map<String, dynamic> solution;
  final SaveStatus saveStatus;

  const SnapSolutionLoaded({
    required this.imageFile,
    required this.extractedText,
    required this.solution,
    this.saveStatus = SaveStatus.initial,
  });

  SnapSolutionLoaded copyWith({
    SaveStatus? saveStatus,
  }) {
    return SnapSolutionLoaded(
      imageFile: imageFile,
      extractedText: extractedText,
      solution: solution,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }

  @override
  List<Object?> get props => [imageFile, extractedText, solution, saveStatus];
}

class SnapError extends SnapState {
  final String message;
  final File? imageFile;

  const SnapError(this.message, {this.imageFile});

  @override
  List<Object?> get props => [message, imageFile];
}
