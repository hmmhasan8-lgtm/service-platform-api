import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entity_record.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://localhost:8000';

  // Available Business Sections (Author Dynamic Control)
  static final List<Map<String, dynamic>> sections = [
    {
      'key': 'all',
      'label_bn': 'সকল সেকশন',
      'label_en': 'All',
      'icon': 'apps',
    },
    {
      'key': 'rent',
      'label_bn': '🚗 ভাড়ার সেকশন',
      'label_en': 'Rentals',
      'description': 'যানবাহন, বাস, ট্রাক, কার ও লজিস্টিকস ভাড়া',
      'entity_key': 'vehicles',
    },
    {
      'key': 'market',
      'label_bn': '🛒 মার্কেটপ্লেস',
      'label_en': 'Products',
      'description': 'পণ্য বেচাকেনা, গ্যাজেটস ও বাণিজ্যিক সামগ্রী',
      'entity_key': 'products',
    },
    {
      'key': 'delivery',
      'label_bn': '📦 ডেলিভারি সার্ভিস',
      'label_en': 'Delivery',
      'description': 'কুরিয়ার, হোম ডেলিভারি ও পার্সেল সার্ভিস',
      'entity_key': 'delivery',
    },
    {
      'key': 'labor',
      'label_bn': '🛠️ মজদুরি ও পেশাদার সেবা',
      'label_en': 'Labor & Services',
      'description': 'এসি মেরামত, ইলেকট্রিশিয়ান, দিনমজুর ও টেকনিশিয়ান',
      'entity_key': 'services',
    },
  ];

  // In-memory feed items synchronized with Web Preview and all sections
  final List<EntityRecord> _inMemoryRecords = [
    EntityRecord(
      id: 'post_1',
      title: 'Toyota Axio 2018 - Personal Used Condition',
      userName: 'তানভীর আহমেদ',
      userId: 'usr_8812',
      entityKey: 'vehicles',
      sectionKey: 'rent',
      country: 'BD',
      approxLocation: 'উত্তরা সেক্টর ৭, ঢাকা',
      isVerified: true,
      userAvgRating: 4.8,
      totalReviews: 120,
      userLevel: 'Gold',
      userAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      customCol1: 'CNG', // Fuel Type
      customCol2: '5000', // Security Deposit
      customCol3: '450', // Hourly Rate
      customCol4: '2018', // Model Year
      customCol5: '4', // Seating Capacity
      customCol6: '+8801711223344', // Owner Mobile (Private)
      customCol7: 'House 12, Road 4, Sector 7, Uttara, Dhaka', // Garage Location (Private)
      reactionsCount: 28,
      acceptedCount: 14,
      isUnlocked: false,
      unlockPriceUsd: 1.0,
      authorValidityDays: 7,
    ),
    EntityRecord(
      id: 'post_2',
      title: 'Noah Microbus - 8 Seats AC Tour Pack',
      userName: 'করিম এন্টারপ্রাইজ',
      userId: 'usr_karim',
      entityKey: 'vehicles',
      sectionKey: 'rent',
      country: 'BD',
      approxLocation: 'মিরপুর ১০, ঢাকা',
      isVerified: true,
      userAvgRating: 4.9,
      totalReviews: 85,
      userLevel: 'Platinum',
      userAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      customCol1: 'Octane',
      customCol2: '8000',
      customCol3: '650',
      customCol4: '2019',
      customCol5: '8',
      customCol6: '+8801822998877',
      customCol7: 'Plot 44, Block C, Mirpur 10, Dhaka',
      reactionsCount: 45,
      acceptedCount: 22,
      isUnlocked: false,
      unlockPriceUsd: 1.0,
      authorValidityDays: 7,
    ),
    EntityRecord(
      id: 'post_3',
      title: 'জরুরী স্প্লিট এসি গ্যাস চার্জ ও মেরামত টেকনিশিয়ান',
      userName: 'রহিম এসি সলিউশন',
      userId: 'usr_rahim',
      entityKey: 'services',
      sectionKey: 'labor',
      country: 'BD',
      approxLocation: 'মিরপুর ১১, ঢাকা',
      isVerified: true,
      userAvgRating: 4.9,
      totalReviews: 140,
      userLevel: 'Platinum',
      userAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      customCol1: 'AC Repair',
      customCol2: '500', // Visiting Charge
      customCol3: '30', // Warranty Days
      customCol4: 'Specialist AC',
      customCol5: 'On-demand',
      customCol6: '+8801733445566',
      customCol7: 'Shop 14, Block D, Mirpur 11, Dhaka',
      reactionsCount: 62,
      acceptedCount: 39,
      isUnlocked: false,
      unlockPriceUsd: 0.5,
      authorValidityDays: 7,
    ),
    EntityRecord(
      id: 'post_4',
      title: 'নতুন জেনুইন স্যামসাং ৫১২ জিবি এসএসডি (Boxed)',
      userName: 'আইটি মার্ট',
      userId: 'usr_itmart',
      entityKey: 'products',
      sectionKey: 'market',
      country: 'BD',
      approxLocation: 'মাল্টিপ্ল্যান সেন্টার, ঢাকা',
      isVerified: true,
      userAvgRating: 4.7,
      totalReviews: 32,
      userLevel: 'Gold',
      customCol1: 'Electronics',
      customCol2: '4500', // Price
      customCol3: '3 Years Warranty',
      customCol4: 'New',
      customCol5: 'Cash on Delivery',
      customCol6: '+8801999887766',
      customCol7: 'Level 4, Multiplan Center, Elephant Road, Dhaka',
      reactionsCount: 19,
      acceptedCount: 9,
      isUnlocked: false,
      unlockPriceUsd: 0.5,
      authorValidityDays: 7,
    ),
  ];

  // Nearby Service Requests (For Notification Bell Alerts)
  final List<Map<String, dynamic>> nearbyAlerts = [
    {
      'id': 'alert_1',
      'title': 'মিরপুর ১০ এ ১.৫ টন স্প্লিট এসি মেরামত প্রয়োজন',
      'seeker': 'আরিফুল ইসলাম',
      'distance': '১.২ কিমি দূরে',
      'time': '৩ মিনিট আগে',
      'fee': '৳ ৫০',
      'category': 'এসি সার্ভিসিং',
      'location': 'মিরপুর ১০, ঢাকা',
    },
    {
      'id': 'alert_2',
      'title': 'উত্তরা থেকে এয়ারপোর্ট প্রিমিও কার রেন্টাল প্রয়োজন',
      'seeker': 'নাজমুল হাসান',
      'distance': '২.৫ কিমি দূরে',
      'time': '৮ মিনিট আগে',
      'fee': '৳ ১২০',
      'category': 'কার রেন্টাল',
      'location': 'উত্তরা সেক্টর ৩, ঢাকা',
    },
  ];

  /// Fetch and filter records
  Future<List<EntityRecord>> fetchRecords({
    String sectionKey = 'all',
    String country = 'BD',
    String searchQuery = '',
    double? minPrice,
    double? maxPrice,
    String locationQuery = '',
  }) async {
    return _inMemoryRecords.where((r) {
      if (country != 'ALL' && r.country != country) return false;
      if (sectionKey != 'all' && r.sectionKey != sectionKey) return false;

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchTitle = r.title.toLowerCase().contains(query);
        final matchLoc = r.approxLocation.toLowerCase().contains(query);
        final matchUser = r.userName.toLowerCase().contains(query);
        final matchCol = r.recordColumns.values.any((v) => v?.toString().toLowerCase().contains(query) == true);
        if (!matchTitle && !matchLoc && !matchUser && !matchCol) return false;
      }

      if (locationQuery.isNotEmpty) {
        if (!r.approxLocation.toLowerCase().contains(locationQuery.toLowerCase())) {
          return false;
        }
      }

      // Check numeric price in custom_col_2 or custom_col_3
      if (minPrice != null || maxPrice != null) {
        final rawPrice = double.tryParse(r.customCol2?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ??
            double.tryParse(r.customCol3?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '');
        if (rawPrice != null) {
          if (minPrice != null && rawPrice < minPrice) return false;
          if (maxPrice != null && rawPrice > maxPrice) return false;
        }
      }

      return true;
    }).toList();
  }

  /// Add new post
  void addRecord(EntityRecord record) {
    _inMemoryRecords.insert(0, record);
  }

  /// Edit existing post
  bool editRecord(String recordId, {
    required String newTitle,
    required String newLocation,
    Map<String, String>? updatedColumns,
  }) {
    final index = _inMemoryRecords.indexWhere((r) => r.id == recordId);
    if (index == -1) return false;

    final record = _inMemoryRecords[index];
    record.title = newTitle;
    record.approxLocation = newLocation;

    if (updatedColumns != null) {
      for (final entry in updatedColumns.entries) {
        record.recordColumns[entry.key] = entry.value;
        switch (entry.key) {
          case 'custom_col_1': record.customCol1 = entry.value; break;
          case 'custom_col_2': record.customCol2 = entry.value; break;
          case 'custom_col_3': record.customCol3 = entry.value; break;
          case 'custom_col_4': record.customCol4 = entry.value; break;
          case 'custom_col_5': record.customCol5 = entry.value; break;
          case 'custom_col_6': record.customCol6 = entry.value; break;
          case 'custom_col_7': record.customCol7 = entry.value; break;
        }
      }
    }
    return true;
  }

  /// Delete post
  bool deleteRecord(String recordId) {
    final initialLen = _inMemoryRecords.length;
    _inMemoryRecords.removeWhere((r) => r.id == recordId);
    return _inMemoryRecords.length < initialLen;
  }

  /// Toggle reaction on post
  int toggleReaction(String recordId) {
    final record = _inMemoryRecords.firstWhere((r) => r.id == recordId, orElse: () => _inMemoryRecords.first);
    record.hasUserReacted = !record.hasUserReacted;
    if (record.hasUserReacted) {
      record.reactionsCount++;
    } else {
      record.reactionsCount = (record.reactionsCount - 1).clamp(0, 9999);
    }
    return record.reactionsCount;
  }

  /// Quick unlock record (mock/direct)
  Future<bool> unlockRecord(String recordId) async {
    final record = _inMemoryRecords.firstWhere((r) => r.id == recordId, orElse: () => _inMemoryRecords.first);
    record.isUnlocked = true;
    record.acceptedCount++;
    final expiry = DateTime.now().add(Duration(days: record.authorValidityDays));
    record.unlockValidUntil = '${expiry.day}/${expiry.month}/${expiry.year}';
    return true;
  }

  /// Process direct payment unlock (bKash / Nagad / Rocket)
  Future<bool> unlockWithDirectPayment({
    required String recordId,
    required String method, // 'bkash', 'nagad', 'rocket', 'upay'
    required String senderNumber,
    required String transactionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final record = _inMemoryRecords.firstWhere((r) => r.id == recordId, orElse: () => _inMemoryRecords.first);
    record.isUnlocked = true;
    record.acceptedCount++;
    final expiry = DateTime.now().add(Duration(days: record.authorValidityDays));
    record.unlockValidUntil = '${expiry.day}/${expiry.month}/${expiry.year}';
    return true;
  }
}
