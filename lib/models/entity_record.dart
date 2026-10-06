/// Model for Dynamic Entity Records with 15 Generic Columns Architecture,
/// Reactions, Unlocks Counters, Sections, and Private Verified Photo.
class EntityRecord {
  final String id;
  String title;
  final String entityKey;
  final String sectionKey; // 'rent', 'market', 'delivery', 'labor'
  final String country;
  String approxLocation;
  final String userName;
  final String? userId;
  final bool isVerified;
  final double userAvgRating;
  final int totalReviews;
  final String userLevel; // 'Platinum', 'Gold', 'Silver', 'New'
  final String? userAvatarUrl;

  // Generic 15 Columns System
  String? customCol1;
  String? customCol2;
  String? customCol3;
  String? customCol4;
  String? customCol5;
  String? customCol6; // Often Private (e.g. Phone)
  String? customCol7; // Often Private (e.g. Exact Address)
  String? customCol8;
  String? customCol9;
  String? customCol10;
  String? customCol11;
  String? customCol12;
  String? customCol13;
  String? customCol14;
  String? customCol15;

  Map<String, dynamic> recordColumns;

  // Social & Community Features
  int reactionsCount;
  bool hasUserReacted;
  int acceptedCount; // কতজন এই পোস্ট গ্রহণ / আনলক করেছেন (পাবলিক)

  // Monetization & Author Limits
  bool isUnlocked;
  double unlockPriceUsd;
  String? unlockValidUntil;
  final int authorValidityDays; // Author কর্তৃক নির্দিষ্ট সময়সীমা (যেমন: ৭ দিন)
  final DateTime createdAt;

  EntityRecord({
    required this.id,
    required this.title,
    required this.entityKey,
    this.sectionKey = 'rent',
    required this.country,
    required this.approxLocation,
    required this.userName,
    this.userId,
    this.isVerified = false,
    this.userAvgRating = 5.0,
    this.totalReviews = 0,
    this.userLevel = 'New',
    this.userAvatarUrl,
    this.customCol1,
    this.customCol2,
    this.customCol3,
    this.customCol4,
    this.customCol5,
    this.customCol6,
    this.customCol7,
    this.customCol8,
    this.customCol9,
    this.customCol10,
    this.customCol11,
    this.customCol12,
    this.customCol13,
    this.customCol14,
    this.customCol15,
    Map<String, dynamic>? recordColumns,
    this.reactionsCount = 0,
    this.hasUserReacted = false,
    this.acceptedCount = 0,
    this.isUnlocked = false,
    this.unlockPriceUsd = 1.0,
    this.unlockValidUntil,
    this.authorValidityDays = 7,
    DateTime? createdAt,
  })  : recordColumns = recordColumns ?? {
          'custom_col_1': customCol1,
          'custom_col_2': customCol2,
          'custom_col_3': customCol3,
          'custom_col_4': customCol4,
          'custom_col_5': customCol5,
          'custom_col_6': customCol6,
          'custom_col_7': customCol7,
          'custom_col_8': customCol8,
          'custom_col_9': customCol9,
          'custom_col_10': customCol10,
          'custom_col_11': customCol11,
          'custom_col_12': customCol12,
          'custom_col_13': customCol13,
          'custom_col_14': customCol14,
          'custom_col_15': customCol15,
        },
        createdAt = createdAt ?? DateTime.now();

