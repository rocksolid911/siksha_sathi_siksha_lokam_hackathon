import 'package:equatable/equatable.dart';
import '../../../../data/models/teacher_profile_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  final String message;

  const ProfileLoading({this.message = 'Loading...'});

  @override
  List<Object?> get props => [message];
}

class ProfileLoaded extends ProfileState {
  final TeacherProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// State to indicate successful deletion (to navigate away)
class ProfileDeleted extends ProfileState {
  const ProfileDeleted();
}
