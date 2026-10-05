import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dynamic_field_model.dart';
import '../../provider/dynamic_form_provider.dart';

class DynamicFormWidget extends ConsumerWidget {
  final List<DynamicFieldModel> fields;
  final String languageCode;
  final String currencySymbol;
  final Future<void> Function(Map<String, dynamic> formValues) onFormSubmitted;

  const DynamicFormWidget({
    Key? key,
    required this.fields,
    this.languageCode = 'bn',
    this.currencySymbol = '৳',
    required this.onFormSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(dynamicFormProvider);
    final notifier = ref.read(dynamicFormProvider.notifier);

    // Group fields by section if defined
    final generalFields = fields.where((f) => f.section == 'general').toList();
    final specFields = fields.where((f) => f.section == 'specifications').toList();
    final otherFields = fields.where((f) => f.section != 'general' && f.section != 'specifications').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (formState.serverErrorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formState.serverErrorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 1. General Fields
        ...generalFields.map((field) => _buildFieldItem(context, field, formState, notifier)),

        // 2. Specifications Fields
        if (specFields.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            languageCode == 'bn' ? 'স্পেসিফিকেশন ও বিবরণ' : 'Specifications',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 8),
          ...specFields.map((field) => _buildFieldItem(context, field, formState, notifier)),
        ],

        // 3. Other / Contact Fields
        if (otherFields.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            languageCode == 'bn' ? 'অন্যান্য তথ্য' : 'Additional Information',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 8),
          ...otherFields.map((field) => _buildFieldItem(context, field, formState, notifier)),
        ],

        const SizedBox(height: 24),

        // Submit Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          onPressed: formState.isSubmitting
              ? null
              : () async {
                  if (notifier.validateForm(fields, languageCode)) {
                    notifier.setSubmitting(true);
                    try {
                      await onFormSubmitted(formState.formValues);
                      notifier.setSuccess();
                    } catch (e) {
                      notifier.setServerError(e.toString());
                    }
                  }
                },
          child: formState.isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  languageCode == 'bn' ? 'পোস্ট সাবমিট করুন' : 'Submit Publication',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  Widget _buildFieldItem(
    BuildContext context,
    DynamicFieldModel field,
    DynamicFormState formState,
    DynamicFormNotifier notifier,
  ) {
    final label = field.getLocalizedLabel(languageCode);
    final placeholder = field.getLocalizedPlaceholder(languageCode);
    final errorText = formState.fieldErrors[field.fieldKey];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Label + Required Astrix + Private Lock Badge
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (field.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              const Spacer(),

              // CRITICAL: PRIVATE LOCK BADGE
              if (field.isPrivate)
                Tooltip(
                  message: languageCode == 'bn'
                      ? 'এটি একটি গোপনীয় তথ্য। আনলক ফি পরিশোধের পর বায়ার এটি দেখতে পাবে।'
                      : 'Private field: Revealed only after contact unlock payment.',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFB45309)),
                        const SizedBox(width: 4),
                        Text(
                          languageCode == 'bn' ? 'লক থাকবে' : 'Private (Locked)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Dynamic Input Widget Resolution
          _buildInputByType(context, field, placeholder, errorText, formState, notifier),
        ],
      ),
    );
  }

  Widget _buildInputByType(
    BuildContext context,
    DynamicFieldModel field,
    String placeholder,
    String? errorText,
    DynamicFormState formState,
    DynamicFormNotifier notifier,
  ) {
    switch (field.fieldType) {
      // 1. Currency Formatter Field
      case 'currency':
        return TextFormField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          decoration: InputDecoration(
            prefixIcon: Container(
              alignment: Alignment.center,
              width: 42,
              child: Text(
                currencySymbol,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ),
            hintText: placeholder.isNotEmpty ? placeholder : (languageCode == 'bn' ? 'টাকার পরিমাণ' : 'Amount'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val.trim());
            notifier.setFieldValue(field.fieldKey, parsed ?? 0.0);
          },
        );

      // 2. Select / Dropdown Field
      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          hint: Text(placeholder.isNotEmpty ? placeholder : (languageCode == 'bn' ? 'নির্বাচন করুন' : 'Select option')),
          value: formState.formValues[field.fieldKey]?.toString(),
          items: field.options.map<DropdownMenuItem<String>>((opt) {
            String label = opt['value'].toString();
            if (opt is Map && opt.containsKey('label')) {
              if (opt['label'] is Map) {
                label = opt['label'][languageCode] ?? opt['label']['en'] ?? opt['value'];
              } else {
                label = opt['label'].toString();
              }
            }
            return DropdownMenuItem<String>(
              value: opt['value'].toString(),
              child: Text(label),
            );
          }).toList(),
          onChanged: (selectedVal) {
            notifier.setFieldValue(field.fieldKey, selectedVal);
          },
        );

      // 3. Geo Point / Map Picker Field
      case 'geo_point':
        final currentGeo = formState.formValues[field.fieldKey];
        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(color: errorText != null ? Colors.red : Colors.grey.shade400),
          ),
          icon: Icon(Icons.location_on_rounded, color: currentGeo != null ? Colors.green : Colors.blueGrey),
          label: Text(
            currentGeo != null
                ? (currentGeo is Map && currentGeo.containsKey('address')
                    ? currentGeo['address'].toString()
                    : (languageCode == 'bn' ? 'অবস্থান চিহ্নিত হয়েছে' : 'Location Pin Selected'))
                : (languageCode == 'bn' ? 'ম্যাপ থেকে লোকেশন সিলেক্ট করুন' : 'Select Location on Map'),
            style: TextStyle(
              color: currentGeo != null ? Colors.black87 : Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          onPressed: () {
            // Interactive Map Picker trigger
            notifier.setFieldValue(field.fieldKey, {
              'latitude': 23.8103,
              'longitude': 90.4125,
              'address': languageCode == 'bn' ? 'মিরপুর ১০, ঢাকা' : 'Mirpur 10, Dhaka',
            });
          },
        );

      // 4. Default Text Field
      case 'text':
      default:
        return TextFormField(
          decoration: InputDecoration(
            hintText: placeholder.isNotEmpty ? placeholder : (languageCode == 'bn' ? 'এখানে লিখুন' : 'Enter value'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onChanged: (val) {
            notifier.setFieldValue(field.fieldKey, val.trim());
          },
        );
    }
  }
}