  factory EntityRecord.fromJson(Map<String, dynamic> json) {
    final cols = (json['record_columns'] as Map<String, dynamic>?) ?? {};

    return EntityRecord(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      entityKey: json['entity_key']?.toString() ?? 'vehicles',
      sectionKey: json['section_key']?.toString() ?? 'rent',
      country: json['country']?.toString() ?? 'BD',
      approxLocation: json['approx_location']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['provider_name']?.toString() ?? 'সেবা প্রদানকারী',
      userId: json['user_id']?.toString(),
      isVerified: json['is_verified'] == true,
      userAvgRating: (json['user_avg_rating'] as num?)?.toDouble() ??
          (json['avg_rating'] as num?)?.toDouble() ??
          4.8,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 100,
      userLevel: json['user_level']?.toString() ?? json['level']?.toString() ?? 'Gold',
      userAvatarUrl: json['user_avatar_url']?.toString(),
      customCol1: json['custom_col_1']?.toString() ?? cols['custom_col_1']?.toString(),
      customCol2: json['custom_col_2']?.toString() ?? cols['custom_col_2']?.toString(),
      customCol3: json['custom_col_3']?.toString() ?? cols['custom_col_3']?.toString(),
      customCol4: json['custom_col_4']?.toString() ?? cols['custom_col_4']?.toString(),
      customCol5: json['custom_col_5']?.toString() ?? cols['custom_col_5']?.toString(),
      customCol6: json['custom_col_6']?.toString() ?? cols['custom_col_6']?.toString(),
      customCol7: json['custom_col_7']?.toString() ?? cols['custom_col_7']?.toString(),
      customCol8: json['custom_col_8']?.toString() ?? cols['custom_col_8']?.toString(),
      customCol9: json['custom_col_9']?.toString() ?? cols['custom_col_9']?.toString(),
      customCol10: json['custom_col_10']?.toString() ?? cols['custom_col_10']?.toString(),
      customCol11: json['custom_col_11']?.toString() ?? cols['custom_col_11']?.toString(),
      customCol12: json['custom_col_12']?.toString() ?? cols['custom_col_12']?.toString(),
      customCol13: json['custom_col_13']?.toString() ?? cols['custom_col_13']?.toString(),
      customCol14: json['custom_col_14']?.toString() ?? cols['custom_col_14']?.toString(),
      customCol15: json['custom_col_15']?.toString() ?? cols['custom_col_15']?.toString(),
      recordColumns: cols,
      reactionsCount: (json['reactions_count'] as num?)?.toInt() ?? 12,
      hasUserReacted: json['has_user_reacted'] == true,
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? (json['unlocks_count'] as num?)?.toInt() ?? 8,
      isUnlocked: json['is_unlocked'] == true,
      unlockPriceUsd: (json['unlock_price_usd'] as num?)?.toDouble() ?? 1.0,
      unlockValidUntil: json['unlock_valid_until']?.toString(),
      authorValidityDays: (json['author_validity_days'] as num?)?.toInt() ?? 7,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'entity_key': entityKey,
      'section_key': sectionKey,
      'country': country,
      'approx_location': approxLocation,
      'user_name': userName,
      'user_id': userId,
      'is_verified': isVerified,
      'user_avg_rating': userAvgRating,
      'total_reviews': totalReviews,
      'user_level': userLevel,
      'user_avatar_url': userAvatarUrl,
      'custom_col_1': customCol1,
      'custom_col_2': customCol2,
      'custom_col_3': customCol3,
      'custom_col_4': customCol4,
      'custom_col_5': customCol5,
      'custom_col_6': customCol6,
      'custom_col_7': customCol7,
      'custom_col_8': customCol8,
      'custom_col_9': customCol9,
      'custom_col_10': customCol10,
      'custom_col_11': customCol11,
      'custom_col_12': customCol12,
      'custom_col_13': customCol13,
      'custom_col_14': customCol14,
      'custom_col_15': customCol15,
      'record_columns': recordColumns,
      'reactions_count': reactionsCount,
      'has_user_reacted': hasUserReacted,
      'accepted_count': acceptedCount,
      'is_unlocked': isUnlocked,
      'unlock_price_usd': unlockPriceUsd,
      'unlock_valid_until': unlockValidUntil,
      'author_validity_days': authorValidityDays,
      'created_at': createdAt.toIso8601String(),
    };
  }

