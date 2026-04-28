class EnrollmentModel {
  final String enrollmentId;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String courseCode;
  final String status; // pending / approved / rejected
  final DateTime requestedAt;

  EnrollmentModel({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.status,
    required this.requestedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'enrollmentId': enrollmentId,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'courseCode': courseCode,
      'status': status,
      'requestedAt': requestedAt,
    };
  }

  factory EnrollmentModel.fromMap(Map<String, dynamic> map) {
    return EnrollmentModel(
      enrollmentId: map['enrollmentId'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      courseId: map['courseId'],
      courseName: map['courseName'],
      courseCode: map['courseCode'],
      status: map['status'],
      requestedAt: map['requestedAt'].toDate(),
    );
  }
}