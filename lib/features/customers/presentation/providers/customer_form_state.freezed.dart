// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerFormState {

 int get currentStep; String get name; String get phone; String get street; String get apartment; String get floor; String get visualReference; List<CustomerPreference> get preferences; bool get isSubmitting; bool get isSuccess; String? get errorMessage;
/// Create a copy of CustomerFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerFormStateCopyWith<CustomerFormState> get copyWith => _$CustomerFormStateCopyWithImpl<CustomerFormState>(this as CustomerFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerFormState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.street, street) || other.street == street)&&(identical(other.apartment, apartment) || other.apartment == apartment)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.visualReference, visualReference) || other.visualReference == visualReference)&&const DeepCollectionEquality().equals(other.preferences, preferences)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,name,phone,street,apartment,floor,visualReference,const DeepCollectionEquality().hash(preferences),isSubmitting,isSuccess,errorMessage);

@override
String toString() {
  return 'CustomerFormState(currentStep: $currentStep, name: $name, phone: $phone, street: $street, apartment: $apartment, floor: $floor, visualReference: $visualReference, preferences: $preferences, isSubmitting: $isSubmitting, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $CustomerFormStateCopyWith<$Res>  {
  factory $CustomerFormStateCopyWith(CustomerFormState value, $Res Function(CustomerFormState) _then) = _$CustomerFormStateCopyWithImpl;
@useResult
$Res call({
 int currentStep, String name, String phone, String street, String apartment, String floor, String visualReference, List<CustomerPreference> preferences, bool isSubmitting, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class _$CustomerFormStateCopyWithImpl<$Res>
    implements $CustomerFormStateCopyWith<$Res> {
  _$CustomerFormStateCopyWithImpl(this._self, this._then);

  final CustomerFormState _self;
  final $Res Function(CustomerFormState) _then;

/// Create a copy of CustomerFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? name = null,Object? phone = null,Object? street = null,Object? apartment = null,Object? floor = null,Object? visualReference = null,Object? preferences = null,Object? isSubmitting = null,Object? isSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,apartment: null == apartment ? _self.apartment : apartment // ignore: cast_nullable_to_non_nullable
as String,floor: null == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String,visualReference: null == visualReference ? _self.visualReference : visualReference // ignore: cast_nullable_to_non_nullable
as String,preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as List<CustomerPreference>,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerFormState].
extension CustomerFormStatePatterns on CustomerFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerFormState value)  $default,){
final _that = this;
switch (_that) {
case _CustomerFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerFormState value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStep,  String name,  String phone,  String street,  String apartment,  String floor,  String visualReference,  List<CustomerPreference> preferences,  bool isSubmitting,  bool isSuccess,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerFormState() when $default != null:
return $default(_that.currentStep,_that.name,_that.phone,_that.street,_that.apartment,_that.floor,_that.visualReference,_that.preferences,_that.isSubmitting,_that.isSuccess,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStep,  String name,  String phone,  String street,  String apartment,  String floor,  String visualReference,  List<CustomerPreference> preferences,  bool isSubmitting,  bool isSuccess,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _CustomerFormState():
return $default(_that.currentStep,_that.name,_that.phone,_that.street,_that.apartment,_that.floor,_that.visualReference,_that.preferences,_that.isSubmitting,_that.isSuccess,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStep,  String name,  String phone,  String street,  String apartment,  String floor,  String visualReference,  List<CustomerPreference> preferences,  bool isSubmitting,  bool isSuccess,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _CustomerFormState() when $default != null:
return $default(_that.currentStep,_that.name,_that.phone,_that.street,_that.apartment,_that.floor,_that.visualReference,_that.preferences,_that.isSubmitting,_that.isSuccess,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerFormState extends CustomerFormState {
  const _CustomerFormState({this.currentStep = 0, this.name = '', this.phone = '', this.street = '', this.apartment = '', this.floor = '', this.visualReference = '', final  List<CustomerPreference> preferences = const [], this.isSubmitting = false, this.isSuccess = false, this.errorMessage}): _preferences = preferences,super._();
  

@override@JsonKey() final  int currentStep;
@override@JsonKey() final  String name;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String street;
@override@JsonKey() final  String apartment;
@override@JsonKey() final  String floor;
@override@JsonKey() final  String visualReference;
 final  List<CustomerPreference> _preferences;
@override@JsonKey() List<CustomerPreference> get preferences {
  if (_preferences is EqualUnmodifiableListView) return _preferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferences);
}

@override@JsonKey() final  bool isSubmitting;
@override@JsonKey() final  bool isSuccess;
@override final  String? errorMessage;

/// Create a copy of CustomerFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerFormStateCopyWith<_CustomerFormState> get copyWith => __$CustomerFormStateCopyWithImpl<_CustomerFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerFormState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.street, street) || other.street == street)&&(identical(other.apartment, apartment) || other.apartment == apartment)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.visualReference, visualReference) || other.visualReference == visualReference)&&const DeepCollectionEquality().equals(other._preferences, _preferences)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,name,phone,street,apartment,floor,visualReference,const DeepCollectionEquality().hash(_preferences),isSubmitting,isSuccess,errorMessage);

@override
String toString() {
  return 'CustomerFormState(currentStep: $currentStep, name: $name, phone: $phone, street: $street, apartment: $apartment, floor: $floor, visualReference: $visualReference, preferences: $preferences, isSubmitting: $isSubmitting, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$CustomerFormStateCopyWith<$Res> implements $CustomerFormStateCopyWith<$Res> {
  factory _$CustomerFormStateCopyWith(_CustomerFormState value, $Res Function(_CustomerFormState) _then) = __$CustomerFormStateCopyWithImpl;
@override @useResult
$Res call({
 int currentStep, String name, String phone, String street, String apartment, String floor, String visualReference, List<CustomerPreference> preferences, bool isSubmitting, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class __$CustomerFormStateCopyWithImpl<$Res>
    implements _$CustomerFormStateCopyWith<$Res> {
  __$CustomerFormStateCopyWithImpl(this._self, this._then);

  final _CustomerFormState _self;
  final $Res Function(_CustomerFormState) _then;

/// Create a copy of CustomerFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? name = null,Object? phone = null,Object? street = null,Object? apartment = null,Object? floor = null,Object? visualReference = null,Object? preferences = null,Object? isSubmitting = null,Object? isSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_CustomerFormState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,apartment: null == apartment ? _self.apartment : apartment // ignore: cast_nullable_to_non_nullable
as String,floor: null == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String,visualReference: null == visualReference ? _self.visualReference : visualReference // ignore: cast_nullable_to_non_nullable
as String,preferences: null == preferences ? _self._preferences : preferences // ignore: cast_nullable_to_non_nullable
as List<CustomerPreference>,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
