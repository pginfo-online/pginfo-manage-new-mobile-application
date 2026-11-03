// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Property {

 String get id; String get name; String get type; String? get city;
/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyCopyWith<Property> get copyWith => _$PropertyCopyWithImpl<Property>(this as Property, _$identity);

  /// Serializes this Property to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Property&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,city);

@override
String toString() {
  return 'Property(id: $id, name: $name, type: $type, city: $city)';
}


}

/// @nodoc
abstract mixin class $PropertyCopyWith<$Res>  {
  factory $PropertyCopyWith(Property value, $Res Function(Property) _then) = _$PropertyCopyWithImpl;
@useResult
$Res call({
 String id, String name, String type, String? city
});




}
/// @nodoc
class _$PropertyCopyWithImpl<$Res>
    implements $PropertyCopyWith<$Res> {
  _$PropertyCopyWithImpl(this._self, this._then);

  final Property _self;
  final $Res Function(Property) _then;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? city = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Property].
extension PropertyPatterns on Property {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Property value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Property value)  $default,){
final _that = this;
switch (_that) {
case _Property():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Property value)?  $default,){
final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  String? city)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.city);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  String? city)  $default,) {final _that = this;
switch (_that) {
case _Property():
return $default(_that.id,_that.name,_that.type,_that.city);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  String? city)?  $default,) {final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.city);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Property implements Property {
  const _Property({required this.id, required this.name, required this.type, this.city});
  factory _Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);

@override final  String id;
@override final  String name;
@override final  String type;
@override final  String? city;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyCopyWith<_Property> get copyWith => __$PropertyCopyWithImpl<_Property>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Property&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,city);

@override
String toString() {
  return 'Property(id: $id, name: $name, type: $type, city: $city)';
}


}