  EntityRecord copyWith({
    String? id,
    String? title,
    String? entityKey,
    String? sectionKey,
    String? country,
    String? approxLocation,
    String? userName,
    String? userId,
    bool? isVerified,
    double? userAvgRating,
    int? totalReviews,
    String? userLevel,
    String? userAvatarUrl,
    String? customCol1,
    String? customCol2,
    String? customCol3,
    String? customCol4,
    String? customCol5,
    String? customCol6,
    String? customCol7,
    String? customCol8,
    String? customCol9,
    String? customCol10,
    String? customCol11,
    String? customCol12,
    String? customCol13,
    String? customCol14,
    String? customCol15,
    Map<String, dynamic>? recordColumns,
    int? reactionsCount,
    bool? hasUserReacted,
    int? acceptedCount,
    bool? isUnlocked,
    double? unlockPriceUsd,
    String? unlockValidUntil,
    int? authorValidityDays,
    DateTime? createdAt,
  }) {
    return EntityRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      entityKey: entityKey ?? this.entityKey,
      sectionKey: sectionKey ?? this.sectionKey,
      country: country ?? this.country,
      approxLocation: approxLocation ?? this.approxLocation,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      isVerified: isVerified ?? this.isVerified,
      userAvgRating: userAvgRating ?? this.userAvgRating,
      totalReviews: totalReviews ?? this.totalReviews,
      userLevel: userLevel ?? this.userLevel,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      customCol1: customCol1 ?? this.customCol1,
      customCol2: customCol2 ?? this.customCol2,
      customCol3: customCol3 ?? this.customCol3,
      customCol4: customCol4 ?? this.customCol4,
      customCol5: customCol5 ?? this.customCol5,
      customCol6: customCol6 ?? this.customCol6,
      customCol7: customCol7 ?? this.customCol7,
      customCol8: customCol8 ?? this.customCol8,
      customCol9: customCol9 ?? this.customCol9,
      customCol10: customCol10 ?? this.customCol10,
      customCol11: customCol11 ?? this.customCol11,
      customCol12: customCol12 ?? this.customCol12,
      customCol13: customCol13 ?? this.customCol13,
      customCol14: customCol14 ?? this.customCol14,
      customCol15: customCol15 ?? this.customCol15,
      recordColumns: recordColumns ?? this.recordColumns,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      hasUserReacted: hasUserReacted ?? this.hasUserReacted,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockPriceUsd: unlockPriceUsd ?? this.unlockPriceUsd,
      unlockValidUntil: unlockValidUntil ?? this.unlockValidUntil,
      authorValidityDays: authorValidityDays ?? this.authorValidityDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String? getColumnValue(String colKey) {
    if (recordColumns.containsKey(colKey) && recordColumns[colKey] != null) {
      return recordColumns[colKey].toString();
    }
    switch (colKey) {
      case 'custom_col_1':
        return customCol1;
      case 'custom_col_2':
        return customCol2;
      case 'custom_col_3':
        return customCol3;
      case 'custom_col_4':
        return customCol4;
      case 'custom_col_5':
        return customCol5;
      case 'custom_col_6':
        return customCol6;
      case 'custom_col_7':
        return customCol7;
      case 'custom_col_8':
        return customCol8;
      case 'custom_col_9':
        return customCol9;
      case 'custom_col_10':
        return customCol10;
      case 'custom_col_11':
        return customCol11;
      case 'custom_col_12':
        return customCol12;
      case 'custom_col_13':
        return customCol13;
      case 'custom_col_14':
        return customCol14;
      case 'custom_col_15':
        return customCol15;
      default:
        return null;
    }
  }
}

/// Dynamic Column Metadata definition for rendering
class GenericColumnConfig {
  final String colKey;
  final String labelEn;
  final String labelBn;
  final String dataType;
  final bool isPrivate;
  final bool isActive;
  final List<String>? options;

  GenericColumnConfig({
    required this.colKey,
    required this.labelEn,
    required this.labelBn,
    required this.dataType,
    required this.isPrivate,
    required this.isActive,
    this.options,
  });
}
