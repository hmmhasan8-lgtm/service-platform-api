class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final bool isVerified;
  final String level;
  final double avgRating;
  final String referralCode;
  final double walletBalance;
  final String? token;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.role = 'user',
    this.isVerified = false,
    this.level = 'Gold',
    this.avgRating = 4.8,
    this.referralCode = 'ARIF123',
    this.walletBalance = 100.0,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? 'ইউজার',
      phone: json['phone_number']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isVerified: json['is_verified'] == true,
      level: json['level']?.toString() ?? 'Gold',
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 4.8,
      referralCode: json['referral_code']?.toString() ?? 'ARIF123',
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 100.0,
      token: json['token']?.toString() ?? json['access_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phone,
      'email': email,
      'role': role,
      'is_verified': isVerified,
      'level': level,
      'avg_rating': avgRating,
      'referral_code': referralCode,
      'wallet_balance': walletBalance,
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? role,
    bool? isVerified,
    String? level,
    double? avgRating,
    String? referralCode,
    double? walletBalance,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      level: level ?? this.level,
      avgRating: avgRating ?? this.avgRating,
      referralCode: referralCode ?? this.referralCode,
      walletBalance: walletBalance ?? this.walletBalance,
      token: token ?? this.token,
    );
  }
}
