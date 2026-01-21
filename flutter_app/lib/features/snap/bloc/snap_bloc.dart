import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../data/snap_repository.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/offline_queue_service.dart';

part 'snap_event.dart';
part 'snap_state.dart';

class SnapBloc extends Bloc<SnapEvent, SnapState> {
  final SnapRepository _repository;
  final ImagePicker _picker = ImagePicker();

  SnapBloc({SnapRepository? repository})
      : _repository = repository ?? SnapRepository(),
        super(SnapInitial()) {
    on<SnapImagePicked>(_onImagePicked);
    on<SnapSolveRequested>(_onSolveRequested);
    on<SnapSaveRequested>(_onSaveRequested);
    on<SnapReset>(_onReset);
  }

  Future<void> _onSaveRequested(
      SnapSaveRequested event, Emitter<SnapState> emit) async {
    if (state is SnapSolutionLoaded) {
      final currentState = state as SnapSolutionLoaded;
      emit(currentState.copyWith(saveStatus: SaveStatus.saving));

      final success = await _repository.saveSnap(
        title: event.title,
        content: event.content,
        subject: event.subject,
        grade: event.grade,
      );

      if (success) {
        emit(currentState.copyWith(saveStatus: SaveStatus.success));
      } else {
        emit(currentState.copyWith(saveStatus: SaveStatus.error));
      }
    }
  }

  Future<void> _onImagePicked(
      SnapImagePicked event, Emitter<SnapState> emit) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: event.source);
      if (pickedFile != null) {
        // First state transition: Image picked, starting crop/scan flow
        // We can do cropping here or separately. Let's do it immediately.
        await _processImage(pickedFile.path, emit);
      }
    } catch (e) {
      emit(SnapError("Failed to pick image: $e"));
    }
  }

  Future<void> _processImage(String path, Emitter<SnapState> emit) async {
    try {
      // 1. Crop
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Problem',
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Problem',
          ),
        ],
      );

      if (croppedFile != null) {
        final file = File(croppedFile.path);
        emit(SnapScanning(imageFile: file));

        // 2. OCR
        final inputImage = InputImage.fromFile(file);
        final textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);
        final text = recognizedText.text;

        textRecognizer.close();

        if (text.trim().isEmpty) {
          emit(SnapError("No text found in image", imageFile: file));
        } else {
          emit(SnapScanned(imageFile: file, extractedText: text));
        }
      }
    } catch (e) {
      emit(SnapError("Image processing failed: $e"));
    }
  }

  Future<void> _onSolveRequested(
      SnapSolveRequested event, Emitter<SnapState> emit) async {
    final currentState = state;
    File? currentImage; // Keep reference to image if we have it
    if (currentState is SnapScanned) {
      currentImage = currentState.imageFile;
    } else if (currentState is SnapSolutionLoaded) {
      currentImage = currentState.imageFile;
    }

    if (currentImage == null && currentState is SnapError) {
      currentImage = currentState.imageFile;
    }

    if (currentImage == null) {
      emit(const SnapError("No image available to context"));
      return;
    }

    emit(SnapSolutionLoading(
        imageFile: currentImage, extractedText: event.text));

    try {
      final offlineService = OfflineQueueService();
      if (!await offlineService.isOnline()) {
        await offlineService.addToQueue(
          text: event.text,
          grade: event.grade,
          subject: event.subject,
          language: event.language,
        );
        emit(SnapOfflineQueued(imageFile: currentImage));
        return;
      }

      final result = await _repository.solveProblem(
        text: event.text,
        grade: event.grade,
        subject: event.subject,
        language: event.language,
      );

      emit(SnapSolutionLoaded(
        imageFile: currentImage,
        extractedText: event.text,
        solution: result,
      ));
    } catch (e) {
      bool isNetworkError = false;

      // Check for generic network errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('No route to host')) {
        isNetworkError = true;
      }

      // Check for Dio specific connection errors
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.unknown) {
          // Unknown often wraps SocketException
          isNetworkError = true;
        }
      }

      if (isNetworkError) {
        final offlineService = OfflineQueueService();
        try {
          await offlineService.addToQueue(
            text: event.text,
            grade: event.grade,
            subject: event.subject,
            language: event.language,
          );
        } catch (queueError) {
          debugPrint('Failed to add to offline queue: $queueError');
        }
        emit(SnapOfflineQueued(imageFile: currentImage));
        return;
      }

      emit(SnapError("Failed to solve problem: $e", imageFile: currentImage));
      // Optionally fallback to Scanned state to let user retry?
      // Instead we stay in Error state but keep image so they can retry.
    }
  }

  void _onReset(SnapReset event, Emitter<SnapState> emit) {
    emit(SnapInitial());
  }
}
