part of 'snap_bloc.dart';

abstract class SnapEvent extends Equatable {
  const SnapEvent();

  @override
  List<Object> get props => [];
}

class SnapImagePicked extends SnapEvent {
  final ImageSource source;
  const SnapImagePicked(this.source);

  @override
  List<Object> get props => [source];
}

class SnapImageCropped extends SnapEvent {
  final String path;
  const SnapImageCropped(this.path);

  @override
  List<Object> get props => [path];
}

class SnapSolveRequested extends SnapEvent {
  final String text;
  final String grade;
  final String subject;
  final String language;

  const SnapSolveRequested({
    required this.text,
    required this.grade,
    required this.subject,
    this.language = 'en',
  });

  @override
  List<Object> get props => [text, grade, subject, language];
}

class SnapSaveRequested extends SnapEvent {
  final String title;
  final String content;
  final String subject;
  final String grade;

  const SnapSaveRequested({
    required this.title,
    required this.content,
    required this.subject,
    required this.grade,
  });

  @override
  List<Object> get props => [title, content, subject, grade];
}

class SnapReset extends SnapEvent {}
