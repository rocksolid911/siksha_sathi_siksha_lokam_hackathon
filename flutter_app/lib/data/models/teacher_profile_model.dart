/// Complete teacher profile model with all fields
class TeacherProfile {
  final String? firebaseUid;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final String role;
  final String? school;
  final String? district;
  final String? state;
  final String? gradesTaught;
  final String? subjectsTaught;
  final int numberOfStudents;
  final String preferredLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  const TeacherProfile({
    this.firebaseUid,
    required this.name,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.role = 'teacher',
    this.school,
    this.district,
    this.state,
    this.gradesTaught,
    this.subjectsTaught,
    this.numberOfStudents = 0,
    this.preferredLanguage = 'hi',
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  /// Create from Firebase Firestore data
  factory TeacherProfile.fromFirestore(Map<String, dynamic> data) {
    return TeacherProfile(
      firebaseUid: data['firebase_uid'] ?? data['firebaseUid'],
      name: data['name'] ?? 'Teacher',
      email: data['email'],
      phoneNumber: data['phone_number'] ?? data['phoneNumber'],
      photoUrl: data['photo_url'] ?? data['photoUrl'],
      role: data['role'] ?? 'teacher',
      school: data['school'],
      district: data['district'],
      state: data['state'],
      gradesTaught: data['grades_taught'] ?? data['gradesTaught'],
      subjectsTaught: data['subjects_taught'] ?? data['subjectsTaught'],
      numberOfStudents:
          data['number_of_students'] ?? data['numberOfStudents'] ?? 0,
      preferredLanguage:
          data['preferred_language'] ?? data['preferredLanguage'] ?? 'hi',
      createdAt: _parseDateTime(data['created_at'] ?? data['createdAt']),
      updatedAt: _parseDateTime(data['updated_at'] ?? data['updatedAt']),
      lastLogin: _parseDateTime(data['last_login'] ?? data['lastLogin']),
    );
  }

  /// Create from JSON (alias for fromFirestore)
  factory TeacherProfile.fromJson(Map<String, dynamic> json) =>
      TeacherProfile.fromFirestore(json);

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      if (firebaseUid != null) 'firebase_uid': firebaseUid,
      'name': name,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (photoUrl != null) 'photo_url': photoUrl,
      'role': role,
      if (school != null) 'school': school,
      if (district != null) 'district': district,
      if (state != null) 'state': state,
      if (gradesTaught != null) 'grades_taught': gradesTaught,
      if (subjectsTaught != null) 'subjects_taught': subjectsTaught,
      'number_of_students': numberOfStudents,
      'preferred_language': preferredLanguage,
      // Don't modify created_at on update
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => toFirestore();

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Copy with new values
  TeacherProfile copyWith({
    String? firebaseUid,
    String? name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    String? school,
    String? district,
    String? state,
    String? gradesTaught,
    String? subjectsTaught,
    int? numberOfStudents,
    String? preferredLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return TeacherProfile(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      school: school ?? this.school,
      district: district ?? this.district,
      state: state ?? this.state,
      gradesTaught: gradesTaught ?? this.gradesTaught,
      subjectsTaught: subjectsTaught ?? this.subjectsTaught,
      numberOfStudents: numberOfStudents ?? this.numberOfStudents,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// Get display name for grades
  String get gradesDisplay =>
      gradesTaught?.isNotEmpty == true ? 'Class $gradesTaught' : 'Not set';

  /// Get display name for subjects
  String get subjectsDisplay =>
      subjectsTaught?.isNotEmpty == true ? subjectsTaught! : 'Not set';

  /// Get initials for avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'T';
  }
}
