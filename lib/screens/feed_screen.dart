import 'package:flutter/material.dart';
import '../models/entity_record.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'create_post_screen.dart';
import 'create_request_screen.dart';
import 'single_winner_screen.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const FeedScreen({super.key, required this.onLogout});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedCountry = 'BD';
  String _selectedSectionKey = 'all'; // 'all', 'rent', 'market', 'delivery', 'labor'
  bool _isLoading = false;
  List<EntityRecord> _records = [];

  // Search & Filter State
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationFilterController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Regional Configs
  final Map<String, Map<String, dynamic>> _countryConfigs = {
    'BD': {'flag': '🇧🇩', 'currency': '৳', 'rate': 120, 'gateway': 'bKash / Nagad / Rocket'},
    'IN': {'flag': '🇮🇳', 'currency': '₹', 'rate': 85, 'gateway': 'Razorpay / UPI'},
    'US': {'flag': '🇺🇸', 'currency': '\$', 'rate': 1, 'gateway': 'Stripe / Card'},
  };

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationFilterController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final minPrice = double.tryParse(_minPriceController.text.trim());
    final maxPrice = double.tryParse(_maxPriceController.text.trim());

    final items = await ApiService().fetchRecords(
      sectionKey: _selectedSectionKey,
      country: _selectedCountry,
      searchQuery: _searchController.text.trim(),
      locationQuery: _locationFilterController.text.trim(),
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    if (mounted) {
      setState(() {
        _records = items;
        _isLoading = false;
      });
    }
  }

  /// NID & Face Verification Modal (With Camera simulation)
  void _showNidVerificationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 28),
                  SizedBox(width: 10),
                  Text('NID ও ফেস ভেরিফিকেশন (বাধ্যতামূলক)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'এনআইডি দিয়ে ভেরিফিকেশন না হওয়া পর্যন্ত কোনো পোস্ট গ্রহণ বা রিকোয়েস্ট পাঠানো যাবে না। ক্যামেরার মাধ্যমে পরিষ্কার ছবি আপলোড করুন।',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildUploadBox('১. NID ফ্রন্ট সাইড ছবি (ক্যামেরা)', Icons.credit_card),
              const SizedBox(height: 10),
              _buildUploadBox('২. NID ব্যাক সাইড ছবি (ক্যামেরা)', Icons.credit_card_outlined),
              const SizedBox(height: 10),
              _buildUploadBox('৩. লাইভ সেলফি ছবি (Face Verification)', Icons.camera_front),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  AuthService().setVerified(true);
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 NID তথ্য যাচাই সম্পন্ন হয়েছে! আপনি এখন যেকোনো পোস্ট গ্রহণ বা রিকোয়েস্ট পাঠাতে পারবেন। ✅'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                child: const Text('যাচাইয়ের জন্য জমা দিন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadBox(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          const Text('ক্যামেরা চালু করুন 📸', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Contact Scan Simulation Dialog
  void _showContactScanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.contacts_rounded, color: Color(0xFF2563EB), size: 44),
        title: const Text('কন্টাক্ট নাম্বার পারমিশন ও বৃদ্ধি কৌশল', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'ব্যবহারকারী বৃদ্ধি করার কৌশল:\nঅ্যাপস আপনার ফোনবুক কন্টাক্ট স্ক্যান করে নিকটস্থ পরিচিত মানুষদের SERVICE প্ল্যাটফর্মে যুক্ত হওয়ার আমন্ত্রণ পাঠাবে।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),
            SizedBox(height: 12),
            Text('• পরিচিতদের সহজে খুঁজে পাওয়া যাবে\n• ভেরিফায়েড রেফারাল বোনাস সরাসরি ওয়ালেটে যুক্ত হবে', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('পরে করব')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📱 কন্টাক্ট পারমিশন সফল! ৮৪ জন পরিচিত সার্ভিস নেটওয়ার্কে চিহ্নিত হয়েছে।')),
              );
            },
            child: const Text('পারমিশন দিন ও স্ক্যান করুন'),
          ),
        ],
      ),
    );
  }

  /// Notification Alert Dialog
  void _showNotificationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final alerts = ApiService().nearbyAlerts;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.notifications_active, color: Color(0xFFEA580C), size: 24),
                      SizedBox(width: 8),
                      Text('কাছাকাছি আবেদন ও অ্যালার্টসমূহ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDBA74))),
                    child: Text('${alerts.length}টি সক্রিয়', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...alerts.map((al) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.bolt, color: Color(0xFFEA580C), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(al['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('${al['seeker']} • ${al['distance']} • ${al['time']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _verifyAndProceed(
                            actionName: 'রিকোয়েস্ট গ্রহণ',
                            onAuthorized: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('✅ ${al['seeker']} এর আবেদনটি আপনি সফলভাবে গ্রহণ করেছেন!')),
                              );
                            },
                          );
                        },
                        child: const Text('গ্রহণ করুন', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Verification Guard: Block posts and requests if user is NOT NID-verified!
  void _verifyAndProceed({required String actionName, required VoidCallback onAuthorized}) {
    final user = AuthService().currentUser;
    if (user == null || !user.isVerified) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 48),
          title: const Text('NID ভেরিফিকেশন আবশ্যক', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            'এনআইডি দিয়ে ভেরিফিকেশন না হওয়া পর্যন্ত আপনি কোনো $actionName করতে পারবেন না। নিরাপত্তা ও বিশ্বস্ততার স্বার্থে এটি বাধ্যতামূলক।',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('পরে করব')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _showNidVerificationDialog();
              },
              child: const Text('এখনই NID ভেরিফাই করুন'),
            ),
          ],
        ),
      );
      return;
    }
    onAuthorized();
  }

  /// Filter Bottom Sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setFilterState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.tune, color: Color(0xFF1E3A8A), size: 24),
                          SizedBox(width: 8),
                          Text('ফিল্টার সেটিংস (Filter)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          _locationFilterController.clear();
                          _minPriceController.clear();
                          _maxPriceController.clear();
                          Navigator.pop(ctx);
                          _loadRecords();
                        },
                        child: const Text('রিসেট', style: TextStyle(color: Color(0xFFDC2626))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Location Filter
                  TextField(
                    controller: _locationFilterController,
                    decoration: InputDecoration(
                      labelText: 'সুনির্দিষ্ট এলাকা / লোকেশন ফিল্টার',
                      hintText: 'যেমন: উত্তরা, মিরপুর, ধানমন্ডি',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('মূল্য বা পারিশ্রমিক (সর্বনিম্ন থেকে সর্বোচ্চ):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'সর্বনিম্ন মূল্য (৳)',
                            hintText: '০',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'সর্বোচ্চ মূল্য (৳)',
                            hintText: '১০০০০',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _loadRecords();
                    },
                    child: const Text('ফিল্টার প্রয়োগ করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Page Help Modal
  void _showPageHelpModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.help_outline, color: Color(0xFF1E3A8A), size: 24),
            SizedBox(width: 8),
            Text('হোম পেজ ব্যবহারের নিয়মাবলী', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '১. বাম পাশের SERVICE লোগোতে চাপ দিলে ড্রয়ার মেনু ওপেন হবে।\n\n'
                '২. পোস্ট করুন (নীল কার্ড): সার্ভিস প্রদানকারী হিসেবে ভাড়ার সেকশন, মার্কেটপ্লেস, ডেলিভারি বা মজদুরি সেকশনে পোস্ট দিন।\n\n'
                '৩. আবেদন করুন (সবুজ কার্ড): গ্রাহক হিসেবে কাছাকাছি ভেরিফায়েড প্রোভাইডারের কাছে লাইভ রিকোয়েস্ট পাঠান।\n\n'
                '৪. সার্চ ও ফিল্টার: সার্চ আইকন দিয়ে নাম, ক্যাটাগরি এবং ফিল্টারে লোকেশন ও সর্বনিম্ন-সর্বোচ্চ মূল্যের রেঞ্জ দিয়ে সার্চ করুন।\n\n'
                '৫. NID ভেরিফিকেশন: NID ছাড়া কোনো পোস্ট একসেপ্ট বা রিকোয়েস্ট পাঠানো যাবে না।\n\n'
                '৬. রিয়্যাক্ট ও আনলক সংখ্যা: প্রতিটি পোস্টে রিয়্যাক্ট দেওয়া যায় এবং কতজন এই পোস্ট আনলক করেছেন তা উন্মুক্ত থাকে।\n\n'
                '৭. পেমেন্ট গেটওয়ে: বিকাশ, নগদ, রকেটের মাধ্যমে আনলক ফি পরিশোধ করলেই ৭ দিনের জন্য গোপন তথ্য উন্মুক্ত হবে।',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে, বুঝেছি', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Direct Payment Gateway Modal (bKash, Nagad, Rocket)
  void _showDirectPaymentModal(EntityRecord record) {
    final cfg = _countryConfigs[_selectedCountry]!;
    final basePrice = (record.unlockPriceUsd * (cfg['rate'] as num)).round();
    String selectedMethod = 'bkash';
    final senderNumberCtrl = TextEditingController(text: '017XXXXXXXX');
    final trxIdCtrl = TextEditingController(text: 'TRX${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPayState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.emerald.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.account_balance_wallet, color: Color(0xFF059669), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('নিরাপদ পেমেন্ট গেটওয়ে (সরাসরি আনলক)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('টাকা পাঠালে সাথে সাথে আনলক হবে (মেয়াদ ${record.authorValidityDays} দিন)', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Method Selection
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setPayState(() => selectedMethod = 'bkash'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedMethod == 'bkash' ? const Color(0xFFFDF2F8) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedMethod == 'bkash' ? const Color(0xFFDB2777) : const Color(0xFFCBD5E1), width: 1.5),
                            ),
                            child: const Center(
                              child: Text('বিকাশ (bKash)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFBE185D))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setPayState(() => selectedMethod = 'nagad'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedMethod == 'nagad' ? const Color(0xFFFFF7ED) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedMethod == 'nagad' ? const Color(0xFFEA580C) : const Color(0xFFCBD5E1), width: 1.5),
                            ),
                            child: const Center(
                              child: Text('নগদ (Nagad)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFC2410C))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setPayState(() => selectedMethod = 'rocket'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedMethod == 'rocket' ? const Color(0xFFF5F3FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selectedMethod == 'rocket' ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1), width: 1.5),
                            ),
                            child: const Center(
                              child: Text('রকেট (Rocket)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6D28D9))),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('মার্চেন্ট নম্বর: 01800-000000 (Send Money)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue.shade900)),
                        const SizedBox(height: 4),
                        Text('আনলক ফি: ${cfg['currency']} $basePrice (Author নির্ধারিত রেট)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF059669))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: senderNumberCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'আপনার মোবাইল নম্বর',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: trxIdCtrl,
                    decoration: InputDecoration(
                      labelText: 'ট্রানজেকশন আইডি (TrxID)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () async {
                            setPayState(() => isProcessing = true);
                            await ApiService().unlockWithDirectPayment(
                              recordId: record.id,
                              method: selectedMethod,
                              senderNumber: senderNumberCtrl.text.trim(),
                              transactionId: trxIdCtrl.text.trim(),
                            );
                            if (mounted) setState(() {});
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 পেমেন্ট সফলভাবে যাচাই হয়েছে! ${record.authorValidityDays} দিনের জন্য সম্পূর্ণ যোগাযোগ আনলক করা হয়েছে।'),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          },
                    child: isProcessing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('টাকা পরিশোধ ও সাথে সাথে আনলক করুন (${cfg['currency']} $basePrice)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Section Picker Dialog when pressing 'পোস্ট করুন'
  void _showSectionSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(Icons.category, color: Color(0xFF1E3A8A), size: 24),
                  SizedBox(width: 10),
                  Text('কোথায় পোস্ট করতে চান? সেকশন নির্বাচন করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Author কর্তৃক নিয়ন্ত্রিত সকল সেকশন:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 14),

              ...ApiService.sections.where((s) => s['key'] != 'all').map((sec) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ListTile(
                    title: Text(sec['label_bn'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(sec['description'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1E3A8A)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePostScreen(
                            entityKey: sec['entity_key'] as String,
                            initialSectionKey: sec['key'] as String,
                            onPostCreated: _loadRecords,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Delete Confirmation Dialog
  void _confirmDeleteRecord(EntityRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('পোস্টটি ডিলিট করতে চান?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('"${record.title}" পোস্টটি স্থায়ীভাবে মুছে ফেলা হবে।', style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              ApiService().deleteRecord(record.id);
              Navigator.pop(ctx);
              _loadRecords();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('পোস্টটি সফলভাবে মুছে ফেলা হয়েছে!')),
              );
            },
            child: const Text('ডিলিট করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);
    final user = AuthService().currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),

      // App Drawer (Left-side navigation triggered by SERVICE Logo)
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: const Text('SERVICE', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      if (user?.isVerified == true)
                        const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(user?.fullName ?? 'ব্যবহারকারী', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(user?.phone ?? 'মোবাইল নম্বর', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('ব্যালেন্স: ৳${user?.walletBalance ?? 100} • Level: ${user?.level ?? "New"}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user, color: Color(0xFF059669)),
              title: const Text('NID ভেরিফিকেশন', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user?.isVerified == true ? 'ভেরিফায়েড প্রোফাইল ✅' : 'অননুমোদিত (ভেরিফাই করুন)', style: const TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                _showNidVerificationDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.contacts, color: Color(0xFF2563EB)),
              title: const Text('কন্টাক্ট স্ক্যান ও সম্প্রসারণ', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('কন্টাক্ট পারমিশন নিয়ে ইউজার বৃদ্ধি কৌশল', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                _showContactScanDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Color(0xFFEA580C)),
              title: const Text('কাছাকাছি অ্যালার্টসমূহ', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFFFEDD5), shape: BoxShape.circle),
                child: Text('${ApiService().nearbyAlerts.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFEA580C))),
              ),
              onTap: () {
                Navigator.pop(context);
                _showNotificationDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt, color: Color(0xFFD97706)),
              title: const Text('একক বিজয়ী সিমুলেটর', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SingleWinnerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Color(0xFF64748B)),
              title: const Text('অ্যাপ ব্যবহারের নিয়মাবলী', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showPageHelpModal();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              title: const Text('লগআউট করুন', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          tooltip: 'ড্রয়ার মেনু খুলুন',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Row(
            children: [
              const Text('SERVICE', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '👤 ${user?.fullName ?? 'ইউজার'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Search Icon
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search, size: 22, color: const Color(0xFF334155)),
            tooltip: 'সার্চ বার',
            onPressed: () {
              setState(() => _showSearchBar = !_showSearchBar);
            },
          ),

          // Filter Icon
          IconButton(
            icon: const Icon(Icons.tune, size: 20, color: Color(0xFF334155)),
            tooltip: 'ফিল্টার করুন',
            onPressed: _showFilterBottomSheet,
          ),

          // Notification Alert Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 22, color: Color(0xFF334155)),
                tooltip: 'অ্যালার্ট ও নোটিফিকেশন',
                onPressed: _showNotificationDialog,
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEA580C), shape: BoxShape.circle),
                  child: Text(
                    '${ApiService().nearbyAlerts.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // Help Icon
          IconButton(
            icon: const Icon(Icons.help_outline, size: 20, color: Color(0xFF64748B)),
            tooltip: 'পেজ ব্যবহারের নিয়মাবলী',
            onPressed: _showPageHelpModal,
          ),

          // Country Switcher
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountry,
              items: _countryConfigs.keys.map((code) {
                return DropdownMenuItem(
                  value: code,
                  child: Text('${_countryConfigs[code]!['flag']} $code', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                );
              }).toList>,
              onChanged: (code) {
                if (code != null) {
                  setState(() => _selectedCountry = code);
                  _loadRecords();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // Search Bar (Expanded when search icon pressed)
            if (_showSearchBar) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'ক্যাটাগরি, শিরোনাম বা বিবরণ সার্চ করুন...',
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        onChanged: (_) => _loadRecords(),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _loadRecords();
                        },
                      ),
                  ],
                ),
              ),
            ],

            // Quick Status Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: Icon(
                      user?.isVerified == true ? Icons.verified : Icons.shield_outlined,
                      size: 16,
                      color: user?.isVerified == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                    label: Text(
                      user?.isVerified == true ? 'NID ভেরিফায়েড ✅' : 'NID ভেরিফিকেশন প্রয়োজন ⚠️',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: user?.isVerified == true ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                      ),
                    ),
                    backgroundColor: user?.isVerified == true ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    side: BorderSide(color: user?.isVerified == true ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                    onPressed: _showNidVerificationDialog,
                  ),
                  const SizedBox(width: 8),

                  ActionChip(
                    avatar: const Icon(Icons.contacts, size: 16, color: Color(0xFF2563EB)),
                    label: const Text('কন্টাক্ট স্ক্যান পারমিশন', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    onPressed: _showContactScanDialog,
                  ),
                  const SizedBox(width: 8),

                  ActionChip(
                    avatar: const Icon(Icons.help_outline, size: 16, color: Color(0xFF64748B)),
                    label: const Text('ব্যবহারের নিয়ম', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    onPressed: _showPageHelpModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // TWO BIG BUTTONS (Post Korun & Abedon Korun)
            Row(
              children: [
                // CARD 1: পোস্ট করুন
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _verifyAndProceed(
                        actionName: 'পোস্ট তৈরি',
                        onAuthorized: _showSectionSelectionModal,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Text('📝', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(height: 8),
                          const Text('পোস্ট করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          const Text('সার্ভিস প্রদানকারী (ভাড়া/মার্কেট/মজদুরি)', style: TextStyle(color: Colors.white70, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // CARD 2: আবেদন করুন
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _verifyAndProceed(
                        actionName: 'আবেদন তৈরি',
                        onAuthorized: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateRequestScreen(
                                onRequestCreated: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('আপনার রিকোয়েস্ট সফলভাবে প্রচারিত হয়েছে!')),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Text('🙋', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(height: 8),
                          const Text('আবেদন করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          const Text('কাছাকাছি প্রোভাইডারকে অ্যালার্ট পাঠান', style: TextStyle(color: Colors.white70, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dynamic Sections Filter Tabs (Author Controlled)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ApiService.sections.map((sec) {
                  final isSelected = _selectedSectionKey == sec['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedSectionKey = sec['key'] as String);
                        _loadRecords();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? primaryColor : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          sec['label_bn'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_records.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
                    SizedBox(height: 10),
                    Text('কোনো পোস্ট পাওয়া যায়নি। ফিল্টার পরিবর্তন করে আবার চেষ্টা করুন।', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              )
            else
              ..._records.map((record) => _buildPostCard(record)),
          ],
        ),
      ),
    );
  }

  /// PREMIUM CARD WITH EDIT, DELETE, REACTIONS, ACCEPTS, AND PRIVATE VERIFIED PHOTO
  Widget _buildPostCard(EntityRecord record) {
    final cfg = _countryConfigs[_selectedCountry]!;
    final unlockFeeLocal = (record.unlockPriceUsd * (cfg['rate'] as num)).round();
    final user = AuthService().currentUser;
    final isMyPost = user?.id == record.userId || record.userName == user?.fullName;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category + Approx Location + Edit/Delete Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.sectionKey == 'rent'
                        ? 'ভাড়ার সেকশন'
                        : record.sectionKey == 'market'
                            ? 'মার্কেটপ্লেস'
                            : record.sectionKey == 'delivery'
                                ? 'ডেলিভারি'
                                : 'মজদুরি ও পেশাদার সেবা',
                    style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      record.approxLocation,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF64748B)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreatePostScreen(
                                entityKey: record.entityKey,
                                initialSectionKey: record.sectionKey,
                                editRecord: record,
                                onPostCreated: _loadRecords,
                              ),
                            ),
                          );
                        } else if (val == 'delete') {
                          _confirmDeleteRecord(record);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 8),
                              Text('পোস্ট এডিট করুন', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Color(0xFFDC2626)),
                              SizedBox(width: 8),
                              Text('পোস্ট ডিলিট করুন', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              record.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.3),
            ),
            const SizedBox(height: 6),

            // Second Row: User Info + Verified Badge + Level + Rating + Verified Photo Preview
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  record.userName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                if (record.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified, size: 12, color: Color(0xFF059669)),
                        SizedBox(width: 3),
                        Text('Verified', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                      ],
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      '${record.userAvgRating} (${record.totalReviews})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Text(
                    '${record.userLevel} Level',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF4338CA)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle Grid: Dynamic 15 Columns rendering
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildGridField('ক্যাটাগরি / ধরন', record.customCol1 ?? 'সার্ভিস')),
                      Expanded(child: _buildGridField('জামানত / মূল্য', '${cfg['currency']} ${record.customCol2 ?? '5000'}')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGridField('রেট / চার্জ', '${cfg['currency']} ${record.customCol3 ?? '450'}')),
                      Expanded(child: _buildGridField('মডেল / অভিজ্ঞতা', record.customCol4 ?? '2019')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGridField('আসন / সক্ষমতা', '${record.customCol5 ?? '4'} জন')),
                      Expanded(child: _buildGridField('Author সময়সীমা', '${record.authorValidityDays} দিন কার্যকর')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Social & Public Metrics: Reactions + Accepted Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reaction Button (পাবলিক রিয়্যাক্ট)
                InkWell(
                  onTap: () {
                    setState(() {
                      ApiService().toggleReaction(record.id);
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: record.hasUserReacted ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: record.hasUserReacted ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          record.hasUserReacted ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          size: 14,
                          color: record.hasUserReacted ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${record.reactionsCount} লাইক',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: record.hasUserReacted ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Accepted Count (কতজন এই পোস্ট গ্রহণ / আনলক করেছেন - পাবলিক)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text(
                        '${record.acceptedCount} জন গ্রহণ করেছেন',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Locked or Unlocked Box
            if (record.isUnlocked)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.lock_open_rounded, size: 16, color: Color(0xFF059669)),
                            SizedBox(width: 6),
                            Text('আনলক করা তথ্য (৭ দিনের মেয়াদ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF065F46))),
                          ],
                        ),
                        if (record.unlockValidUntil != null)
                          Text('Valid: ${record.unlockValidUntil}', style: const TextStyle(fontSize: 10, color: Color(0xFF047857))),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Private Photo revealed upon unlock
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: (record.userAvatarUrl != null)
                              ? NetworkImage(record.userAvatarUrl!)
                              : null,
                          child: record.userAvatarUrl == null ? const Icon(Icons.person, color: Color(0xFF1E3A8A)) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('সরাসরি মোবাইল: ${record.customCol6 ?? "+8801711223344"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                              Text('নিশ্চিত ঠিকানা: ${record.customCol7 ?? "উত্তরা সেক্টর ৭, রোড ৪, বাসা ১২, ঢাকা"}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('মোবাইল, ঠিকানা ও ভেরিফাইড ছবি: 🔒 Unlock Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF92400E))),
                          SizedBox(height: 2),
                          Text('বিকাশ/নগদ/রকেট দিয়ে আনলক ফি পাঠালে সাথে সাথে আনলক হয়ে যাবে।', style: TextStyle(fontSize: 10, color: Color(0xFF78350F))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Action Button
            if (record.isUnlocked)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('সরাসরি লাইভ চ্যাট করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('লাইভ চ্যাট উইন্ডো সক্রিয়!')),
                  );
                },
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.lock_open, size: 16),
                label: Text('বিকাশ / নগদ / রকেটে আনলক করুন (${cfg['currency']} $unlockFeeLocal)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  _verifyAndProceed(
                    actionName: 'পোস্ট আনলক',
                    onAuthorized: () => _showDirectPaymentModal(record),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }
}
