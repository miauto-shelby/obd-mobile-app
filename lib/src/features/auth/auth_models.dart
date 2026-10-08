class GoogleAuthRequest {
  const GoogleAuthRequest({
    required this.idToken,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
  });

  final String idToken;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String appVersion;

  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'platform': platform,
    'appVersion': appVersion,
  };
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.photoUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String photoUrl;

  String get fullName => '$firstName $lastName';
}

class AuthSession {
  const AuthSession({
    required this.request,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.user,
  });

  final GoogleAuthRequest request;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final AuthUser user;

  factory AuthSession.fromJson(
    Map<String, dynamic> json,
    GoogleAuthRequest request,
  ) {
    final userJson = json['user'] as Map<String, dynamic>? ?? const {};
    return AuthSession(
      request: request,
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: json['expiresIn'] is int
          ? json['expiresIn'] as int
          : int.tryParse(json['expiresIn']?.toString() ?? '') ?? 0,
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      user: AuthUser(
        id: userJson['id']?.toString() ?? '',
        firstName: userJson['name']?.toString() ?? '',
        lastName: userJson['lastName']?.toString() ?? '',
        email: userJson['email']?.toString() ?? '',
        photoUrl: userJson['photoUrl']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toStorageJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'tokenType': tokenType,
    'user': {
      'id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'photoUrl': user.photoUrl,
    },
    'request': request.toJson(),
  };

  factory AuthSession.fromStorageJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? const {};
    final requestJson = json['request'] as Map<String, dynamic>? ?? const {};

    return AuthSession(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: json['expiresIn'] is int
          ? json['expiresIn'] as int
          : int.tryParse(json['expiresIn']?.toString() ?? '') ?? 0,
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      user: AuthUser(
        id: userJson['id']?.toString() ?? '',
        firstName: userJson['firstName']?.toString() ?? '',
        lastName: userJson['lastName']?.toString() ?? '',
        email: userJson['email']?.toString() ?? '',
        photoUrl: userJson['photoUrl']?.toString() ?? '',
      ),
      request: GoogleAuthRequest(
        idToken: '',
        deviceId: requestJson['deviceId']?.toString() ?? '',
        deviceName: requestJson['deviceName']?.toString() ?? '',
        platform: requestJson['platform']?.toString() ?? '',
        appVersion: requestJson['appVersion']?.toString() ?? '',
      ),
    );
  }

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    AuthUser? user,
  }) {
    return AuthSession(
      request: request,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      tokenType: tokenType,
      user: user ?? this.user,
    );
  }
}
