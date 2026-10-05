import 'package:flutter/material.dart';
import '../models/entity_record.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String entityKey;
  final VoidCallback onPostCreated;

  const CreatePostScreen({
    super.key,
    this.entityKey = 'vehicles',
    required this.onPostCreated,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  // Dynamic 15 Columns field controllers
  final Map<String, TextEditingController> _colControllers = {};
  String _selectedFuelType = 'CNG';
  String? _leakWarning;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 15; i++) {
      _colControllers['custom_col_$i'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    for (final c in _colControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Strict Contact Leakage Check (> 5 digits anywhere in public fields)
  bool _checkContactLeak(String text) {
    if (text.isEmpty) return false;
    // Check if more than 5 digits clustered together or in total
    final digits = text.replaceAll(RegExp(r'[^0-9০-৯]'), '');
    return digits.length > 5;
  }

  void _handleSubmit() {
    setState(() => _leakWarning = null);

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শিরোনাম এবং আনুমানিক এলাকা আবশ্যক')),
      );
      return;
    }

    // Check contact leakage in public title or public location
    if (_checkContactLeak(title)) {
      setState(() => _leakWarning = '🛑 শিরোনামে ৫টির বেশি সংখ্যা বা ফোন নম্বর দেওয়া নিষিদ্ধ!');
      return;
    }

    if (_checkContactLeak(location)) {
      setState(() => _leakWarning = '🛑 পাবলিক লোকেশন ফিল্ডে সরাসরি হোল্ডিং বা ফোন নম্বর দেওয়া যাবে না!');
      return;
    }

    // Check public column values
    for (int i = 1; i <= 5; i++) {
      final val = _colControllers['custom_col_$i']?.text.trim() ?? '';
      if (_checkContactLeak(val)) {
        setState(() => _leakWarning = '🛑 পাবলিক ফিল্ড custom_col_$i এ ৫টির বেশি সংখ্যা সনাক্ত হয়েছে!');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final user = AuthService().currentUser;

    final newRecord = EntityRecord(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      entityKey: widget.entityKey,
      country: 'BD',
      approxLocation: location,
      userName: user?.fullName ?? 'নতুন প্রোভাইডার',
      isVerified: user?.isVerified ?? false,
      userAvgRating: user?.avgRating ?? 5.0,
      totalReviews: 1,
      userLevel: user?.level ?? 'New',
      customCol1: _selectedFuelType,
      customCol2: _colControllers['custom_col_2']?.text.trim().isEmpty == true ? '5000' : _colControllers['custom_col_2']!.text.trim(),
      customCol3: _colControllers['custom_col_3']?.text.trim().isEmpty == true ? '500' : _colControllers['custom_col_3']!.text.trim(),
      customCol4: _colControllers['custom_col_4']?.text.trim().isEmpty == true ? '2019' : _colControllers['custom_col_4']!.text.trim(),
      customCol5: _colControllers['custom_col_5']?.text.trim().isEmpty == true ? '4' : _colControllers['custom_col_5']!.text.trim(),
      customCol6: _colControllers['custom_col_6']?.text.trim().isEmpty == true ? (user?.phone ?? '+8801711223344') : _colControllers['custom_col_6']!.text.trim(),
      customCol7: _colControllers['custom_col_7']?.text.trim().isEmpty == true ? 'House 22, Road 4, Sector 7, Dhaka' : _colControllers['custom_col_7']!.text.trim(),
      isUnlocked: false,
      unlockPriceUsd: 1.0,
    );

    ApiService().addRecord(newRecord);
    widget.onPostCreated();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 আপনার পোস্ট সফলভাবে প্রকাশিত হয়েছে!'),
        backgroundColor: Color(0xFF059669),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('পোস্ট তৈরি করুন (15-Columns)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('১৫টি ডায়নামিক কলাম সিস্টেম', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('পাবলিক ফিল্ডে সরাসরি ফোন নম্বর বা ঠিকানা দেওয়া নিষিদ্ধ। ব্যক্তিগত তথ্য স্বয়ংক্রিয়ভাবে লক করা থাকবে।', style: TextStyle(fontSize: 11, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_leakWarning != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _leakWarning!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'পোস্টের শিরোনাম (Title) *',
                  hintText: 'যেমন: Toyota Axio 2018 - Personal Used',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 14),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'আনুমানিক এলাকা (Approx Location) *',
                  hintText: 'যেমন: উত্তরা সেক্টর ৭, ঢাকা',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 18),

              const Text('পাবলিক ফিল্ডসমূহ (সকলের জন্য দৃশ্যমান)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),

              // Column 1: Fuel Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFuelType,
                decoration: InputDecoration(
                  labelText: 'জ্বালানির ধরন (custom_col_1)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.local_gas_station),
                ),
                items: const [
                  DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                  DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                  DropdownMenuItem(value: 'Octane', child: Text('Octane')),
                  DropdownMenuItem(value: 'Electric', child: Text('Electric (EV)')),
                ],
                onChanged: (val) => setState(() => _selectedFuelType = val ?? 'CNG'),
              ),
              const SizedBox(height: 12),

              // Column 2: Security Deposit
              TextFormField(
                controller: _colControllers['custom_col_2'],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'জামানতের পরিমাণ (custom_col_2)',
                  hintText: '৫০০০',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Column 3: Hourly Rate
              TextFormField(
                controller: _colControllers['custom_col_3'],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ঘণ্টাপ্রতি ভাড়া (custom_col_3)',
                  hintText: '৪৫০',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Column 4 & 5
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colControllers['custom_col_4'],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'মডেল সাল (col_4)',
                        hintText: '2018',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _colControllers['custom_col_5'],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'আসন সংখ্যা (col_5)',
                        hintText: '4',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Private Columns Section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lock, color: Color(0xFFB45309), size: 18),
                        SizedBox(width: 8),
                        Text('লকড ও ব্যক্তিগত তথ্য (Private Fields)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('এই তথ্যগুলো আনলক ফি প্রদানের পূর্বে সুরক্ষিত ও গোপন থাকবে।', style: TextStyle(fontSize: 11, color: Color(0xFF78350F))),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _colControllers['custom_col_6'],
                      decoration: InputDecoration(
                        labelText: 'মালিকের সরাসরি মোবাইল (custom_col_6) 🔒',
                        hintText: '+8801711223344',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _colControllers['custom_col_7'],
                      decoration: InputDecoration(
                        labelText: 'গ্যারেজের নির্ভুল ঠিকানা (custom_col_7) 🔒',
                        hintText: 'House 12, Road 4, Sector 7, Uttara, Dhaka',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: const Icon(Icons.send_rounded),
                label: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('পোস্ট প্রকাশ করুন (Publish Post)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
