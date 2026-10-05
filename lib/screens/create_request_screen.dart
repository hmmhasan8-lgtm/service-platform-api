import 'package:flutter/material.dart';

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
            'আপনার রিকোয়েস্ট কাছাকাছি ৫ কিমি দূরত্বের ভেরিফায়েড প্রোভাইডারদের কাছে পাঠানো হয়েছে। যিনি আগে গ্রহণ করবেন, শুধু তার সাথেই সংযোগ স্থাপিত হবে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
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
            const SizedBox(height: 20),

            // Step 1: Category selection
            const Text('১. সেবার ক্যাটাগরি নির্বাচন করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return ChoiceChip(
                  label: Text('${cat['name']} (৳${cat['fee']})'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFD1FAE5),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF065F46) : const Color(0xFF334155),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  avatar: Icon(cat['icon'] as IconData, size: 16, color: isSelected ? const Color(0xFF065F46) : const Color(0xFF64748B)),
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedCategory = cat['name'] as String);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Step 2: Form fields
            const Text('২. কাজের বিবরণ ও আপনার লোকেশন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'কাজের শিরোনাম *',
                hintText: 'যেমন: ১.৫ টন স্প্লিট এসি গ্যাস রিফিল ও সার্ভিসিং',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.handyman_outlined),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'আপনার এলাকা / লোকেশন *',
                      hintText: 'মিরপুর ১০, ঢাকা',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'আনুমানিক বাজেট',
                      hintText: '১৫০০',
                      prefixText: '৳ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'বিস্তারিত বিবরণ (ঐচ্ছিক)',
                hintText: 'সমস্যা বা প্রয়োজনীয়তার বিস্তারিত লিখুন...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: const Icon(Icons.send_rounded),
              label: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('কাছাকাছি প্রোভাইডারদের খুঁজুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    );
  }
}
