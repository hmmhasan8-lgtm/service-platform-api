import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entity_record.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://localhost:8000';

  // Active 15-Columns Configuration for entities
  static final Map<String, List<GenericColumnConfig>> entityColumnConfigs = {
    'vehicles': [
      GenericColumnConfig(
        colKey: 'custom_col_1',
        labelEn: 'Fuel Type',
        labelBn: 'জ্বালানির ধরন',
        dataType: 'select',
        isPrivate: false,
        isActive: true,
        options: ['CNG', 'Petrol', 'Octane', 'Electric'],
      ),
      GenericColumnConfig(
        colKey: 'custom_col_2',
        labelEn: 'Security Deposit',
        labelBn: 'জামানতের পরিমাণ',
        dataType: 'currency',
        isPrivate: false,
        isActive: true,
      ),
      GenericColumnConfig(
        colKey: 'custom_col_3',
        labelEn: 'Hourly Rate',
        labelBn: 'ঘণ্টাপ্রতি ভাড়া',
        dataType: 'currency',
        isPrivate: false,
        isActive: true,
      ),
      GenericColumnConfig(
        colKey: 'custom_col_4',
        labelEn: 'Vehicle Model Year',
        labelBn: 'মডেল সাল',
        dataType: 'number',
        isPrivate: false,
        isActive: true,
      ),
      GenericColumnConfig(
        colKey: 'custom_col_5',
        labelEn: 'Seating Capacity',
        labelBn: 'আসন সংখ্যা',
        dataType: 'number',
        isPrivate: false,
        isActive: true,
      ),
      GenericColumnConfig(
        colKey: 'custom_col_6',
        labelEn: 'Owner Direct Mobile',
        labelBn: 'মালিকের সরাসরি মোবাইল',
        dataType: 'phone',
        isPrivate: true,
        isActive: true,
      ),
      GenericColumnConfig(
        colKey: 'custom_col_7',
        labelEn: 'Exact Garage Address',
        labelBn: 'গ্যারেজের নির্ভুল ঠিকানা',
        dataType: 'geo_point',
        isPrivate: true,
        isActive: true,
      ),
    ],
    'services': [
      GenericColumnConfig(
        colKey: 'custom_col_1',
        labelEn: 'Service Category',
        labelBn: 'সেবার ক্যাটাগরি',
        dataType: 'select',
        isPrivate: false,
        isActive: true,
        options: ['AC Repair', 'Plumbing', 'Electrical', 'Cleaning'],
      ),
      GenericColumnConfig(
        colKey: 'custom_col_2',
        labelEn: 'Visiting Charge',
        labelBn: 'ভিজিটিং চার্জ',
        dataType: 'currency',
        isPrivate: false,
        isActive: true,
      ),
      GenericColumnConfig(
        colKey: 'custom_col_3',
        labelEn: 'Warranty Days',
        labelBn: 'ওয়ারেন্টি (দিন)',
        dataType: 'number',
        isPrivate: false,
        isActive: true,
      ),
      GenericColumnConfig(
        colKey: 'custom_col_4',
        labelEn: 'Technician Direct Mobile',
        labelBn: 'টেকনিশিয়ান সরাসরি মোবাইল',
        dataType: 'phone',
        isPrivate: true,
        isActive: true,
      ),
      GenericColumnConfig(
        colKey: 'custom_col_5',
        labelEn: 'Holding Address',
        labelBn: 'হোল্ডিং ঠিকানা',
        dataType: 'geo_point',
        isPrivate: true,
        isActive: true,
      ),
    ],
  };

  // In-memory feed items synchronized with Web Preview
  final List<EntityRecord> _inMemoryRecords = [
    EntityRecord(
      id: 'post_1',
      title: 'Toyota Axio 2018 - Personal Used Condition',
      userName: 'তানভীর আহমেদ',
      entityKey: 'vehicles',
      country: 'BD',
      approxLocation: 'উত্তরা সেক্টর ৭, ঢাকা',
      isVerified: true,
      userAvgRating: 4.8,
      totalReviews: 120,
      userLevel: 'Gold',
      customCol1: 'CNG', // Fuel Type
      customCol2: '5000', // Security Deposit
      customCol3: '450', // Hourly Rate
      customCol4: '2018', // Model Year
      customCol5: '4', // Seating Capacity
      customCol6: '+8801711223344', // Owner Mobile (Private)
      customCol7: 'House 12, Road 4, Sector 7, Uttara, Dhaka', // Garage Location (Private)
      isUnlocked: false,
      unlockPriceUsd: 1.0,
    ),
    EntityRecord(
      id: 'post_2',
      title: 'Noah Microbus - 8 Seats AC Tour Pack',
      userName: 'করিম এন্টারপ্রাইজ',
      entityKey: 'vehicles',
      country: 'BD',
      approxLocation: 'মিরপুর ১০, ঢাকা',
      isVerified: true,
      userAvgRating: 4.9,
      totalReviews: 85,
      userLevel: 'Platinum',
      customCol1: 'Octane',
      customCol2: '8000',
      customCol3: '650',
      customCol4: '2019',
      customCol5: '8',
      customCol6: '+8801822998877',
      customCol7: 'Plot 44, Block C, Mirpur 10, Dhaka',
      isUnlocked: false,
      unlockPriceUsd: 1.0,
    ),
    EntityRecord(
      id: 'post_3',
      title: 'Premio 2017 Model - Chilled AC Wedding/VIP Pack',
      userName: 'আব্দুর রহমান',
      entityKey: 'vehicles',
      country: 'BD',
      approxLocation: 'ধানমন্ডি ২৭, ঢাকা',
      isVerified: true,
      userAvgRating: 4.7,
      totalReviews: 42,
      userLevel: 'Silver',
      customCol1: 'Octane',
      customCol2: '10000',
      customCol3: '700',
      customCol4: '2017',
      customCol5: '5',
      customCol6: '+8801911443322',
      customCol7: 'House 45, Road 27, Dhanmondi, Dhaka',
      isUnlocked: false,
      unlockPriceUsd: 1.0,
    ),
  ];

  /// Fetch records with country filter
  Future<List<EntityRecord>> fetchRecords({
    required String entityKey,
    required String country,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/entities/$entityKey/records?country=$country'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['records'] ?? data;
        return items.map((e) => EntityRecord.fromJson(e)).toList();
      }
    } catch (_) {}

    // Return in-memory synchronized list
    return _inMemoryRecords
        .where((r) => r.entityKey == entityKey && (r.country == country || country == 'ALL'))
        .toList();
  }

  /// Add new provider post
  void addRecord(EntityRecord record) {
    _inMemoryRecords.insert(0, record);
  }

  /// Validate discount coupon code
  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double feeAmount,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/coupons/validate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': cleanCode,
              'fee_amount': feeAmount,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Offline simulation
    if (cleanCode == 'EID50') {
      final discount = feeAmount * 0.5;
      return {
        'valid': true,
        'code': 'EID50',
        'discount_percent': 50.0,
        'discount_amount': discount,
        'final_fee': feeAmount - discount,
        'message': '🎉 কুপন সফল! আপনি ৫০% (৳${discount.toStringAsFixed(0)}) ছাড় পেয়েছেন।',
      };
    } else if (cleanCode == 'SERVICE20') {
      final discount = feeAmount * 0.2;
      return {
        'valid': true,
        'code': 'SERVICE20',
        'discount_percent': 20.0,
        'discount_amount': discount,
        'final_fee': feeAmount - discount,
        'message': '🎉 কুপন সফল! আপনি ২০% ছাড় পেয়েছেন।',
      };
    }

    return {
      'valid': false,
      'message': '❌ কুপন কোড সঠিক নয় অথবা মেয়াদোত্তীর্ণ।',
      'final_fee': feeAmount,
    };
  }

  /// Unlock Record
  Future<bool> unlockRecord(String recordId) async {
    final record = _inMemoryRecords.firstWhere(
      (r) => r.id == recordId,
      orElse: () => _inMemoryRecords.first,
    );
    record.isUnlocked = true;
    final expiry = DateTime.now().add(const Duration(days: 7));
    record.unlockValidUntil = '${expiry.day}/${expiry.month}/${expiry.year}';
    return true;
  }
}