/// @nodoc
abstract mixin class _$PropertyCopyWith<$Res> implements $PropertyCopyWith<$Res> {
  factory _$PropertyCopyWith(_Property value, $Res Function(_Property) _then) = __$PropertyCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String type, String? city
});




}
/// @nodoc
class __$PropertyCopyWithImpl<$Res>
    implements _$PropertyCopyWith<$Res> {
  __$PropertyCopyWithImpl(this._self, this._then);

  final _Property _self;
  final $Res Function(_Property) _then;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? city = freezed,}) {
  return _then(_Property(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Room {

 String get id; String get roomNumber; String get sharingType; int get rentAmount; String get status; String get gender; String get unitType; bool get isDisabledForRent; bool get isPublished; String? get availableFrom; PropertySummary? get property; List<Bed> get beds; List<String> get images;
/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomCopyWith<Room> get copyWith => _$RoomCopyWithImpl<Room>(this as Room, _$identity);

  /// Serializes this Room to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Room&&(identical(other.id, id) || other.id == id)&&(identical(other.roomNumber, roomNumber) || other.roomNumber == roomNumber)&&(identical(other.sharingType, sharingType) || other.sharingType == sharingType)&&(identical(other.rentAmount, rentAmount) || other.rentAmount == rentAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.unitType, unitType) || other.unitType == unitType)&&(identical(other.isDisabledForRent, isDisabledForRent) || other.isDisabledForRent == isDisabledForRent)&&(identical(other.isPublished, isPublished) || other.isPublished == isPublished)&&(identical(other.availableFrom, availableFrom) || other.availableFrom == availableFrom)&&(identical(other.property, property) || other.property == property)&&const DeepCollectionEquality().equals(other.beds, beds)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomNumber,sharingType,rentAmount,status,gender,unitType,isDisabledForRent,isPublished,availableFrom,property,const DeepCollectionEquality().hash(beds),const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'Room(id: $id, roomNumber: $roomNumber, sharingType: $sharingType, rentAmount: $rentAmount, status: $status, gender: $gender, unitType: $unitType, isDisabledForRent: $isDisabledForRent, isPublished: $isPublished, availableFrom: $availableFrom, property: $property, beds: $beds, images: $images)';
}


}

/// @nodoc
abstract mixin class $RoomCopyWith<$Res>  {
  factory $RoomCopyWith(Room value, $Res Function(Room) _then) = _$RoomCopyWithImpl;
@useResult
$Res call({
 String id, String roomNumber, String sharingType, int rentAmount, String status, String gender, String unitType, bool isDisabledForRent, bool isPublished, String? availableFrom, PropertySummary? property, List<Bed> beds, List<String> images
});


$PropertySummaryCopyWith<$Res>? get property;

}
/// @nodoc
class _$RoomCopyWithImpl<$Res>
    implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._self, this._then);

  final Room _self;
  final $Res Function(Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomNumber = null,Object? sharingType = null,Object? rentAmount = null,Object? status = null,Object? gender = null,Object? unitType = null,Object? isDisabledForRent = null,Object? isPublished = null,Object? availableFrom = freezed,Object? property = freezed,Object? beds = null,Object? images = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomNumber: null == roomNumber ? _self.roomNumber : roomNumber // ignore: cast_nullable_to_non_nullable
as String,sharingType: null == sharingType ? _self.sharingType : sharingType // ignore: cast_nullable_to_non_nullable
as String,rentAmount: null == rentAmount ? _self.rentAmount : rentAmount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,unitType: null == unitType ? _self.unitType : unitType // ignore: cast_nullable_to_non_nullable
as String,isDisabledForRent: null == isDisabledForRent ? _self.isDisabledForRent : isDisabledForRent // ignore: cast_nullable_to_non_nullable
as bool,isPublished: null == isPublished ? _self.isPublished : isPublished // ignore: cast_nullable_to_non_nullable
as bool,availableFrom: freezed == availableFrom ? _self.availableFrom : availableFrom // ignore: cast_nullable_to_non_nullable
as String?,property: freezed == property ? _self.property : property // ignore: cast_nullable_to_non_nullable
as PropertySummary?,beds: null == beds ? _self.beds : beds // ignore: cast_nullable_to_non_nullable
as List<Bed>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PropertySummaryCopyWith<$Res>? get property {
    if (_self.property == null) {
    return null;
  }

  return $PropertySummaryCopyWith<$Res>(_self.property!, (value) {
    return _then(_self.copyWith(property: value));
  });
}
}


/// Adds pattern-matching-related methods to [Room].
extension RoomPatterns on Room {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Room value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Room value)  $default,){
final _that = this;
switch (_that) {
case _Room():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Room value)?  $default,){
final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String roomNumber,  String sharingType,  int rentAmount,  String status,  String gender,  String unitType,  bool isDisabledForRent,  bool isPublished,  String? availableFrom,  PropertySummary? property,  List<Bed> beds,  List<String> images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.roomNumber,_that.sharingType,_that.rentAmount,_that.status,_that.gender,_that.unitType,_that.isDisabledForRent,_that.isPublished,_that.availableFrom,_that.property,_that.beds,_that.images);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String roomNumber,  String sharingType,  int rentAmount,  String status,  String gender,  String unitType,  bool isDisabledForRent,  bool isPublished,  String? availableFrom,  PropertySummary? property,  List<Bed> beds,  List<String> images)  $default,) {final _that = this;
switch (_that) {
case _Room():
return $default(_that.id,_that.roomNumber,_that.sharingType,_that.rentAmount,_that.status,_that.gender,_that.unitType,_that.isDisabledForRent,_that.isPublished,_that.availableFrom,_that.property,_that.beds,_that.images);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String roomNumber,  String sharingType,  int rentAmount,  String status,  String gender,  String unitType,  bool isDisabledForRent,  bool isPublished,  String? availableFrom,  PropertySummary? property,  List<Bed> beds,  List<String> images)?  $default,) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.roomNumber,_that.sharingType,_that.rentAmount,_that.status,_that.gender,_that.unitType,_that.isDisabledForRent,_that.isPublished,_that.availableFrom,_that.property,_that.beds,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Room implements Room {
  const _Room({required this.id, required this.roomNumber, required this.sharingType, required this.rentAmount, required this.status, this.gender = 'UNISEX', this.unitType = 'Room', this.isDisabledForRent = false, this.isPublished = true, this.availableFrom, this.property, this.beds = const [], this.images = const []});
  factory _Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

@override final  String id;
@override final  String roomNumber;
@override final  String sharingType;
@override final  int rentAmount;
@override final  String status;
@override@JsonKey() final  String gender;
@override@JsonKey() final  String unitType;
@override@JsonKey() final  bool isDisabledForRent;
@override@JsonKey() final  bool isPublished;
@override final  String? availableFrom;
@override final  PropertySummary? property;
@override@JsonKey() final  List<Bed> beds;
@override@JsonKey() final  List<String> images;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomCopyWith<_Room> get copyWith => __$RoomCopyWithImpl<_Room>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Room&&(identical(other.id, id) || other.id == id)&&(identical(other.roomNumber, roomNumber) || other.roomNumber == roomNumber)&&(identical(other.sharingType, sharingType) || other.sharingType == sharingType)&&(identical(other.rentAmount, rentAmount) || other.rentAmount == rentAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.unitType, unitType) || other.unitType == unitType)&&(identical(other.isDisabledForRent, isDisabledForRent) || other.isDisabledForRent == isDisabledForRent)&&(identical(other.isPublished, isPublished) || other.isPublished == isPublished)&&(identical(other.availableFrom, availableFrom) || other.availableFrom == availableFrom)&&(identical(other.property, property) || other.property == property)&&const DeepCollectionEquality().equals(other.beds, beds)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomNumber,sharingType,rentAmount,status,gender,unitType,isDisabledForRent,isPublished,availableFrom,property,const DeepCollectionEquality().hash(beds),const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'Room(id: $id, roomNumber: $roomNumber, sharingType: $sharingType, rentAmount: $rentAmount, status: $status, gender: $gender, unitType: $unitType, isDisabledForRent: $isDisabledForRent, isPublished: $isPublished, availableFrom: $availableFrom, property: $property, beds: $beds, images: $images)';
}


}

/// @nodoc
abstract mixin class _$RoomCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$RoomCopyWith(_Room value, $Res Function(_Room) _then) = __$RoomCopyWithImpl;
@override @useResult
$Res call({
 String id, String roomNumber, String sharingType, int rentAmount, String status, String gender, String unitType, bool isDisabledForRent, bool isPublished, String? availableFrom, PropertySummary? property, List<Bed> beds, List<String> images
});


