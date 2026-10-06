import 'package:flutter/material.dart';
import '../models/entity_record.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String entityKey;
  final String? initialSectionKey;
  final EntityRecord? editRecord;
  final VoidCallback onPostCreated;

  const CreatePostScreen({
    super.key,
    this.entityKey = 'vehicles',
    this.initialSectionKey,
    this.editRecord,
    required this.onPostCreated,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  final Map<String, TextEditingController> _colControllers = {};
  
  String _selectedSectionKey = 'rent';
  String _selectedFuelType = 'CNG';
  String? _leakWarning;
  bool _isSubmitting = false;

  // Camera & Image simulation state
  bool _hasAttachedPhoto = false;
  String _attachedPhotoType = 'ক্যামেরা থেকে তোলা সার্ভিস ছবি 📸';

  @override
  void initState() {
    super.initState();
    final edit = widget.editRecord;

    _titleController = TextEditingController(text: edit?.title ?? '');
    _locationController = TextEditingController(text: edit?.approxLocation ?? '');
    _selectedSectionKey = edit?.sectionKey ?? widget.initialSectionKey ?? 'rent';

    for (int i = 1; i <= 15; i++) {
      String initialVal = '';
      if (edit != null) {
        switch (i) {
          case 1: initialVal = edit.customCol1 ?? ''; break;
          case 2: initialVal = edit.customCol2 ?? ''; break;
          case 3: initialVal = edit.customCol3 ?? ''; break;
          case 4: initialVal = edit.customCol4 ?? ''; break;
          case 5: initialVal = edit.customCol5 ?? ''; break;
          case 6: initialVal = edit.customCol6 ?? ''; break;
          case 7: initialVal = edit.customCol7 ?? ''; break;
          case 8: initialVal = edit.customCol8 ?? ''; break;
          case 9: initialVal = edit.customCol9 ?? ''; break;
          case 10: initialVal = edit.customCol10 ?? ''; break;
          case 11: initialVal = edit.customCol11 ?? ''; break;
          case 12: initialVal = edit.customCol12 ?? ''; break;
          case 13: initialVal = edit.customCol13 ?? ''; break;
          case 14: initialVal = edit.customCol14 ?? ''; break;
          case 15: initialVal = edit.customCol15 ?? ''; break;
        }
      }
      _colControllers['custom_col_$i'] = TextEditingController(text: initialVal);
    }

    if (edit?.customCol1 != null && ['CNG', 'Petrol', 'Octane', 'Electric'].contains(edit!.customCol1)) {
      _selectedFuelType = edit.customCol1!;
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

  /// Strict Contact Leakage Check (> 5 digits in public fields)
  bool _checkContactLeak(String text) {
    if (text.isEmpty) return false;
    final digits = text.replaceAll(RegExp(r'[^0-9০-৯]'), '');
    return digits.length > 5;
  }

  void _handleSimulateCamera() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.camera_alt, color: Color(0xFF1E3A8A), size: 24),
                SizedBox(width: 10),
                Text('ক্যামেরা পারমিশন ও ছবি সংযুক্তি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'পোস্টের বিশ্বাসযোগ্যতা বাড়াতে সরাসরি ক্যামেরা দিয়ে লাইভ ছবি তুলুন অথবা গ্যালারি থেকে যুক্ত করুন।',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.photo_camera, color: Color(0xFF1E3A8A)),
              ),
              title: const Text('লাইভ ক্যামেরা খুলুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('ক্যামেরা পারমিশন অনুমোদিত ✅', style: TextStyle(fontSize: 11, color: Color(0xFF059669))),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _hasAttachedPhoto = true;
                  _attachedPhotoType = 'লাইভ ক্যামেরা শট (Live Photo Capture) 📸';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📸 ছবি সফলভাবে ক্যামেরা থেকে সংযুক্ত হয়েছে!')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.photo_library, color: Color(0xFF475569)),
              ),
              title: const Text('গ্যালারি থেকে নির্বাচন করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _hasAttachedPhoto = true;
                  _attachedPhotoType = 'গ্যালারি ইমেজ (Gallery Asset) 🖼️';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🖼️ গ্যালারি থেকে ছবি সফলভাবে যুক্ত হয়েছে!')),
                );
              },
            ),
          ],
        ),
      ),
    );
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

    if (widget.editRecord != null) {
      // Edit existing post
      final updatedCols = <String, String>{};
      for (int i = 1; i <= 15; i++) {
        final val = _colControllers['custom_col_$i']?.text.trim();
        if (val != null && val.isNotEmpty) {
          updatedCols['custom_col_$i'] = val;
        }
      }
      if (_selectedSectionKey == 'rent') {
        updatedCols['custom_col_1'] = _selectedFuelType;
      }

      ApiService().editRecord(
        widget.editRecord!.id,
        newTitle: title,
        newLocation: location,
        updatedColumns: updatedCols,
      );

      widget.onPostCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 পোস্টটি সফলভাবে আপডেট করা হয়েছে!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.pop(context);
      return;
    }

    // Create brand new post
    final newRecord = EntityRecord(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      entityKey: widget.entityKey,
      sectionKey: _selectedSectionKey,
      country: 'BD',
      approxLocation: location,
      userName: user?.fullName ?? 'নতুন প্রোভাইডার',
      userId: user?.id,
      isVerified: user?.isVerified ?? false,
      userAvgRating: user?.avgRating ?? 5.0,
      totalReviews: 1,
      userLevel: user?.level ?? 'New',
      userAvatarUrl: user?.isVerified == true
          ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'
          : null,
      customCol1: _selectedSectionKey == 'rent' ? _selectedFuelType : (_colControllers['custom_col_1']?.text.trim() ?? 'সেবা'),
      customCol2: _colControllers['custom_col_2']?.text.trim().isEmpty == true ? '5000' : _colControllers['custom_col_2']!.text.trim(),
      customCol3: _colControllers['custom_col_3']?.text.trim().isEmpty == true ? '500' : _colControllers['custom_col_3']!.text.trim(),
      customCol4: _colControllers['custom_col_4']?.text.trim().isEmpty == true ? '2022' : _colControllers['custom_col_4']!.text.trim(),
      customCol5: _colControllers['custom_col_5']?.text.trim().isEmpty == true ? '4' : _colControllers['custom_col_5']!.text.trim(),
      customCol6: _colControllers['custom_col_6']?.text.trim().isEmpty == true ? (user?.phone ?? '+8801711223344') : _colControllers['custom_col_6']!.text.trim(),
      customCol7: _colControllers['custom_col_7']?.text.trim().isEmpty == true ? 'উত্তরা সেক্টর ৭, ঢাকা' : _colControllers['custom_col_7']!.text.trim(),
      reactionsCount: 0,
      acceptedCount: 0,
      isUnlocked: false,
      unlockPriceUsd: 1.0,
      authorValidityDays: 7, // Author কর্তৃক নির্দিষ্ট সময়সীমা (৭ দিন)
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
    final isEditing = widget.editRecord != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'পোস্ট এডিট করুন' : 'নতুন পোস্ট তৈরি করুন',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'পেজ ব্যবহারের নিয়ম',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('পোস্ট তৈরির নিয়মাবলী', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  content: const Text(
                    '১. সঠিক ক্যাটাগরি ও সেকশন বেছে নিন (ভাড়া, মার্কেট, ডেলিভারি, মজদুরি)।\n'
                    '২. টাইটেল ও এলাকার নাম স্পষ্ট করে লিখুন।\n'
                    '৩. পাবলিক ফিল্ডে ফোন নাম্বার দেওয়া নিষিদ্ধ (অ্যালগরিদম ৫টির বেশি ডিজিট পেলে পোস্ট আটকে দেবে)।\n'
                    '৪. আপনার ফোন ও সুনির্দিষ্ট ঠিকানা নিচে প্রাইভেট বক্সে দিন—আনলক ফি প্রদানের পরই অন্য ব্যবহারকারী দেখতে পাবেন।\n'
                    '৫. ক্যামেরা বাটন প্রেস করে সার্ভিসের বাস্তব ছবি যুক্ত করুন।',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বুঝেছি')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section Selector (Author Driven Multi-Section Architecture)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'পোস্টের সেকশন নির্বাচন করুন *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ApiService.sections
                          .where((s) => s['key'] != 'all')
                          .map((sec) {
                        final isSel = _selectedSectionKey == sec['key'];
                        return ChoiceChip(
                          label: Text(
                            sec['label_bn'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: primaryColor,
                          backgroundColor: const Color(0xFFF1F5F9),
                          onSelected: (val) {
                            if (val) setState(() => _selectedSectionKey = sec['key'] as String);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Banner Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('১৫টি ডায়নামিক কলাম সিস্টেম (Author Driven)', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12)),
                          SizedBox(height: 2),
                          Text('পাবলিক ফিল্ডে সরাসরি ফোন নম্বর দেওয়া নিষিদ্ধ। যোগাযোগের তথ্য স্বয়ংক্রিয়ভাবে লক থাকবে।', style: TextStyle(fontSize: 11, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (_leakWarning != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
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
                  hintText: 'যেমন: Toyota Axio 2018 - ব্যক্তিগত ব্যবহারে নিখুঁত',
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
              const SizedBox(height: 14),

              // Camera and Photos Upload Block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Color(0xFF1E3A8A)),
                      onPressed: _handleSimulateCamera,
                      tooltip: 'ক্যামেরা থেকে ছবি নিন',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasAttachedPhoto ? _attachedPhotoType : 'ক্যামেরা / ছবি সংযুক্তি (ঐচ্ছিক)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _hasAttachedPhoto ? const Color(0xFF059669) : const Color(0xFF334155),
                            ),
                          ),
                          const Text(
                            'ক্যামেরা পারমিশন ও ফাইল স্ক্যানিং সক্ষম',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _handleSimulateCamera,
                      child: Text(_hasAttachedPhoto ? 'পরিবর্তন' : 'ক্যামেরা'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text('পাবলিক ফিল্ডসমূহ (সকলের জন্য দৃশ্যমান)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),

              // Fuel Type (If rent section)
              if (_selectedSectionKey == 'rent') ...[
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
              ] else ...[
                TextFormField(
                  controller: _colControllers['custom_col_1'],
                  decoration: InputDecoration(
                    labelText: 'ক্যাটাগরি বা কাজের ধরন (custom_col_1)',
                    hintText: 'যেমন: ইলেকট্রিক ওয়্যারিং / ডেলিভারি পার্সেল',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Column 2: Price / Deposit
              TextFormField(
                controller: _colControllers['custom_col_2'],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _selectedSectionKey == 'rent' ? 'জামানতের পরিমাণ (custom_col_2)' : 'মূল্য / পারিশ্রমিক (custom_col_2)',
                  hintText: '৫০০০',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),

              // Column 3: Rate / Warranty
              TextFormField(
                controller: _colControllers['custom_col_3'],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _selectedSectionKey == 'rent' ? 'ঘণ্টাপ্রতি ভাড়া (custom_col_3)' : 'ভিজিটিং চার্জ বা রেট (custom_col_3)',
                  hintText: '৪৫০',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.timer_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Column 4 & 5
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colControllers['custom_col_4'],
                      decoration: InputDecoration(
                        labelText: 'মডেল / অভিজ্ঞতা (col_4)',
                        hintText: '2019 / 5 yrs',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _colControllers['custom_col_5'],
                      decoration: InputDecoration(
                        labelText: 'আসন / কন্ডিশন (col_5)',
                        hintText: '৪ জন / Chilled AC',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Private Box
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
                        hintText: 'উত্তরা সেক্টর ৭, রোড ৪, বাসা ১২, ঢাকা',
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
                icon: Icon(isEditing ? Icons.check_circle : Icons.send_rounded),
                label: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        isEditing ? 'পরিবর্তন সংরক্ষণ করুন (Save Edits)' : 'পোস্ট প্রকাশ করুন (Publish Post)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
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
