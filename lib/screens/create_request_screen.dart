import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CreateRequestScreen extends StatefulWidget {
  final VoidCallback onRequestCreated;

  const CreateRequestScreen({super.key, required this.onRequestCreated});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController(text: 'মিরপুর ১০, ঢাকা');
  final _budgetController = TextEditingController(text: '১৫০০');
  final _detailsController = TextEditingController();

  String _selectedCategory = 'এসি সার্ভিসিং (AC Repair)';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'এসি সার্ভিসিং (AC Repair)', 'icon': Icons.ac_unit, 'fee': 50},
    {'name': 'ইলেকট্রিশিয়ান (Electrician)', 'icon': Icons.bolt, 'fee': 100},
    {'name': 'প্লাম্বিং সার্ভিস (Plumbing)', 'icon': Icons.plumbing, 'fee': 60},
    {'name': 'যানবাহন ও লজিস্টিকস (Rental)', 'icon': Icons.directions_car, 'fee': 120},
    {'name': 'হোম ক্লিনিং (Cleaning)', 'icon': Icons.cleaning_services, 'fee': 80},
    {'name': 'ডেলিভারি পার্সেল (Delivery)', 'icon': Icons.local_shipping, 'fee': 40},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('রিকোয়েস্টের শিরোনাম ও লোকেশন দিন')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      widget.onRequestCreated();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.check_circle, color: Color(0xFF059669), size: 54),
          title: const Text('রিকোয়েস্ট সফলভাবে পাঠানো হয়েছে!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text(
            'আপনার রিকোয়েস্ট কাছাকাছি ৫ কিমি দূরত্বের ভেরিফায়েড প্রোভাইডারদের কাছে নোটিফিকেশন অ্যালার্ট আকারে পাঠানো হয়েছে। যিনি আগে গ্রহণ করবেন, তার সাথেই সংযোগ স্থাপিত হবে।\n\nপোস্টের সময়সীমা Author কর্তৃক নির্দিষ্ট (৭ দিন)।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('ঠিক আছে', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF059669);

    return Scaffold(
      appBar: AppBar(
        title: const Text('সার্ভিসের জন্য আবেদন করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  title: const Text('আবেদন করার নিয়মাবলী', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  content: const Text(
                    '১. আপনার কি সেবা প্রয়োজন তা সংক্ষেপে লিখুন।\n'
                    '২. আপনার আনুমানিক এলাকা ও সম্ভাব্য বাজেট উল্লেখ করুন।\n'
                    '৩. শুধুমাত্র NID ভেরিফাইড ইউজাররাই আবেদন প্রচার বা গ্রহণ করতে পারবেন।\n'
                    '৪. আবেদন জমা দিলে ৫ কিমি এলাকার ভেরিফাইড প্রোভাইডারদের কাছে পুশ নোটিফিকেশন অ্যালার্ট যাবে।\n'
                    '৫. Author এর পলিসি অনুযায়ী প্রতিটি আবেদনের কার্যকারিতা ৭ দিন বলবৎ থাকবে।',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('🙋', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('আবেদন করুন (Seeker Request)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 3),
                        Text('কাছাকাছি ভেরিফায়েড প্রোভাইডারদের কাছে সরাসরি ইনস্ট্যান্ট অ্যালার্ট পৌঁছে যাবে।', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text('ক্যাটাগরি বেছে নিন *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),

            // Category Chips Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return ChoiceChip(
                  avatar: Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : primaryColor),
                  label: Text('${cat['name']} (ফি ৳${cat['fee']})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF1E293B))),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat['name'] as String);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'কিসের সেবা প্রয়োজন? (সংক্ষেপে লিখুন) *',
                hintText: 'যেমন: ১.৫ টন জেনারেল স্প্লিট এসি গ্যাস চার্জ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.handyman_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Location
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'আপনার এলাকা বা লোকেশন *',
                hintText: 'মিরপুর ১০, ঢাকা',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Budget
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'প্রস্তাবিত বাজেট (টাকা)',
                hintText: '১৫০০',
                prefixText: '৳ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Additional details
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'বিস্তারিত বিবরণ (কখন প্রয়োজন, কাজের ধরন ইত্যাদি)',
                hintText: 'আগামীকাল সকাল ১০টার মধ্যে আসা সম্ভব হলে ভালো হয়...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('আবেদন সম্প্রচার করুন (Broadcast Request)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
