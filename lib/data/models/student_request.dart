class StudentRequest {
  final String id;
  final String name;
  final String email;
  final String createdAt;
  final String? message; // optional custom message from learner
  final String status; // pending, approved, rejected

  StudentRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.message,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'message': message,
      'status': status,
    };
  }

  factory StudentRequest.fromMap(Map<String, dynamic> map) {
    return StudentRequest(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] ?? '',
      message: map['message'],
      status: map['status'] ?? 'pending',
    );
  }
}