@override $PropertySummaryCopyWith<$Res>? get property;

}
/// @nodoc
class __$RoomCopyWithImpl<$Res>
    implements _$RoomCopyWith<$Res> {
  __$RoomCopyWithImpl(this._self, this._then);

  final _Room _self;
  final $Res Function(_Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomNumber = null,Object? sharingType = null,Object? rentAmount = null,Object? status = null,Object? gender = null,Object? unitType = null,Object? isDisabledForRent = null,Object? isPublished = null,Object? availableFrom = freezed,Object? property = freezed,Object? beds = null,Object? images = null,}) {
  return _then(_Room(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomNumber: null == roomNumber ? _self.roomNumber : roomNumber // ignore: cast_nullable_to_non_nullable
as String,sharingType: null == sharingType ? _self.sharingType : sharingType // ignore: cast_nullable_to_non_nullable
as String,rentAmount: null == rentAmount ? _self.rentAmount : rentAmount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,unitType: null == unitType ? _self.unitType : unitType // ignore: cast_nullable_to_non_nullable
as String,isDisabledForRent: null == isDisabledForRent ? _self.isDisabledForRent : isDisabledForRent // ignore: cast_nullable_to_non_nullable
as bool,isPublished: null == isPublished ? _self.isPublished : isPublished // ignore: cast_nullable_to_non_nullable
as bool,availableFrom: freezed == availableFrom ? _self.availableFrom : availableFrom // ignore: cast_nullable_to_non_nullable
as String?,property: freezed == property ? _self.property : property // ignore: cast_nullable_to_non_nullable
as PropertySummary?,beds: null == beds ? _self.beds : beds // ignore: cast_nullable_to_non_nullable
as List<Bed>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PropertySummaryCopyWith<$Res>? get property {
    if (_self.property == null) {
    return null;
  }

  return $PropertySummaryCopyWith<$Res>(_self.property!, (value) {
    return _then(_self.copyWith(property: value));
  });
}
}


/// @nodoc
mixin _$PropertySummary {

 String get id; String get name; String get type; String? get timezone;
/// Create a copy of PropertySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertySummaryCopyWith<PropertySummary> get copyWith => _$PropertySummaryCopyWithImpl<PropertySummary>(this as PropertySummary, _$identity);

  /// Serializes this PropertySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PropertySummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.timezone, timezone) || other.timezone == timezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,timezone);

@override
String toString() {
  return 'PropertySummary(id: $id, name: $name, type: $type, timezone: $timezone)';
}


}

/// @nodoc
abstract mixin class $PropertySummaryCopyWith<$Res>  {
  factory $PropertySummaryCopyWith(PropertySummary value, $Res Function(PropertySummary) _then) = _$PropertySummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String type, String? timezone
});




}
/// @nodoc
class _$PropertySummaryCopyWithImpl<$Res>
    implements $PropertySummaryCopyWith<$Res> {
  _$PropertySummaryCopyWithImpl(this._self, this._then);

  final PropertySummary _self;
  final $Res Function(PropertySummary) _then;

/// Create a copy of PropertySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? timezone = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PropertySummary].
extension PropertySummaryPatterns on PropertySummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PropertySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PropertySummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PropertySummary value)  $default,){
final _that = this;
switch (_that) {
case _PropertySummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PropertySummary value)?  $default,){
final _that = this;
switch (_that) {
case _PropertySummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  String? timezone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PropertySummary() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.timezone);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  String? timezone)  $default,) {final _that = this;
switch (_that) {
case _PropertySummary():
return $default(_that.id,_that.name,_that.type,_that.timezone);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  String? timezone)?  $default,) {final _that = this;
switch (_that) {
case _PropertySummary() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.timezone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PropertySummary implements PropertySummary {
  const _PropertySummary({required this.id, required this.name, required this.type, this.timezone});
  factory _PropertySummary.fromJson(Map<String, dynamic> json) => _$PropertySummaryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String type;
@override final  String? timezone;

/// Create a copy of PropertySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertySummaryCopyWith<_PropertySummary> get copyWith => __$PropertySummaryCopyWithImpl<_PropertySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PropertySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PropertySummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.timezone, timezone) || other.timezone == timezone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,timezone);

@override
String toString() {
  return 'PropertySummary(id: $id, name: $name, type: $type, timezone: $timezone)';
}


}

/// @nodoc
abstract mixin class _$PropertySummaryCopyWith<$Res> implements $PropertySummaryCopyWith<$Res> {
  factory _$PropertySummaryCopyWith(_PropertySummary value, $Res Function(_PropertySummary) _then) = __$PropertySummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String type, String? timezone
});




}
/// @nodoc
class __$PropertySummaryCopyWithImpl<$Res>
    implements _$PropertySummaryCopyWith<$Res> {
  __$PropertySummaryCopyWithImpl(this._self, this._then);

  final _PropertySummary _self;
  final $Res Function(_PropertySummary) _then;

/// Create a copy of PropertySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? timezone = freezed,}) {
  return _then(_PropertySummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Bed {

 String get id; String get bedNumber; String get status;
/// Create a copy of Bed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BedCopyWith<Bed> get copyWith => _$BedCopyWithImpl<Bed>(this as Bed, _$identity);

  /// Serializes this Bed to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bed&&(identical(other.id, id) || other.id == id)&&(identical(other.bedNumber, bedNumber) || other.bedNumber == bedNumber)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bedNumber,status);

@override
String toString() {
  return 'Bed(id: $id, bedNumber: $bedNumber, status: $status)';
}


}

/// @nodoc
abstract mixin class $BedCopyWith<$Res>  {
  factory $BedCopyWith(Bed value, $Res Function(Bed) _then) = _$BedCopyWithImpl;
@useResult
$Res call({
 String id, String bedNumber, String status
});




}
/// @nodoc
class _$BedCopyWithImpl<$Res>
    implements $BedCopyWith<$Res> {
  _$BedCopyWithImpl(this._self, this._then);

  final Bed _self;
  final $Res Function(Bed) _then;

/// Create a copy of Bed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bedNumber = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bedNumber: null == bedNumber ? _self.bedNumber : bedNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Bed].
extension BedPatterns on Bed {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bed value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bed() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bed value)  $default,){
final _that = this;
switch (_that) {
case _Bed():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bed value)?  $default,){
final _that = this;
switch (_that) {
case _Bed() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bedNumber,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Bed() when $default != null:
return $default(_that.id,_that.bedNumber,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bedNumber,  String status)  $default,) {final _that = this;
switch (_that) {
case _Bed():
return $default(_that.id,_that.bedNumber,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bedNumber,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Bed() when $default != null:
return $default(_that.id,_that.bedNumber,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Bed implements Bed {
  const _Bed({required this.id, required this.bedNumber, required this.status});
  factory _Bed.fromJson(Map<String, dynamic> json) => _$BedFromJson(json);

@override final  String id;
@override final  String bedNumber;
@override final  String status;

/// Create a copy of Bed
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BedCopyWith<_Bed> get copyWith => __$BedCopyWithImpl<_Bed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bed&&(identical(other.id, id) || other.id == id)&&(identical(other.bedNumber, bedNumber) || other.bedNumber == bedNumber)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bedNumber,status);

@override
String toString() {
  return 'Bed(id: $id, bedNumber: $bedNumber, status: $status)';
}


}

/// @nodoc
abstract mixin class _$BedCopyWith<$Res> implements $BedCopyWith<$Res> {
  factory _$BedCopyWith(_Bed value, $Res Function(_Bed) _then) = __$BedCopyWithImpl;
@override @useResult
$Res call({
 String id, String bedNumber, String status
});




}
/// @nodoc
class __$BedCopyWithImpl<$Res>
    implements _$BedCopyWith<$Res> {
  __$BedCopyWithImpl(this._self, this._then);

  final _Bed _self;
  final $Res Function(_Bed) _then;

/// Create a copy of Bed
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bedNumber = null,Object? status = null,}) {
  return _then(_Bed(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bedNumber: null == bedNumber ? _self.bedNumber : bedNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Resident {

 String get id; String get firstName; String? get lastName; String get mobile; String? get email; String? get whatsappNumber; String? get emergencyContact; String? get permanentAddress; String? get parentName; String? get parentPhone; String? get idProofUrl; String? get agreementUrl; String? get profession; int get monthlyRent; int get securityDeposit; int? get rentDueDay; String? get propertyId; String? get roomId; String? get bedId; String? get joiningDate; String? get status; String? get notes; TenantRoomSummary? get room; TenantBedSummary? get bed; int get dues;
/// Create a copy of Resident
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResidentCopyWith<Resident> get copyWith => _$ResidentCopyWithImpl<Resident>(this as Resident, _$identity);

  /// Serializes this Resident to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Resident&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.mobile, mobile) || other.mobile == mobile)&&(identical(other.email, email) || other.email == email)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact)&&(identical(other.permanentAddress, permanentAddress) || other.permanentAddress == permanentAddress)&&(identical(other.parentName, parentName) || other.parentName == parentName)&&(identical(other.parentPhone, parentPhone) || other.parentPhone == parentPhone)&&(identical(other.idProofUrl, idProofUrl) || other.idProofUrl == idProofUrl)&&(identical(other.agreementUrl, agreementUrl) || other.agreementUrl == agreementUrl)&&(identical(other.profession, profession) || other.profession == profession)&&(identical(other.monthlyRent, monthlyRent) || other.monthlyRent == monthlyRent)&&(identical(other.securityDeposit, securityDeposit) || other.securityDeposit == securityDeposit)&&(identical(other.rentDueDay, rentDueDay) || other.rentDueDay == rentDueDay)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.bedId, bedId) || other.bedId == bedId)&&(identical(other.joiningDate, joiningDate) || other.joiningDate == joiningDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.room, room) || other.room == room)&&(identical(other.bed, bed) || other.bed == bed)&&(identical(other.dues, dues) || other.dues == dues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,firstName,lastName,mobile,email,whatsappNumber,emergencyContact,permanentAddress,parentName,parentPhone,idProofUrl,agreementUrl,profession,monthlyRent,securityDeposit,rentDueDay,propertyId,roomId,bedId,joiningDate,status,notes,room,bed,dues]);

@override
String toString() {
  return 'Resident(id: $id, firstName: $firstName, lastName: $lastName, mobile: $mobile, email: $email, whatsappNumber: $whatsappNumber, emergencyContact: $emergencyContact, permanentAddress: $permanentAddress, parentName: $parentName, parentPhone: $parentPhone, idProofUrl: $idProofUrl, agreementUrl: $agreementUrl, profession: $profession, monthlyRent: $monthlyRent, securityDeposit: $securityDeposit, rentDueDay: $rentDueDay, propertyId: $propertyId, roomId: $roomId, bedId: $bedId, joiningDate: $joiningDate, status: $status, notes: $notes, room: $room, bed: $bed, dues: $dues)';
}


}

/// @nodoc
abstract mixin class $ResidentCopyWith<$Res>  {
  factory $ResidentCopyWith(Resident value, $Res Function(Resident) _then) = _$ResidentCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String? lastName, String mobile, String? email, String? whatsappNumber, String? emergencyContact, String? permanentAddress, String? parentName, String? parentPhone, String? idProofUrl, String? agreementUrl, String? profession, int monthlyRent, int securityDeposit, int? rentDueDay, String? propertyId, String? roomId, String? bedId, String? joiningDate, String? status, String? notes, TenantRoomSummary? room, TenantBedSummary? bed, int dues
});


$TenantRoomSummaryCopyWith<$Res>? get room;$TenantBedSummaryCopyWith<$Res>? get bed;

}
/// @nodoc
class _$ResidentCopyWithImpl<$Res>
    implements $ResidentCopyWith<$Res> {
  _$ResidentCopyWithImpl(this._self, this._then);

  final Resident _self;
  final $Res Function(Resident) _then;

/// Create a copy of Resident
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? lastName = freezed,Object? mobile = null,Object? email = freezed,Object? whatsappNumber = freezed,Object? emergencyContact = freezed,Object? permanentAddress = freezed,Object? parentName = freezed,Object? parentPhone = freezed,Object? idProofUrl = freezed,Object? agreementUrl = freezed,Object? profession = freezed,Object? monthlyRent = null,Object? securityDeposit = null,Object? rentDueDay = freezed,Object? propertyId = freezed,Object? roomId = freezed,Object? bedId = freezed,Object? joiningDate = freezed,Object? status = freezed,Object? notes = freezed,Object? room = freezed,Object? bed = freezed,Object? dues = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,mobile: null == mobile ? _self.mobile : mobile // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,whatsappNumber: freezed == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String?,emergencyContact: freezed == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as String?,permanentAddress: freezed == permanentAddress ? _self.permanentAddress : permanentAddress // ignore: cast_nullable_to_non_nullable
as String?,parentName: freezed == parentName ? _self.parentName : parentName // ignore: cast_nullable_to_non_nullable
as String?,parentPhone: freezed == parentPhone ? _self.parentPhone : parentPhone // ignore: cast_nullable_to_non_nullable
as String?,idProofUrl: freezed == idProofUrl ? _self.idProofUrl : idProofUrl // ignore: cast_nullable_to_non_nullable
as String?,agreementUrl: freezed == agreementUrl ? _self.agreementUrl : agreementUrl // ignore: cast_nullable_to_non_nullable
as String?,profession: freezed == profession ? _self.profession : profession // ignore: cast_nullable_to_non_nullable
as String?,monthlyRent: null == monthlyRent ? _self.monthlyRent : monthlyRent // ignore: cast_nullable_to_non_nullable
as int,securityDeposit: null == securityDeposit ? _self.securityDeposit : securityDeposit // ignore: cast_nullable_to_non_nullable
as int,rentDueDay: freezed == rentDueDay ? _self.rentDueDay : rentDueDay // ignore: cast_nullable_to_non_nullable
as int?,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,bedId: freezed == bedId ? _self.bedId : bedId // ignore: cast_nullable_to_non_nullable
as String?,joiningDate: freezed == joiningDate ? _self.joiningDate : joiningDate // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as TenantRoomSummary?,bed: freezed == bed ? _self.bed : bed // ignore: cast_nullable_to_non_nullable
as TenantBedSummary?,dues: null == dues ? _self.dues : dues // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Resident
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TenantRoomSummaryCopyWith<$Res>? get room {
    if (_self.room == null) {
    return null;
  }

  return $TenantRoomSummaryCopyWith<$Res>(_self.room!, (value) {
    return _then(_self.copyWith(room: value));
  });
}/// Create a copy of Resident
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TenantBedSummaryCopyWith<$Res>? get bed {
    if (_self.bed == null) {
    return null;
  }

  return $TenantBedSummaryCopyWith<$Res>(_self.bed!, (value) {
    return _then(_self.copyWith(bed: value));
  });
}
}


/// Adds pattern-matching-related methods to [Resident].
extension ResidentPatterns on Resident {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Resident value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Resident() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Resident value)  $default,){
final _that = this;
switch (_that) {
case _Resident():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Resident value)?  $default,){
final _that = this;
switch (_that) {
case _Resident() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String firstName,  String? lastName,  String mobile,  String? email,  String? whatsappNumber,  String? emergencyContact,  String? permanentAddress,  String? parentName,  String? parentPhone,  String? idProofUrl,  String? agreementUrl,  String? profession,  int monthlyRent,  int securityDeposit,  int? rentDueDay,  String? propertyId,  String? roomId,  String? bedId,  String? joiningDate,  String? status,  String? notes,  TenantRoomSummary? room,  TenantBedSummary? bed,  int dues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Resident() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.mobile,_that.email,_that.whatsappNumber,_that.emergencyContact,_that.permanentAddress,_that.parentName,_that.parentPhone,_that.idProofUrl,_that.agreementUrl,_that.profession,_that.monthlyRent,_that.securityDeposit,_that.rentDueDay,_that.propertyId,_that.roomId,_that.bedId,_that.joiningDate,_that.status,_that.notes,_that.room,_that.bed,_that.dues);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String firstName,  String? lastName,  String mobile,  String? email,  String? whatsappNumber,  String? emergencyContact,  String? permanentAddress,  String? parentName,  String? parentPhone,  String? idProofUrl,  String? agreementUrl,  String? profession,  int monthlyRent,  int securityDeposit,  int? rentDueDay,  String? propertyId,  String? roomId,  String? bedId,  String? joiningDate,  String? status,  String? notes,  TenantRoomSummary? room,  TenantBedSummary? bed,  int dues)  $default,) {final _that = this;
switch (_that) {
case _Resident():
return $default(_that.id,_that.firstName,_that.lastName,_that.mobile,_that.email,_that.whatsappNumber,_that.emergencyContact,_that.permanentAddress,_that.parentName,_that.parentPhone,_that.idProofUrl,_that.agreementUrl,_that.profession,_that.monthlyRent,_that.securityDeposit,_that.rentDueDay,_that.propertyId,_that.roomId,_that.bedId,_that.joiningDate,_that.status,_that.notes,_that.room,_that.bed,_that.dues);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String firstName,  String? lastName,  String mobile,  String? email,  String? whatsappNumber,  String? emergencyContact,  String? permanentAddress,  String? parentName,  String? parentPhone,  String? idProofUrl,  String? agreementUrl,  String? profession,  int monthlyRent,  int securityDeposit,  int? rentDueDay,  String? propertyId,  String? roomId,  String? bedId,  String? joiningDate,  String? status,  String? notes,  TenantRoomSummary? room,  TenantBedSummary? bed,  int dues)?  $default,) {final _that = this;
switch (_that) {
case _Resident() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.mobile,_that.email,_that.whatsappNumber,_that.emergencyContact,_that.permanentAddress,_that.parentName,_that.parentPhone,_that.idProofUrl,_that.agreementUrl,_that.profession,_that.monthlyRent,_that.securityDeposit,_that.rentDueDay,_that.propertyId,_that.roomId,_that.bedId,_that.joiningDate,_that.status,_that.notes,_that.room,_that.bed,_that.dues);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Resident implements Resident {
  const _Resident({required this.id, required this.firstName, this.lastName, required this.mobile, this.email, this.whatsappNumber, this.emergencyContact, this.permanentAddress, this.parentName, this.parentPhone, this.idProofUrl, this.agreementUrl, this.profession, required this.monthlyRent, this.securityDeposit = 0, this.rentDueDay, this.propertyId, this.roomId, this.bedId, this.joiningDate, this.status, this.notes, this.room, this.bed, this.dues = 0});
  factory _Resident.fromJson(Map<String, dynamic> json) => _$ResidentFromJson(json);

@override final  String id;
@override final  String firstName;
@override final  String? lastName;
@override final  String mobile;
@override final  String? email;
@override final  String? whatsappNumber;
@override final  String? emergencyContact;
@override final  String? permanentAddress;
@override final  String? parentName;
@override final  String? parentPhone;
@override final  String? idProofUrl;
@override final  String? agreementUrl;
@override final  String? profession;
@override final  int monthlyRent;
@override@JsonKey() final  int securityDeposit;
@override final  int? rentDueDay;
@override final  String? propertyId;
@override final  String? roomId;
@override final  String? bedId;
@override final  String? joiningDate;
@override final  String? status;
@override final  String? notes;
@override final  TenantRoomSummary? room;
@override final  TenantBedSummary? bed;
@override@JsonKey() final  int dues;

/// Create a copy of Resident
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResidentCopyWith<_Resident> get copyWith => __$ResidentCopyWithImpl<_Resident>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResidentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Resident&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.mobile, mobile) || other.mobile == mobile)&&(identical(other.email, email) || other.email == email)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&(identical(other.emergencyContact, emergencyContact) || other.emergencyContact == emergencyContact)&&(identical(other.permanentAddress, permanentAddress) || other.permanentAddress == permanentAddress)&&(identical(other.parentName, parentName) || other.parentName == parentName)&&(identical(other.parentPhone, parentPhone) || other.parentPhone == parentPhone)&&(identical(other.idProofUrl, idProofUrl) || other.idProofUrl == idProofUrl)&&(identical(other.agreementUrl, agreementUrl) || other.agreementUrl == agreementUrl)&&(identical(other.profession, profession) || other.profession == profession)&&(identical(other.monthlyRent, monthlyRent) || other.monthlyRent == monthlyRent)&&(identical(other.securityDeposit, securityDeposit) || other.securityDeposit == securityDeposit)&&(identical(other.rentDueDay, rentDueDay) || other.rentDueDay == rentDueDay)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.bedId, bedId) || other.bedId == bedId)&&(identical(other.joiningDate, joiningDate) || other.joiningDate == joiningDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.room, room) || other.room == room)&&(identical(other.bed, bed) || other.bed == bed)&&(identical(other.dues, dues) || other.dues == dues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,firstName,lastName,mobile,email,whatsappNumber,emergencyContact,permanentAddress,parentName,parentPhone,idProofUrl,agreementUrl,profession,monthlyRent,securityDeposit,rentDueDay,propertyId,roomId,bedId,joiningDate,status,notes,room,bed,dues]);

