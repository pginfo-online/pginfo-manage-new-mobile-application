// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Property _$PropertyFromJson(Map<String, dynamic> json) => _Property(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  city: json['city'] as String?,
);

Map<String, dynamic> _$PropertyToJson(_Property instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'city': instance.city,
};

_Room _$RoomFromJson(Map<String, dynamic> json) => _Room(
  id: json['id'] as String,
  roomNumber: json['roomNumber'] as String,
  sharingType: json['sharingType'] as String,
  rentAmount: (json['rentAmount'] as num).toInt(),
  status: json['status'] as String,
  gender: json['gender'] as String? ?? 'UNISEX',
  unitType: json['unitType'] as String? ?? 'Room',
  isDisabledForRent: json['isDisabledForRent'] as bool? ?? false,
  isPublished: json['isPublished'] as bool? ?? true,
  availableFrom: json['availableFrom'] as String?,
  property: json['property'] == null
      ? null
      : PropertySummary.fromJson(json['property'] as Map<String, dynamic>),
  beds:
      (json['beds'] as List<dynamic>?)
          ?.map((e) => Bed.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$RoomToJson(_Room instance) => <String, dynamic>{
  'id': instance.id,
  'roomNumber': instance.roomNumber,
  'sharingType': instance.sharingType,
  'rentAmount': instance.rentAmount,
  'status': instance.status,
  'gender': instance.gender,
  'unitType': instance.unitType,
  'isDisabledForRent': instance.isDisabledForRent,
  'isPublished': instance.isPublished,
  'availableFrom': instance.availableFrom,
  'property': instance.property,
  'beds': instance.beds,
  'images': instance.images,
};

_PropertySummary _$PropertySummaryFromJson(Map<String, dynamic> json) =>
    _PropertySummary(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      timezone: json['timezone'] as String?,
    );

Map<String, dynamic> _$PropertySummaryToJson(_PropertySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'timezone': instance.timezone,
    };

_Bed _$BedFromJson(Map<String, dynamic> json) => _Bed(
  id: json['id'] as String,
  bedNumber: json['bedNumber'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$BedToJson(_Bed instance) => <String, dynamic>{
  'id': instance.id,
  'bedNumber': instance.bedNumber,
  'status': instance.status,
};

_Resident _$ResidentFromJson(Map<String, dynamic> json) => _Resident(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String?,
  mobile: json['mobile'] as String,
  email: json['email'] as String?,
  whatsappNumber: json['whatsappNumber'] as String?,
  emergencyContact: json['emergencyContact'] as String?,
  permanentAddress: json['permanentAddress'] as String?,
  parentName: json['parentName'] as String?,
  parentPhone: json['parentPhone'] as String?,
  idProofUrl: json['idProofUrl'] as String?,
  agreementUrl: json['agreementUrl'] as String?,
  profession: json['profession'] as String?,
  monthlyRent: (json['monthlyRent'] as num).toInt(),
  securityDeposit: (json['securityDeposit'] as num?)?.toInt() ?? 0,
  rentDueDay: (json['rentDueDay'] as num?)?.toInt(),
  propertyId: json['propertyId'] as String?,
  roomId: json['roomId'] as String?,
  bedId: json['bedId'] as String?,
  joiningDate: json['joiningDate'] as String?,
  status: json['status'] as String?,
  notes: json['notes'] as String?,
  room: json['room'] == null
      ? null
      : TenantRoomSummary.fromJson(json['room'] as Map<String, dynamic>),
  bed: json['bed'] == null
      ? null
      : TenantBedSummary.fromJson(json['bed'] as Map<String, dynamic>),
  dues: (json['dues'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ResidentToJson(_Resident instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'mobile': instance.mobile,
  'email': instance.email,
  'whatsappNumber': instance.whatsappNumber,
  'emergencyContact': instance.emergencyContact,
  'permanentAddress': instance.permanentAddress,
  'parentName': instance.parentName,
  'parentPhone': instance.parentPhone,
  'idProofUrl': instance.idProofUrl,
  'agreementUrl': instance.agreementUrl,
  'profession': instance.profession,
  'monthlyRent': instance.monthlyRent,
  'securityDeposit': instance.securityDeposit,
  'rentDueDay': instance.rentDueDay,
  'propertyId': instance.propertyId,
  'roomId': instance.roomId,
  'bedId': instance.bedId,
  'joiningDate': instance.joiningDate,
  'status': instance.status,
  'notes': instance.notes,
  'room': instance.room,
  'bed': instance.bed,
  'dues': instance.dues,
};

_TenantRoomSummary _$TenantRoomSummaryFromJson(Map<String, dynamic> json) =>
    _TenantRoomSummary(
      id: json['id'] as String,
      roomNumber: json['roomNumber'] as String,
      floor: json['floor'] as String?,
      sharingType: json['sharingType'] as String?,
    );

Map<String, dynamic> _$TenantRoomSummaryToJson(_TenantRoomSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomNumber': instance.roomNumber,
      'floor': instance.floor,
      'sharingType': instance.sharingType,
    };

_TenantBedSummary _$TenantBedSummaryFromJson(Map<String, dynamic> json) =>
    _TenantBedSummary(
      id: json['id'] as String,
      bedNumber: json['bedNumber'] as String,
    );

Map<String, dynamic> _$TenantBedSummaryToJson(_TenantBedSummary instance) =>
    <String, dynamic>{'id': instance.id, 'bedNumber': instance.bedNumber};
