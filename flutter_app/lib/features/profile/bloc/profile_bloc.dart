import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/models/teacher_profile_model.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository;

  ProfileBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfileDeleteAccountRequested>(_onDeleteAccountRequested);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading(message: 'Loading profile...'));
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(const ProfileError('User not logged in'));
        return;
      }

      final profileMap = await _authRepository.getUserProfile(user.uid);

      if (profileMap != null) {
        // Merge with auth data if needed or just use firestore data
        final profile = TeacherProfile.fromFirestore(profileMap).copyWith(
          firebaseUid: user.uid,
          email: user.email,
          photoUrl:
              user.photoURL, // Prefer auth photo if available or use profile
        );
        emit(ProfileLoaded(profile));
      } else {
        // Profile doesn't exist yet, create basic one from Auth
        final profile = TeacherProfile(
          firebaseUid: user.uid,
          name: user.displayName ?? 'Teacher',
          email: user.email,
          photoUrl: user.photoURL,
        );
        emit(ProfileLoaded(profile));
      }
    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading(message: 'Saving changes...'));
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(const ProfileError('User not logged in'));
        return;
      }

      await _authRepository.saveUserProfile(
        uid: user.uid,
        profileData: event.profile.toFirestore(),
      );

      // Re-load to get latest state or just emit the updated profile
      // Using event.profile is faster but might miss server-side fields
      emit(ProfileLoaded(event.profile));
    } catch (e) {
      emit(ProfileError('Failed to update profile: $e'));
    }
  }

  Future<void> _onDeleteAccountRequested(
    ProfileDeleteAccountRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading(message: 'Deleting account...'));
    try {
      await _authRepository.deleteAccount();
      emit(const ProfileDeleted());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