@override
String toString() {
  return 'Resident(id: $id, firstName: $firstName, lastName: $lastName, mobile: $mobile, email: $email, whatsappNumber: $whatsappNumber, emergencyContact: $emergencyContact, permanentAddress: $permanentAddress, parentName: $parentName, parentPhone: $parentPhone, idProofUrl: $idProofUrl, agreementUrl: $agreementUrl, profession: $profession, monthlyRent: $monthlyRent, securityDeposit: $securityDeposit, rentDueDay: $rentDueDay, propertyId: $propertyId, roomId: $roomId, bedId: $bedId, joiningDate: $joiningDate, status: $status, notes: $notes, room: $room, bed: $bed, dues: $dues)';
}


}

/// @nodoc
abstract mixin class _$ResidentCopyWith<$Res> implements $ResidentCopyWith<$Res> {
  factory _$ResidentCopyWith(_Resident value, $Res Function(_Resident) _then) = __$ResidentCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String? lastName, String mobile, String? email, String? whatsappNumber, String? emergencyContact, String? permanentAddress, String? parentName, String? parentPhone, String? idProofUrl, String? agreementUrl, String? profession, int monthlyRent, int securityDeposit, int? rentDueDay, String? propertyId, String? roomId, String? bedId, String? joiningDate, String? status, String? notes, TenantRoomSummary? room, TenantBedSummary? bed, int dues
});


