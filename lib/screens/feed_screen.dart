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
  String _selectedCountry = 'BD';
  String _selectedEntityKey = 'vehicles';
  bool _isLoading = false;
  List<EntityRecord> _records = [];

  // Regional Configs
  final Map<String, Map<String, dynamic>> _countryConfigs = {
    'BD': {'flag': '🇧🇩', 'currency': '৳', 'rate': 120, 'gateway': 'bKash / Nagad'},
    'IN': {'flag': '🇮🇳', 'currency': '₹', 'rate': 85, 'gateway': 'Razorpay / UPI'},
    'US': {'flag': '🇺🇸', 'currency': '\$', 'rate': 1, 'gateway': 'Stripe / Card'},
  };

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final items = await ApiService().fetchRecords(
      entityKey: _selectedEntityKey,
      country: _selectedCountry,
    );
    if (mounted) {
      setState(() {
        _records = items;
        _isLoading = false;
      });
    }
  }

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
                  Text('NID ও ফেস ভেরিফিকেশন (Module 1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'ভেরিফায়েড হলে আপনার নামের পাশে ভেরিফাইড ব্যাজ ✅ প্রদর্শিত হবে এবং আপনি কাছাকাছি গ্রাহকদের সরাসরি রিকোয়েস্ট পাবেন।',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildUploadBox('১. NID ফ্রন্ট সাইড ছবি', Icons.credit_card),
              const SizedBox(height: 10),
              _buildUploadBox('২. NID ব্যাক সাইড ছবি', Icons.credit_card_outlined),
              const SizedBox(height: 10),
              _buildUploadBox('৩. পরিষ্কার সেলফি ছবি (Face Match)', Icons.face),
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
                      content: Text('🎉 NID তথ্য জমা হয়েছে! আপনার প্রোফাইল ভেরিফায়েড ✅ হয়েছে।'),
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
          const Text('ছবি যুক্ত করুন 📁', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showReferralDialog() {
    final user = AuthService().currentUser;
    final code = user?.referralCode ?? 'ARIF123';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.card_giftcard, color: Color(0xFFE11D48), size: 48),
        title: const Text('রেফার করুন ও ১০০ টাকা আয় করুন!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'আপনার অনন্য রেফারাল কোড বন্ধুদের সাথে শেয়ার করুন। তারা একাউন্ট খুললেই দুজনেই ১০০ টাকা করে বোনাস পাবেন!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFFBE123C), letterSpacing: 2)),
                  const SizedBox(width: 10),
                  const Icon(Icons.copy, size: 18, color: Color(0xFFBE123C)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('রেফারাল লিঙ্ক কপি হয়েছে! WhatsApp এ শেয়ার করুন।')),
              );
            },
            child: const Text('লিঙ্ক কপি ও শেয়ার করুন', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showUnlockPaymentModal(EntityRecord record) {
    final cfg = _countryConfigs[_selectedCountry]!;
    final basePrice = (record.unlockPriceUsd * (cfg['rate'] as num)).round();
    final couponController = TextEditingController(text: 'EID50');
    double discount = 0;
    String? promoMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final payable = (basePrice * (1 - discount / 100)).round();

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
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.lock_open, color: Color(0xFF1E3A8A), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('গোপন তথ্য আনলক ফি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('৭ দিনের জন্য সরাসরি কল ও লাইভ চ্যাট', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text('পোস্ট:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            Expanded(
                              child: Text(
                                record.title,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text('পেমেন্ট গেটওয়ে:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            Text(cfg['gateway'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 20),

                        // MODULE 3: Coupon Code Input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: couponController,
                                decoration: InputDecoration(
                                  labelText: 'কুপন কোড (Module 3)',
                                  hintText: 'যেমন: EID50',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onPressed: () {
                                final code = couponController.text.trim().toUpperCase();
                                if (code == 'EID50') {
                                  setModalState(() {
                                    discount = 50;
                                    promoMsg = '🎉 ৫০% ছাড় প্রযোজ্য হয়েছে!';
                                  });
                                } else {
                                  setModalState(() {
                                    discount = 0;
                                    promoMsg = '❌ কুপন কোড সঠিক নয়।';
                                  });
                                }
                              },
                              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        if (promoMsg != null) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              promoMsg!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: discount > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],

                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text('পরিশোধযোগ্য মোট:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Row(
                              children: [
                                if (discount > 0) ...[
                                  Text(
                                    '${cfg['currency']} $basePrice',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  '${cfg['currency']} $payable',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await ApiService().unlockRecord(record.id);
                      setState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('পেমেন্ট সফল! ৭ দিনের জন্য মোবাইল নম্বর ও লাইভ চ্যাট আনলক হয়েছে।'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    },
                    child: Text('পেমেন্ট নিশ্চিত করুন (${cfg['currency']} $payable)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLiveChatDialog(EntityRecord record) {
    final messageController = TextEditingController();
    final List<Map<String, String>> messages = [
      {'sender': 'buyer', 'text': 'আসসালামু আলাইকুম ভাই, গাড়ি কি কাল সকাল ৮টায় পাওয়া যাবে?'},
      {'sender': 'seller', 'text': 'ওয়ালাইকুম আসসালাম। হ্যাঁ ভাই, একদম রেডি থাকবে।'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setChatState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${record.userName} • লাইভ চ্যাট সক্রিয়', style: const TextStyle(fontSize: 11, color: Color(0xFF059669))),
                            ],
                          ),
                        ),
                        // MODULE 2: "কাজ শেষ হয়েছে?" Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showRatingDialog(record);
                          },
                          icon: const Icon(Icons.star, size: 14),
                          label: const Text('কাজ শেষ হয়েছে?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Chat messages
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = messages[i];
                          final isBuyer = msg['sender'] == 'buyer';
                          return Align(
                            alignment: isBuyer ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isBuyer ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg['text']!,
                                style: TextStyle(
                                  color: isBuyer ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            decoration: InputDecoration(
                              hintText: 'মেসেজ লিখুন...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                          icon: const Icon(Icons.send, size: 18),
                          onPressed: () {
                            final text = messageController.text.trim();
                            if (text.isNotEmpty) {
                              setChatState(() {
                                messages.add({'sender': 'buyer', 'text': text});
                              });
                              messageController.clear();
                              Future.delayed(const Duration(milliseconds: 1000), () {
                                setChatState(() {
                                  messages.add({'sender': 'seller', 'text': 'জি ধন্যবাদ। সময়মত পৌঁছে যাবে।'});
                                });
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRatingDialog(EntityRecord record) {
    int rating = 5;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setRatingState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('সার্ভিসের রেটিং দিন (Module 2)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${record.userName} এর কাজের মান কেমন ছিল?', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        starIndex <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setRatingState(() => rating = starIndex),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reviewController,
                  decoration: InputDecoration(
                    hintText: 'মতামত লিখুন (যেমন: চমৎকার সার্ভিস)...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('আপনার রেটিং সফলভাবে জমা হয়েছে! ধন্যবাদ।')),
                  );
                },
                child: const Text('রেটিং জমা দিন', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('SERVICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '👤 ${user?.fullName ?? 'ইউজার'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          // Country Switcher
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountry,
              items: _countryConfigs.keys.map((code) {
                return DropdownMenuItem(
                  value: code,
                  child: Text('${_countryConfigs[code]!['flag']} $code', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (code) {
                if (code != null) {
                  setState(() => _selectedCountry = code);
                  _loadRecords();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: Color(0xFF64748B)),
            onPressed: widget.onLogout,
            tooltip: 'লগআউট',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // Quick Module Action Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // NID Verify Button (Module 1)
                  ActionChip(
                    avatar: Icon(
                      user?.isVerified == true ? Icons.verified : Icons.shield_outlined,
                      size: 16,
                      color: user?.isVerified == true ? const Color(0xFF059669) : const Color(0xFF475569),
                    ),
                    label: Text(
                      user?.isVerified == true ? 'NID ভেরিফায়েড ✅' : 'NID Verify করুন',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: user?.isVerified == true ? const Color(0xFF065F46) : const Color(0xFF334155),
                      ),
                    ),
                    backgroundColor: user?.isVerified == true ? const Color(0xFFECFDF5) : Colors.white,
                    side: BorderSide(color: user?.isVerified == true ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                    onPressed: _showNidVerificationDialog,
                  ),
                  const SizedBox(width: 8),

                  // Refer & Earn Button (Module 3)
                  ActionChip(
                    avatar: const Icon(Icons.card_giftcard, size: 16, color: Color(0xFFE11D48)),
                    label: const Text('রেফার ও আয় (৳১০০)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBE123C))),
                    backgroundColor: const Color(0xFFFFF1F2),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    onPressed: _showReferralDialog,
                  ),
                  const SizedBox(width: 8),

                  // Ekok Bijoyi Simulator
                  ActionChip(
                    avatar: const Icon(Icons.bolt, size: 16, color: Color(0xFFD97706)),
                    label: const Text('একক বিজয়ী সিমুলেটর', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    backgroundColor: const Color(0xFFFFFBEB),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SingleWinnerScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // MODULE 4 B: 2 BIG CARDS (USER PANEL 2 BUTTONS)
            Row(
              children: [
                // CARD 1: পোস্ট করুন (Provider Post)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePostScreen(
                            entityKey: _selectedEntityKey,
                            onPostCreated: _loadRecords,
                          ),
                        ),
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
                          const Text('সার্ভিস প্রদানকারী', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // CARD 2: আবেদন করুন (Seeker Request)
                Expanded(
                  child: InkWell(
                    onTap: () {
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
                          const Text('কাছাকাছি প্রোভাইডার', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Navigation Pills
            Row(
              children: [
                _buildCategoryTab('যানবাহন ভাড়া', 'vehicles'),
                const SizedBox(width: 8),
                _buildCategoryTab('হোম ও বাণিজ্যিক সেবা', 'services'),
              ],
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_records.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('কোনো পোস্ট পাওয়া যায়নি।')))
            else
              ..._records.map((record) => _buildPremiumCard(record)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String title, String key) {
    final isSelected = _selectedEntityKey == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedEntityKey = key);
        _loadRecords();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  /// PREMIUM CARD UI EXACTLY AS PREVIEW
  Widget _buildPremiumCard(EntityRecord record) {
    final cfg = _countryConfigs[_selectedCountry]!;
    final unlockFeeLocal = (record.unlockPriceUsd * (cfg['rate'] as num)).round();

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
            // Top Row: Category + Location
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
                    record.entityKey == 'vehicles' ? 'যানবাহন ভাড়া' : 'পেশাদার সেবা',
                    style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      record.approxLocation,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              record.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.3),
            ),
            const SizedBox(height: 6),

            // Second Row: Provider Name + Verified Badge + Star Rating • Level Badge
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

            // Middle Grid (6-7 fields from custom_col_1..5)
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
                      Expanded(child: _buildGridField('জ্বালানির ধরন', record.customCol1 ?? 'CNG')),
                      Expanded(child: _buildGridField('জামানতের পরিমাণ', '${cfg['currency']} ${record.customCol2 ?? '5000'}')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGridField('ঘণ্টাপ্রতি ভাড়া', '${cfg['currency']} ${record.customCol3 ?? '450'}')),
                      Expanded(child: _buildGridField('মডেল সাল', record.customCol4 ?? '2018')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGridField('আসন সংখ্যা', '${record.customCol5 ?? '4'} জন')),
                      Expanded(child: _buildGridField('এসি কন্ডিশন', 'Chilled AC')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Locked / Unlocked Box
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
                    const SizedBox(height: 6),
                    Text('সরাসরি মোবাইল: ${record.customCol6 ?? '+8801711223344'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                    Text('গ্যারেজের নির্ভুল ঠিকানা: ${record.customCol7 ?? 'উত্তরা সেক্টর ৭, রোড ৪, বাসা ১২, ঢাকা'}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
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
                          Text('মোবাইল ও নির্ভুল ঠিকানা: *** Unlock Required ***', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF92400E))),
                          SizedBox(height: 2),
                          Text('সরাসরি যোগাযোগ ও লাইভ চ্যাট এর জন্য আনলক করুন।', style: TextStyle(fontSize: 10, color: Color(0xFF78350F))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Bottom Action Button
            if (record.isUnlocked)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('সরাসরি চ্যাট করুন (Live Chat)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _showLiveChatDialog(record),
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
                label: Text('যোগাযোগ ও গোপন তথ্য আনলক করুন (${cfg['currency']} $unlockFeeLocal)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _showUnlockPaymentModal(record),
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
