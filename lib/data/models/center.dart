// import 'package:wordstory/data/models/instructor.dart';
// import 'package:wordstory/data/models/student_request.dart';

enum Role { user, learner, instructor, admin, pendingLearner }

class CenterDetails {
  final String? id;
  final String name;
  final String code;
  final String admin;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  // final List<String> admins;
  // final List<Instructor> instructors;
  final List<String> learners;
  // final List<StudentRequest> studentRequests;
  final String? plan;
  final String createdAt;
  final String? updatedAt;
  final bool isActive;
  final String? colorScheme; // personalization
  final bool notificationsEnabled; // personalization

  CenterDetails({
    this.id,
    required this.name,
    required this.code,
    required this.admin,
    this.logoUrl,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.description,
    // this.admins = const [],
    // this.instructors = const [],
    this.learners = const [],
    // this.studentRequests = const [],
    this.plan,
    String? createdAt,
    this.updatedAt,
    this.isActive = true,
    this.colorScheme,
    this.notificationsEnabled = true,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory CenterDetails.fromMap(Map<String, dynamic> map) {
    return CenterDetails(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      description: map['description'] ?? '',
      admin: map['admin'] ?? '',
      // admins: (map['admins'] as List?)?.map((e) => e.toString()).toList() ?? [],
      // instructors: (map['instructors'] as List?)
      //         ?.map((e) => Instructor.fromMap((e as Map<String, dynamic>)['id'], Map<String, dynamic>.from(e)))
      //         .toList() ??
      //     [],
      learners: (map['learners'] as List?)?.map((e) => e.toString()).toList() ?? [],
      // studentRequests: (map['studentRequests'] as List?)
      //         ?.map((e) => StudentRequest.fromMap(Map<String, dynamic>.from(e)))
      //         .toList() ??
      //     [],
      plan: map['plan'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
      isActive: map['isActive'] ?? true,
      colorScheme: map['colorScheme'] ?? '',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'logoUrl': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'description': description,
      'admin': admin,
      // 'admins': admins,
      // 'instructors': instructors,
      'learners': learners,
      // 'studentRequests': studentRequests.map((e) => e.toMap()).toList(),
      'plan': plan,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'colorScheme': colorScheme,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}
