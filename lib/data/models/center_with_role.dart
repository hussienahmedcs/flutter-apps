import 'package:wordstory/data/models/center.dart';

class CenterWithRole {
  final CenterDetails center;
  final Role role; // e.g., ["admin", "instructor"]

  CenterWithRole(this.center, this.role);

  Map<String, dynamic> toMap() {
    return {
      'center': center.toMap(),
      'role': role.name,
    };
  }

  factory CenterWithRole.fromMap(Map<String, dynamic> map) {
    return CenterWithRole(
      CenterDetails.fromMap(Map<String, dynamic>.from(map['center'] ?? {})),
      Role.values.firstWhere((e) => e.name == map['role'], orElse: () => Role.user),
    );
  }
}
