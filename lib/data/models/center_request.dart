import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/data/models/center.dart';

enum RequestType { join, leave, changeClass, inValid }

enum RequestStatus { pending, approved, rejected }

class CenterRequest {
  final String id;
  final String requesterId;
  final RequestType type;
  final String? reason;
  final String? centerCode;
  final String? createdAt;
  final String? updatedAt;
  final RequestStatus status; // pending, approved, rejected
  final Role requesterRole;

  CenterRequest({
    required this.id,
    required this.requesterId,
    required this.type,
    this.reason,
    this.centerCode,
    this.createdAt,
    this.updatedAt,
    this.status = RequestStatus.pending,
    required this.requesterRole,
  });

  /// Deserialize from Firestore
  factory CenterRequest.fromMap(String id, Map<String, dynamic> map) {
    return CenterRequest(
      id: id,
      requesterId: map['requesterId'] ?? '',
      type: RequestType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RequestType.inValid,
      ),
      reason: map['reason'],
      centerCode: map['centerCode'],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : map['createdAt'],
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate().toIso8601String()
          : map['updatedAt'],
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      requesterRole: Role.values.firstWhere(
        (e) => e.name == map['requesterRole'],
        orElse: () => Role.user,
      ),
    );
  }

  /// Serialize to Firestore
  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'type': type.name,
      'reason': reason,
      'centerCode': centerCode,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
      'status': status.name,
      'requesterRole': requesterRole.name,
    };
  }

  /// CopyWith method
  CenterRequest copyWith({
    String? id,
    String? requesterId,
    RequestType? type,
    String? reason,
    String? centerCode,
    String? createdAt,
    String? updatedAt,
    RequestStatus? status,
    Role? requesterRole,
  }) {
    return CenterRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      centerCode: centerCode ?? this.centerCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      requesterRole: requesterRole ?? this.requesterRole,
    );
  }
}
