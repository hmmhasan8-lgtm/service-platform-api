/// Model for Dynamic Entity Records with 15 Generic Columns Architecture
/// and Phase 2 Trust & Safety + Gamification Metadata.
class EntityRecord {
  final String id;
  final String title;
  final String entityKey;
  final String country;
  final String approxLocation;
  final String userName;
  final bool isVerified;
  final double userAvgRating;
  final int totalReviews;
  final String userLevel; // 'Platinum', 'Gold', 'Silver', 'New'

  // Generic 15 Columns System
  final String? customCol1;
  final String? customCol2;
  final String? customCol3;
  final String? customCol4;
  final String? customCol5;
  final String? customCol6; // Often Private (e.g. Phone)
  final String? customCol7; // Often Private (e.g. Exact Address)
  final String? customCol8;
  final String? customCol9;
  final String? customCol10;
  final String? customCol11;
  final String? customCol12;
  final String? customCol13;
  final String? customCol14;
  final String? customCol15;

  final Map<String, dynamic> recordColumns;

  // Monetization & Unlock Status
  bool isUnlocked;
  final double unlockPriceUsd;
  String? unlockValidUntil;

  EntityRecord({
    required this.id,
    required this.title,
    required this.entityKey,
    required this.country,
    required this.approxLocation,
    required this.userName,
    this.isVerified = false,
    this.userAvgRating = 5.0,
    this.totalReviews = 0,
    this.userLevel = 'New',
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
    this.isUnlocked = false,
    this.unlockPriceUsd = 1.0,
    this.unlockValidUntil,
  }) : recordColumns = recordColumns ?? {
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
        };

  factory EntityRecord.fromJson(Map<String, dynamic> json) {
    final cols = (json['record_columns'] as Map<String, dynamic>?) ?? {};

    return EntityRecord(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      entityKey: json['entity_key']?.toString() ?? 'vehicles',
      country: json['country']?.toString() ?? 'BD',
      approxLocation: json['approx_location']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['provider_name']?.toString() ?? 'সেবা প্রদানকারী',
      isVerified: json['is_verified'] == true,
      userAvgRating: (json['user_avg_rating'] as num?)?.toDouble() ??
          (json['avg_rating'] as num?)?.toDouble() ??
          4.8,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 100,
      userLevel: json['user_level']?.toString() ?? json['level']?.toString() ?? 'Gold',
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
      isUnlocked: json['is_unlocked'] == true,
      unlockPriceUsd: (json['unlock_price_usd'] as num?)?.toDouble() ?? 1.0,
      unlockValidUntil: json['unlock_valid_until']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'entity_key': entityKey,
      'country': country,
      'approx_location': approxLocation,
      'user_name': userName,
      'is_verified': isVerified,
      'user_avg_rating': userAvgRating,
      'total_reviews': totalReviews,
      'user_level': userLevel,
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
      'is_unlocked': isUnlocked,
      'unlock_price_usd': unlockPriceUsd,
      'unlock_valid_until': unlockValidUntil,
    };
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