@override $TenantRoomSummaryCopyWith<$Res>? get room;@override $TenantBedSummaryCopyWith<$Res>? get bed;

}
/// @nodoc
class __$ResidentCopyWithImpl<$Res>
    implements _$ResidentCopyWith<$Res> {
  __$ResidentCopyWithImpl(this._self, this._then);

  final _Resident _self;
  final $Res Function(_Resident) _then;

/// Create a copy of Resident
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? lastName = freezed,Object? mobile = null,Object? email = freezed,Object? whatsappNumber = freezed,Object? emergencyContact = freezed,Object? permanentAddress = freezed,Object? parentName = freezed,Object? parentPhone = freezed,Object? idProofUrl = freezed,Object? agreementUrl = freezed,Object? profession = freezed,Object? monthlyRent = null,Object? securityDeposit = null,Object? rentDueDay = freezed,Object? propertyId = freezed,Object? roomId = freezed,Object? bedId = freezed,Object? joiningDate = freezed,Object? status = freezed,Object? notes = freezed,Object? room = freezed,Object? bed = freezed,Object? dues = null,}) {
  return _then(_Resident(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,mobile: null == mobile ? _self.mobile : mobile // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,whatsappNumber: freezed == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String?,emergencyContact: freezed == emergencyContact ? _self.emergencyContact : emergencyContact // ignore: cast_nullable_to_non_nullable
as String?,permanentAddress: freezed == permanentAddress ? _self.permanentAddress : permanentAddress // ignore: cast_nullable_to_non_nullable
as String?,parentName: freezed == parentName ? _self.parentName : parentName // ignore: cast_nullable_to_non_nullable
as String?,parentPhone: freezed == parentPhone ? _self.parentPhone : parentPhone // ignore: cast_nullable_to_non_nullable
as String?,idProofUrl: freezed == idProofUrl ? _self.idProofUrl : idProofUrl // ignore: cast_nullable_to_non_nullable
as String?,agreementUrl: freezed == agreementUrl ? _self.agreementUrl : agreementUrl // ignore: cast_nullable_to_non_nullable
as String?,profession: freezed == profession ? _self.profession : profession // ignore: cast_nullable_to_non_nullable
as String?,monthlyRent: null == monthlyRent ? _self.monthlyRent : monthlyRent // ignore: cast_nullable_to_non_nullable
as int,securityDeposit: null == securityDeposit ? _self.securityDeposit : securityDeposit // ignore: cast_nullable_to_non_nullable
as int,rentDueDay: freezed == rentDueDay ? _self.rentDueDay : rentDueDay // ignore: cast_nullable_to_non_nullable
as int?,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,bedId: freezed == bedId ? _self.bedId : bedId // ignore: cast_nullable_to_non_nullable
as String?,joiningDate: freezed == joiningDate ? _self.joiningDate : joiningDate // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as TenantRoomSummary?,bed: freezed == bed ? _self.bed : bed // ignore: cast_nullable_to_non_nullable
as TenantBedSummary?,dues: null == dues ? _self.dues : dues // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Resident
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TenantRoomSummaryCopyWith<$Res>? get room {
    if (_self.room == null) {
    return null;
  }

  return $TenantRoomSummaryCopyWith<$Res>(_self.room!, (value) {
    return _then(_self.copyWith(room: value));
  });
}/// Create a copy of Resident
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TenantBedSummaryCopyWith<$Res>? get bed {
    if (_self.bed == null) {
    return null;
  }

  return $TenantBedSummaryCopyWith<$Res>(_self.bed!, (value) {
    return _then(_self.copyWith(bed: value));
  });
}
}


/// @nodoc
mixin _$TenantRoomSummary {

 String get id; String get roomNumber; String? get floor; String? get sharingType;
/// Create a copy of TenantRoomSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantRoomSummaryCopyWith<TenantRoomSummary> get copyWith => _$TenantRoomSummaryCopyWithImpl<TenantRoomSummary>(this as TenantRoomSummary, _$identity);

  /// Serializes this TenantRoomSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TenantRoomSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.roomNumber, roomNumber) || other.roomNumber == roomNumber)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.sharingType, sharingType) || other.sharingType == sharingType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomNumber,floor,sharingType);

@override
String toString() {
  return 'TenantRoomSummary(id: $id, roomNumber: $roomNumber, floor: $floor, sharingType: $sharingType)';
}


}

/// @nodoc
abstract mixin class $TenantRoomSummaryCopyWith<$Res>  {
  factory $TenantRoomSummaryCopyWith(TenantRoomSummary value, $Res Function(TenantRoomSummary) _then) = _$TenantRoomSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String roomNumber, String? floor, String? sharingType
});




}
/// @nodoc
class _$TenantRoomSummaryCopyWithImpl<$Res>
    implements $TenantRoomSummaryCopyWith<$Res> {
  _$TenantRoomSummaryCopyWithImpl(this._self, this._then);

  final TenantRoomSummary _self;
  final $Res Function(TenantRoomSummary) _then;

/// Create a copy of TenantRoomSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomNumber = null,Object? floor = freezed,Object? sharingType = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomNumber: null == roomNumber ? _self.roomNumber : roomNumber // ignore: cast_nullable_to_non_nullable
as String,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,sharingType: freezed == sharingType ? _self.sharingType : sharingType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TenantRoomSummary].
extension TenantRoomSummaryPatterns on TenantRoomSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TenantRoomSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TenantRoomSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TenantRoomSummary value)  $default,){
final _that = this;
switch (_that) {
case _TenantRoomSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TenantRoomSummary value)?  $default,){
final _that = this;
switch (_that) {
case _TenantRoomSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String roomNumber,  String? floor,  String? sharingType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TenantRoomSummary() when $default != null:
return $default(_that.id,_that.roomNumber,_that.floor,_that.sharingType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String roomNumber,  String? floor,  String? sharingType)  $default,) {final _that = this;
switch (_that) {
case _TenantRoomSummary():
return $default(_that.id,_that.roomNumber,_that.floor,_that.sharingType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String roomNumber,  String? floor,  String? sharingType)?  $default,) {final _that = this;
switch (_that) {
case _TenantRoomSummary() when $default != null:
return $default(_that.id,_that.roomNumber,_that.floor,_that.sharingType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TenantRoomSummary implements TenantRoomSummary {
  const _TenantRoomSummary({required this.id, required this.roomNumber, this.floor, this.sharingType});
  factory _TenantRoomSummary.fromJson(Map<String, dynamic> json) => _$TenantRoomSummaryFromJson(json);

@override final  String id;
@override final  String roomNumber;
@override final  String? floor;
@override final  String? sharingType;

/// Create a copy of TenantRoomSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantRoomSummaryCopyWith<_TenantRoomSummary> get copyWith => __$TenantRoomSummaryCopyWithImpl<_TenantRoomSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TenantRoomSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TenantRoomSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.roomNumber, roomNumber) || other.roomNumber == roomNumber)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.sharingType, sharingType) || other.sharingType == sharingType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomNumber,floor,sharingType);

@override
String toString() {
  return 'TenantRoomSummary(id: $id, roomNumber: $roomNumber, floor: $floor, sharingType: $sharingType)';
}


}

/// @nodoc
abstract mixin class _$TenantRoomSummaryCopyWith<$Res> implements $TenantRoomSummaryCopyWith<$Res> {
  factory _$TenantRoomSummaryCopyWith(_TenantRoomSummary value, $Res Function(_TenantRoomSummary) _then) = __$TenantRoomSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String roomNumber, String? floor, String? sharingType
});




}
/// @nodoc
class __$TenantRoomSummaryCopyWithImpl<$Res>
    implements _$TenantRoomSummaryCopyWith<$Res> {
  __$TenantRoomSummaryCopyWithImpl(this._self, this._then);

  final _TenantRoomSummary _self;
  final $Res Function(_TenantRoomSummary) _then;

/// Create a copy of TenantRoomSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomNumber = null,Object? floor = freezed,Object? sharingType = freezed,}) {
  return _then(_TenantRoomSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomNumber: null == roomNumber ? _self.roomNumber : roomNumber // ignore: cast_nullable_to_non_nullable
as String,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,sharingType: freezed == sharingType ? _self.sharingType : sharingType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TenantBedSummary {

 String get id; String get bedNumber;
/// Create a copy of TenantBedSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantBedSummaryCopyWith<TenantBedSummary> get copyWith => _$TenantBedSummaryCopyWithImpl<TenantBedSummary>(this as TenantBedSummary, _$identity);

  /// Serializes this TenantBedSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TenantBedSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.bedNumber, bedNumber) || other.bedNumber == bedNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bedNumber);

@override
String toString() {
  return 'TenantBedSummary(id: $id, bedNumber: $bedNumber)';
}


}

/// @nodoc
abstract mixin class $TenantBedSummaryCopyWith<$Res>  {
  factory $TenantBedSummaryCopyWith(TenantBedSummary value, $Res Function(TenantBedSummary) _then) = _$TenantBedSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String bedNumber
});




}
/// @nodoc
class _$TenantBedSummaryCopyWithImpl<$Res>
    implements $TenantBedSummaryCopyWith<$Res> {
  _$TenantBedSummaryCopyWithImpl(this._self, this._then);

  final TenantBedSummary _self;
  final $Res Function(TenantBedSummary) _then;

/// Create a copy of TenantBedSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bedNumber = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bedNumber: null == bedNumber ? _self.bedNumber : bedNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TenantBedSummary].
extension TenantBedSummaryPatterns on TenantBedSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TenantBedSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TenantBedSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TenantBedSummary value)  $default,){
final _that = this;
switch (_that) {
case _TenantBedSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TenantBedSummary value)?  $default,){
final _that = this;
switch (_that) {
case _TenantBedSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bedNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TenantBedSummary() when $default != null:
return $default(_that.id,_that.bedNumber);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bedNumber)  $default,) {final _that = this;
switch (_that) {
case _TenantBedSummary():
return $default(_that.id,_that.bedNumber);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bedNumber)?  $default,) {final _that = this;
switch (_that) {
case _TenantBedSummary() when $default != null:
return $default(_that.id,_that.bedNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TenantBedSummary implements TenantBedSummary {
  const _TenantBedSummary({required this.id, required this.bedNumber});
  factory _TenantBedSummary.fromJson(Map<String, dynamic> json) => _$TenantBedSummaryFromJson(json);

@override final  String id;
@override final  String bedNumber;

/// Create a copy of TenantBedSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantBedSummaryCopyWith<_TenantBedSummary> get copyWith => __$TenantBedSummaryCopyWithImpl<_TenantBedSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TenantBedSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TenantBedSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.bedNumber, bedNumber) || other.bedNumber == bedNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bedNumber);

@override
String toString() {
  return 'TenantBedSummary(id: $id, bedNumber: $bedNumber)';
}


}

/// @nodoc
abstract mixin class _$TenantBedSummaryCopyWith<$Res> implements $TenantBedSummaryCopyWith<$Res> {
  factory _$TenantBedSummaryCopyWith(_TenantBedSummary value, $Res Function(_TenantBedSummary) _then) = __$TenantBedSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String bedNumber
});




}
/// @nodoc
class __$TenantBedSummaryCopyWithImpl<$Res>
    implements _$TenantBedSummaryCopyWith<$Res> {
  __$TenantBedSummaryCopyWithImpl(this._self, this._then);

  final _TenantBedSummary _self;
  final $Res Function(_TenantBedSummary) _then;

/// Create a copy of TenantBedSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bedNumber = null,}) {
  return _then(_TenantBedSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bedNumber: null == bedNumber ? _self.bedNumber : bedNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
