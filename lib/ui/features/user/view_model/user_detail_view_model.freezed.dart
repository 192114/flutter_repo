// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_detail_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserDetailUiState {

 User get user; bool get isFavorite;
/// Create a copy of UserDetailUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDetailUiStateCopyWith<UserDetailUiState> get copyWith => _$UserDetailUiStateCopyWithImpl<UserDetailUiState>(this as UserDetailUiState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserDetailUiState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailUiState&&(identical(other.user, _this.user) || other.user == _this.user)&&(identical(other.isFavorite, _this.isFavorite) || other.isFavorite == _this.isFavorite));
}


@override
int get hashCode {
  final _this = this as UserDetailUiState;
  return Object.hash(runtimeType,_this.user,_this.isFavorite);
}

@override
String toString() {
  final _this = this as UserDetailUiState;
  return 'UserDetailUiState(user: ${_this.user}, isFavorite: ${_this.isFavorite})';
}


}

/// @nodoc
abstract mixin class $UserDetailUiStateCopyWith<$Res>  {
  factory $UserDetailUiStateCopyWith(UserDetailUiState value, $Res Function(UserDetailUiState) _then) = _$UserDetailUiStateCopyWithImpl;
@useResult
$Res call({
 User user, bool isFavorite
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$UserDetailUiStateCopyWithImpl<$Res>
    implements $UserDetailUiStateCopyWith<$Res> {
  _$UserDetailUiStateCopyWithImpl(this._self, this._then);

  final UserDetailUiState _self;
  final $Res Function(UserDetailUiState) _then;

/// Create a copy of UserDetailUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? isFavorite = null,}) {
  return _then(UserDetailUiState(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of UserDetailUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserDetailUiState].
extension UserDetailUiStatePatterns on UserDetailUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserDetailUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserDetailUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserDetailUiState value)  $default,){
final _that = this;
switch (_that) {
case _UserDetailUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserDetailUiState value)?  $default,){
final _that = this;
switch (_that) {
case _UserDetailUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( User user,  bool isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserDetailUiState() when $default != null:
return $default(_that.user,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( User user,  bool isFavorite)  $default,) {final _that = this;
switch (_that) {
case _UserDetailUiState():
return $default(_that.user,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( User user,  bool isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _UserDetailUiState() when $default != null:
return $default(_that.user,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc


class _UserDetailUiState implements UserDetailUiState {
  const _UserDetailUiState({required this.user, this.isFavorite = false});
  

@override final  User user;
@override@JsonKey() final  bool isFavorite;

/// Create a copy of UserDetailUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDetailUiStateCopyWith<_UserDetailUiState> get copyWith => __$UserDetailUiStateCopyWithImpl<_UserDetailUiState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserDetailUiState&&(identical(other.user, user) || other.user == user)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode {
    return Object.hash(runtimeType,user,isFavorite);
}

@override
String toString() {
    return 'UserDetailUiState(user: $user, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$UserDetailUiStateCopyWith<$Res> implements $UserDetailUiStateCopyWith<$Res> {
  factory _$UserDetailUiStateCopyWith(_UserDetailUiState value, $Res Function(_UserDetailUiState) _then) = __$UserDetailUiStateCopyWithImpl;
@override @useResult
$Res call({
 User user, bool isFavorite
});


@override $UserCopyWith<$Res> get user;

}
/// @nodoc
class __$UserDetailUiStateCopyWithImpl<$Res>
    implements _$UserDetailUiStateCopyWith<$Res> {
  __$UserDetailUiStateCopyWithImpl(this._self, this._then);

  final _UserDetailUiState _self;
  final $Res Function(_UserDetailUiState) _then;

/// Create a copy of UserDetailUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? isFavorite = null,}) {
  return _then(_UserDetailUiState(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of UserDetailUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
