import 'package:flutter/material.dart';

class SingleWinnerScreen extends StatefulWidget {
  const SingleWinnerScreen({super.key});

  @override
  State<SingleWinnerScreen> createState() => _SingleWinnerScreenState();
}

class _SingleWinnerScreenState extends State<SingleWinnerScreen> {
  String _requestStatus = 'open'; // 'open' | 'accepted'
  String? _winnerId;
  String? _winnerName;
  bool _seekerFeeCharged = false;

  final TextEditingController _couponController = TextEditingController(text: 'EID50');
  double _discountPercent = 0.0;
  String? _couponMessage;

  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'prov_1',
      'name': 'রহিম এসি সলিউশন',
      'location': 'মিরপুর ১১, ঢাকা',
      'distance': 0.98,
      'isNearby': true,
      'isVerified': true,
      'level': 'Platinum',
      'rating': 4.9,
      'reviews': 140,
      'feeCharged': 0,
      'status': 'idle', // 'idle', 'winner', 'rejected_409'
      'rejectionReason': null,
    },
    {
      'id': 'prov_2',
      'name': 'করিম ইলেকট্রনিক্স ও এসি',
      'location': 'মিরপুর ২, ঢাকা',
      'distance': 1.54,
      'isNearby': true,
      'isVerified': true,
      'level': 'Gold',
      'rating': 4.8,
      'reviews': 120,
      'feeCharged': 0,
      'status': 'idle',
      'rejectionReason': null,
    },
    {
      'id': 'prov_unverified',
      'name': 'আলমগীর টেকনিশিয়ান',
      'location': 'মিরপুর ১০, ঢাকা',
      'distance': 0.45,
      'isNearby': true,
      'isVerified': false,
      'level': 'Silver',
      'rating': 4.6,
      'reviews': 24,
      'feeCharged': 0,
      'status': 'idle',
      'rejectionReason': 'NID Verify করুন, তারপর Request পাবেন',
    },
    {
      'id': 'prov_3',
      'name': 'হাসান টেকনিশিয়ান',
      'location': 'আগ্রাবাদ, চট্টগ্রাম',
      'distance': 216.5,
      'isNearby': false,
      'isVerified': true,
      'level': 'Gold',
      'rating': 4.7,
      'reviews': 65,
      'feeCharged': 0,
      'status': 'idle',
      'rejectionReason': 'দূরবর্তী এলাকা (>৫ কিমি), নোটিফিকেশন পাঠানো হয়নি',
    },
  ];

  final List<String> _auditLogs = [
    '📢 গ্রাহক তানভীর আহমেদ মিরপুর ১০ থেকে এসি মেরামতের রিকোয়েস্ট পোস্ট করেছেন।',
    '🛡️ ট্রাস্ট ও সেফটি: শুধুমাত্র NID Verified প্রোভাইডারদের নোটিফিকেশন পাঠানো হয়েছে।',
    '⭐ গ্যামিফিকেশন ফিল্টার: Platinum ও Gold প্রোভাইডাররা অগ্রাধিকার তালিকায় শীর্ষে।',
    '📡 লোকেশন ফিল্টার সক্রিয়: ৫ কিমি দূরত্বের মধ্যে রহিম ও করিমকে নোটিফাই করা হয়েছে।',
  ];

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'EID50') {
      setState(() {
        _discountPercent = 50.0;
        _couponMessage = '🎉 কুপন EID50 সফল! ৫০% ছাড় সক্রিয়।';
        _auditLogs.insert(0, '🏷️ [COUPON] কুপন EID50 প্রযোজ্য: ফি ৫০ টাকা থেকে কমে ২৫ টাকা হয়েছে।');
      });
    } else {
      setState(() {
        _discountPercent = 0.0;
        _couponMessage = '❌ কুপন কোড সঠিক নয়।';
      });
    }
  }

  void _handleAccept(String providerId) {
    final prov = _providers.firstWhere((p) => p['id'] == providerId);

    if (!prov['isVerified']) {
      setState(() {
        _auditLogs.insert(0, '🚫 [BLOCKED] ${prov['name']} আনভেরিফাইড! NID ভেরিফিকেশন ছাড়া রিকোয়েস্ট গ্রহণ করা যাবে না।');
      });
      return;
    }

    // ROW-LOCK CHECK:
    if (_requestStatus != 'open' || _winnerId != null) {
      setState(() {
        prov['status'] = 'rejected_409';
        prov['rejectionReason'] = '🛑 HTTP 409: ইতিমধ্যে অন্য একজন গ্রহণ করেছেন! আপনার কোনো ফি কাটা হয়নি (৳০)।';
        _auditLogs.insert(0, '❌ [HTTP 409 Conflict] ${prov['name']} এর চেষ্টা ব্যর্থ! অন্য কেউ আগে গ্রহণ করেছেন (৳০ কর্তন)।');
      });
      return;
    }

    final double baseFee = 50.0;
    final int finalFee = (baseFee * (1 - _discountPercent / 100)).round();

    setState(() {
      _requestStatus = 'accepted';
      _winnerId = providerId;
      _winnerName = prov['name'] as String;
      _seekerFeeCharged = true;

      prov['status'] = 'winner';
      prov['feeCharged'] = finalFee;

      _auditLogs.insert(0, '🏆 [SINGLE WINNER] ${prov['name']} বিজয়ী! প্রোভাইডারের থেকে ৳$finalFee এবং গ্রাহকের থেকে ৳৫০ কাটা হয়েছে।');
    });
  }

  void _simulateSimultaneousRace() {
    _handleAccept('prov_1');
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _handleAccept('prov_2');
    });
  }

  void _reset() {
    setState(() {
      _requestStatus = 'open';
      _winnerId = null;
      _winnerName = null;
      _seekerFeeCharged = false;
      _discountPercent = 0.0;
      _couponMessage = null;
      for (final p in _providers) {
        p['status'] = 'idle';
        p['feeCharged'] = 0;
        if (p['id'] == 'prov_unverified') {
          p['rejectionReason'] = 'NID Verify করুন, তারপর Request পাবেন';
        } else if (p['id'] == 'prov_3') {
          p['rejectionReason'] = 'দূরবর্তী এলাকা (>৫ কিমি), নোটিফিকেশন পাঠানো হয়নি';
        } else {
          p['rejectionReason'] = null;
        }
      }
      _auditLogs.clear();
      _auditLogs.addAll([
        '📢 গ্রাহক তানভীর আহমেদ মিরপুর ১০ থেকে এসি মেরামতের রিকোয়েস্ট পোস্ট করেছেন।',
        '🛡️ ট্রাস্ট ও সেফটি: শুধুমাত্র NID Verified প্রোভাইডারদের নোটিফিকেশন পাঠানো হয়েছে।',
        '⭐ গ্যামিফিকেশন ফিল্টার: Platinum ও Gold প্রোভাইডাররা অগ্রাধিকার তালিকায় শীর্ষে।',
        '📡 লোকেশন ফিল্টার সক্রিয়: ৫ কিমি দূরত্বের মধ্যে রহিম ও করিমকে নোটিফাই করা হয়েছে।',
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('একক বিজয়ী সিমুলেটর (Single Winner)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'রিসেট',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bolt, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'একক বিজয়ী ও রেস কন্ডিশন ইঞ্জিন',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'যিনি আগে রিকোয়েস্ট গ্রহণ করবেন শুধু তার কাছ থেকেই ফি কাটা হবে। একসাথে একাধিক ব্যক্তি ক্লিক করলেও শুধুমাত্র ১ জনের ফি কাটা হবে, বাকিরা বাদ পড়বেন।',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade500,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _requestStatus == 'accepted' ? null : _simulateSimultaneousRace,
                        icon: const Icon(Icons.flash_on, size: 16),
                        label: const Text('একসাথে গ্রহণের চেষ্টা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _reset,
                        child: const Text('রিসেট', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seeker Request Details Card with Coupon Input
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('সেবা গ্রহীতার রিকোয়েস্ট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _requestStatus == 'open' ? Colors.amber.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _requestStatus == 'open' ? Colors.amber.shade300 : Colors.green.shade300),
                          ),
                          child: Text(
                            _requestStatus == 'open' ? 'উন্মুক্ত (Open)' : 'গৃহীত (Accepted)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _requestStatus == 'open' ? Colors.amber.shade900 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('জরুরী স্প্লিট এসি গ্যাস চার্জ ও মেরামত প্রয়োজন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Text('লোকেশন: মিরপুর ১০, ঢাকা • ম্যাচ ফি: ৳ ৫০ / জন', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 10),

                    // Coupon Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            decoration: InputDecoration(
                              labelText: 'কুপন কোড (যেমন: EID50)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _applyCoupon,
                          child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    if (_couponMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _couponMessage!,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _discountPercent > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('কাছাকাছি সার্ভিস প্রোভাইডারগণ (৫ কিমি)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),

            // Provider Cards
            ..._providers.map((prov) {
              final isWinner = prov['status'] == 'winner';
              final is409 = prov['status'] == 'rejected_409';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isWinner
                        ? const Color(0xFF10B981)
                        : is409
                            ? const Color(0xFFF87171)
                            : const Color(0xFFE2E8F0),
                    width: isWinner || is409 ? 2 : 1,
                  ),
                ),
                color: isWinner
                    ? const Color(0xFFECFDF5)
                    : is409
                        ? const Color(0xFFFEF2F2)
                        : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(prov['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 6),
                                    if (prov['isVerified'])
                                      const Icon(Icons.verified, color: Color(0xFF059669), size: 16)
                                    else
                                      const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 16),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '⭐ ${prov['rating']} (${prov['reviews']}) • ${prov['level']} Level • ${prov['distance']} km দূরে',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          if (prov['isNearby'])
                            prov['isVerified']
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isWinner
                                          ? const Color(0xFF059669)
                                          : is409
                                              ? const Color(0xFFDC2626)
                                              : primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _requestStatus == 'accepted' && prov['status'] == 'idle'
                                        ? null
                                        : () => _handleAccept(prov['id'] as String),
                                    child: Text(
                                      isWinner
                                          ? 'বিজয়ী (৳${prov['feeCharged']})'
                                          : is409
                                              ? 'বাদ (৳০)'
                                              : 'গ্রহণ করুন',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.shade300),
                                    ),
                                    child: const Text('NID Verify করুন', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                                  )
                          else
                            const Text('এলাকার বাইরে', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      if (prov['rejectionReason'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          prov['rejectionReason'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            // Live Audit Logs Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('লাইভ অডিট লগ (Race Condition Guard):', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ..._auditLogs.take(5).map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('> $log', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
