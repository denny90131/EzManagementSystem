import 'dart:typed_data';

/// Represents a single attachment for a site, like access control or parking info.
class SiteAttachment {
  final String? note;
  final Uint8List? imageBytes;

  const SiteAttachment({this.note, this.imageBytes});

  /// Creates an empty attachment.
  const SiteAttachment.empty()
      : note = null,
        imageBytes = null;

  /// Creates a copy of this attachment but with the given fields replaced with the new values.
  SiteAttachment copyWith({
    String? note,
    Uint8List? imageBytes,
    bool clearImage = false,
  }) {
    return SiteAttachment(
      note: note ?? this.note,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
    );
  }
}

/// Represents the detailed information for a single construction site.
class SiteDetails {
  final String siteUUID;
  final String siteName;
  final String siteAddress;
  final String notes;
  final String ownerName;
  final String ownerPhone;
  final String project;
  final String contractorName;
  final String contractorPhone;
  final String orderDate;
  final String duration;
  final String sellingPrice;

  const SiteDetails({
    required this.siteUUID,
    required this.siteName,
    required this.siteAddress,
    required this.notes,
    required this.ownerName,
    required this.ownerPhone,
    required this.project,
    required this.contractorName,
    required this.contractorPhone,
    required this.orderDate,
    required this.duration,
    required this.sellingPrice,
  });

  /// Creates an empty SiteDetails object with default values.
  factory SiteDetails.fromInitial(Map<String, dynamic> site) {
    return SiteDetails(
      siteUUID: site['siteUUID']?.toString() ?? '',
      siteName: site['siteName']?.toString() ?? '未命名工地',
      siteAddress: site['siteAddress']?.toString() ?? '無地址資訊',
      notes: site['note']?.toString() ?? '',
      ownerName: site['siteOwner']?.toString() ?? '未提供',
      ownerPhone: site['siteOwnerPhoneNumber']?.toString() ?? '未提供',
      project: site['siteProperty']?.toString() ?? '未提供',
      contractorName: site['siteClient']?.toString() ?? '未提供',
      contractorPhone: site['siteClientPhoneNumber']?.toString() ?? '未提供',
      orderDate: site['siteOrderBegeingDate']?.toString().split('T')[0] ?? '未提供',
      duration: site['siteOrderExecuteTime']?.toString() ?? '未提供',
      sellingPrice: site['price']?.toString() ?? '未提供',
    );
  }

  /// Creates a SiteDetails object from an API response, using a fallback for missing fields.
  factory SiteDetails.fromApi(Map<String, dynamic> json, {required SiteDetails fallback}) {
    return SiteDetails(
      siteUUID: json['siteUUID']?.toString() ?? fallback.siteUUID,
      siteName: json['siteName']?.toString() ?? fallback.siteName,
      siteAddress: json['siteAddress']?.toString() ?? fallback.siteAddress,
      notes: json['note']?.toString() ?? fallback.notes,
      ownerName: json['siteOwner']?.toString() ?? fallback.ownerName,
      ownerPhone: json['siteOwnerPhoneNumber']?.toString() ?? fallback.ownerPhone,
      project: json['siteProperty']?.toString() ?? fallback.project,
      contractorName: json['siteClient']?.toString() ?? fallback.contractorName,
      contractorPhone: json['siteClientPhoneNumber']?.toString() ?? fallback.contractorPhone,
      orderDate: json['siteOrderBegeingDate']?.toString().split('T')[0] ?? fallback.orderDate,
      duration: json['siteOrderExecuteTime']?.toString() ?? fallback.duration,
      sellingPrice: json['price']?.toString() ?? fallback.sellingPrice,
    );
  }
}

/// Represents a meeting record.
class MeetingRecord {
  // This is a placeholder for your future implementation of point 7.
  // You would define fields like id, date, creator, content, isPrivate, etc.
}