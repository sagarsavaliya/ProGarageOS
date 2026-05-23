import 'dart:convert';

/// Staff user model — matches POST /auth/staff/login response shape exactly.
/// API returns: uuid, first_name, last_name, email, phone, roles[], tenant{business_name}
class UserModel {
  final String uuid;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // first entry of roles[] array
  final String? phone;
  final String? avatar;
  final String? garageName; // from tenant.business_name
  final String? tenantUuid;

  const UserModel({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.garageName,
    this.tenantUuid,
  });

  String get name => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenant'] as Map<String, dynamic>?;
    final roles = json['roles'] as List<dynamic>?;
    return UserModel(
      uuid: json['uuid'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: roles != null && roles.isNotEmpty
          ? roles.first as String
          : json['role'] as String? ?? 'technician',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String? ?? json['avatar_url'] as String?,
      garageName: tenant?['business_name'] as String? ?? json['garage_name'] as String?,
      tenantUuid: tenant?['uuid'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'role': role,
        if (phone != null) 'phone': phone,
        if (avatar != null) 'avatar': avatar,
        if (garageName != null) 'garage_name': garageName,
        if (tenantUuid != null) 'tenant_uuid': tenantUuid,
      };

  String toJsonString() => jsonEncode(toJson());

  static UserModel? fromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Returns the two-letter initials from the user's full name.
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}

/// Response from POST /auth/staff/login
class StaffAuthResponse {
  final String token;
  final String tokenType;
  final UserModel user;

  const StaffAuthResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory StaffAuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return StaffAuthResponse(
      token: data['token'] as String? ?? data['access_token'] as String,
      tokenType: data['token_type'] as String? ?? 'Bearer',
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

/// Request body for POST /auth/staff/login
class StaffLoginRequest {
  final String login; // email or phone
  final String pin;

  const StaffLoginRequest({required this.login, required this.pin});

  Map<String, dynamic> toJson() => {'login': login, 'pin': pin};
}

/// Request body for POST /auth/staff/pin-otp/request
class StaffPinOtpRequest {
  final String login;
  final String purpose; // setup | reset

  const StaffPinOtpRequest({required this.login, this.purpose = 'reset'});

  Map<String, dynamic> toJson() => {'login': login, 'purpose': purpose};
}

/// Request body for POST /auth/staff/pin-otp/reset
class StaffPinResetRequest {
  final String login;
  final String otp;
  final String pin;

  const StaffPinResetRequest({
    required this.login,
    required this.otp,
    required this.pin,
  });

  Map<String, dynamic> toJson() => {'login': login, 'otp': otp, 'pin': pin};
}

/// Request body for POST /auth/customer/otp/request
class OtpRequestBody {
  final String phone;

  const OtpRequestBody({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

/// Request body for POST /auth/customer/otp/verify
class OtpVerifyRequest {
  final String phone;
  final String otp;
  final String deviceToken;
  final String platform; // 'ios' | 'android'
  final String appVersion;

  const OtpVerifyRequest({
    required this.phone,
    required this.otp,
    this.deviceToken = '',
    this.platform = 'android',
    this.appVersion = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'otp': otp,
        if (deviceToken.isNotEmpty) 'device_token': deviceToken,
        'platform': platform,
        'app_version': appVersion,
      };
}

class SubscriptionPlanModel {
  final String uuid;
  final String name;
  final String slug;
  final double price;
  final int trialDays;
  final String billingCycle;

  const SubscriptionPlanModel({
    required this.uuid,
    required this.name,
    required this.slug,
    required this.price,
    required this.trialDays,
    required this.billingCycle,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) => SubscriptionPlanModel(
        uuid: json['uuid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        trialDays: (json['trial_days'] as num?)?.toInt() ?? 14,
        billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      );
}

class OwnerSignupResult {
  final String login;
  final String businessName;
  final String message;

  const OwnerSignupResult({
    required this.login,
    required this.businessName,
    required this.message,
  });

  factory OwnerSignupResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return OwnerSignupResult(
      login: data['login'] as String? ?? '',
      businessName: data['business_name'] as String? ?? '',
      message: data['message'] as String? ?? 'Account created.',
    );
  }
}

class OwnerSignupRequest {
  final String phone;
  final String firstName;
  final String businessName;
  final String? lastName;
  final String? email;
  final String? planSlug;

  const OwnerSignupRequest({
    required this.phone,
    required this.firstName,
    required this.businessName,
    this.lastName,
    this.email,
    this.planSlug,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'first_name': firstName,
        'business_name': businessName,
        if (lastName != null && lastName!.isNotEmpty) 'last_name': lastName,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (planSlug != null) 'plan_slug': planSlug,
      };
}
