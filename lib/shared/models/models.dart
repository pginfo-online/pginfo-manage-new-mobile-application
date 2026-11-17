import 'package:freezed_annotation/freezed_annotation.dart';
part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class Property with _$Property {
  const factory Property({
    required String id,
    required String name,
    required String type,
    String? city,
    @Default(0) int roomCount,
  }) = _Property;
  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class Room with _$Room {
  const factory Room({
    required String id,
    required String roomNumber,
    @Default('0') String floor,
    required String sharingType,
    required int rentAmount,
    required String status,
    @Default('UNISEX') String gender,
    @Default('Room') String unitType,
    @Default(false) bool isDisabledForRent,
    @Default(true) bool isPublished,
    String? availableFrom,
    PropertySummary? property,
    @Default([]) List<Bed> beds,
    @Default([]) List<String> images,
    @Default([]) List<String> amenities,
    String? description,
    String? remarks,
  }) = _Room;
  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}

@freezed
abstract class PropertySummary with _$PropertySummary {
  const factory PropertySummary({
    required String id,
    required String name,
    required String type,
    String? timezone,
  }) = _PropertySummary;
  factory PropertySummary.fromJson(Map<String, dynamic> json) =>
      _$PropertySummaryFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class Bed with _$Bed {
  const factory Bed({
    required String id,
    required String bedNumber,
    required String status,
    @Default([]) List<Resident> residents,
  }) = _Bed;
  factory Bed.fromJson(Map<String, dynamic> json) => _$BedFromJson(json);
}

@freezed
abstract class Resident with _$Resident {
  const factory Resident({
    required String id,
    required String firstName,
    String? lastName,
    required String mobile,
    String? email,
    String? whatsappNumber,
    String? emergencyContact,
    String? permanentAddress,
    String? parentName,
    String? parentPhone,
    String? idProofUrl,
    String? agreementUrl,
    String? profession,
    required int monthlyRent,
    @Default(0) int securityDeposit,
    int? rentDueDay,
    String? propertyId,
    String? roomId,
    String? bedId,
    String? joiningDate,
    String? moveOutDate,
    String? expectedVacatingDate,
    PropertySummary? property,
    @Default(false) bool autopayActive,
    String? status,
    String? notes,
    TenantRoomSummary? room,
    TenantBedSummary? bed,
    @Default(0) int dues,
  }) = _Resident;
  factory Resident.fromJson(Map<String, dynamic> json) =>
      _$ResidentFromJson(json);
}

@freezed
abstract class TenantRoomSummary with _$TenantRoomSummary {
  const factory TenantRoomSummary({
    required String id,
    required String roomNumber,
    String? floor,
    String? sharingType,
  }) = _TenantRoomSummary;
  factory TenantRoomSummary.fromJson(Map<String, dynamic> json) =>
      _$TenantRoomSummaryFromJson(json);
}

@freezed
abstract class TenantBedSummary with _$TenantBedSummary {
  const factory TenantBedSummary({
    required String id,
    required String bedNumber,
  }) = _TenantBedSummary;
  factory TenantBedSummary.fromJson(Map<String, dynamic> json) =>
      _$TenantBedSummaryFromJson(json);
}

String rupees(num paise) =>
    '₹${(paise / 100).toStringAsFixed(paise % 100 == 0 ? 0 : 2)}';
int? tryParseRupees(String? input) {
  final value = input?.trim() ?? '';
  if (!RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final whole = int.tryParse(parts.first);
  if (whole == null) return null;
  final fraction = parts.length == 1
      ? 0
      : int.parse(parts.last.padRight(2, '0'));
  return whole * 100 + fraction;
}

int parseRupees(String input) =>
    tryParseRupees(input) ??
    (throw const FormatException(
      'Enter rupees with at most two decimal places',
    ));
List<T> pageData<T>(dynamic value, T Function(Map<String, dynamic>) decode) {
  final list = value is List
      ? value
      : (value as Map<String, dynamic>)['data'] as List<dynamic>;
  return list.map((e) => decode(Map<String, dynamic>.from(e as Map))).toList();
}
