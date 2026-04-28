class StudentModel {
  final String uid;
  final String rollNo;
  final String name;
  final String cnic;
  final String department;
  final String email;
  final List<String> photoUrls;
  final DateTime createdAt;

  StudentModel({
    required this.uid,
    required this.rollNo,
    required this.name,
    required this.cnic,
    required this.department,
    required this.email,
    this.photoUrls = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'rollNo': rollNo,
      'name': name,
      'cnic': cnic,
      'department': department,
      'email': email,
      'photoUrls': photoUrls,
      'createdAt': createdAt,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'],
      rollNo: map['rollNo'],
      name: map['name'],
      cnic: map['cnic'],
      department: map['department'],
      email: map['email'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      createdAt: map['createdAt'].toDate(),
    );
  }
}