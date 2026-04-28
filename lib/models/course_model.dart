class CourseModel {
  final String courseId;
  final String name;
  final String code;
  final String department;
  final String teacherId;
  final String teacherName;
  final int creditHours;
  final String semester;
  final DateTime createdAt;

  CourseModel({
    required this.courseId,
    required this.name,
    required this.code,
    required this.department,
    required this.teacherId,
    required this.teacherName,
    required this.creditHours,
    required this.semester,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'name': name,
      'code': code,
      'department': department,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'creditHours': creditHours,
      'semester': semester,
      'createdAt': createdAt,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      courseId: map['courseId'],
      name: map['name'],
      code: map['code'],
      department: map['department'],
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      creditHours: map['creditHours'],
      semester: map['semester'],
      createdAt: map['createdAt'].toDate(),
    );
  }
}