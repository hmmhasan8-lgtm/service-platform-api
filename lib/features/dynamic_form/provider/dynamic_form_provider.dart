import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/dynamic_field_model.dart';

class DynamicFormState {
  final Map<String, dynamic> formValues;
  final Map<String, String> fieldErrors;
  final bool isSubmitting;
  final bool isSuccess;
  final String? serverErrorMessage;

  const DynamicFormState({
    this.formValues = const {},
    this.fieldErrors = const {},
    this.isSubmitting = false,
    this.isSuccess = false,
    this.serverErrorMessage,
  });

  DynamicFormState copyWith({
    Map<String, dynamic>? formValues,
    Map<String, String>? fieldErrors,
    bool? isSubmitting,
    bool? isSuccess,
    String? serverErrorMessage,
  }) {
    return DynamicFormState(
      formValues: formValues ?? this.formValues,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      serverErrorMessage: serverErrorMessage,
    );
  }
}

class DynamicFormNotifier extends StateNotifier<DynamicFormState> {
  DynamicFormNotifier() : super(const DynamicFormState());

  void setFieldValue(String fieldKey, dynamic value) {
    final updatedValues = Map<String, dynamic>.from(state.formValues);
    updatedValues[fieldKey] = value;

    final updatedErrors = Map<String, String>.from(state.fieldErrors);
    updatedErrors.remove(fieldKey);

    state = state.copyWith(
      formValues: updatedValues,
      fieldErrors: updatedErrors,
      serverErrorMessage: null,
    );
  }

  void resetForm() {
    state = const DynamicFormState();
  }

  bool validateForm(List<DynamicFieldModel> fields, String langCode) {
    final errors = <String, String>{};

    for (final field in fields) {
      final value = state.formValues[field.fieldKey];
      final label = field.getLocalizedLabel(langCode);

      // 1. Required Validation
      if (field.isRequired) {
        if (value == null || (value is String && value.trim().isEmpty)) {
          errors[field.fieldKey] = langCode == 'bn'
              ? '$label পূরণ করা বাধ্যতামূলক'
              : '$label is required';
          continue;
        }
      }

      // If empty and not required, skip further checks
      if (value == null || (value is String && value.trim().isEmpty)) {
        continue;
      }

      // 2. Numeric / Currency Min-Max Validation
      if (field.fieldType == 'currency' || field.fieldType == 'number') {
        final numVal = num.tryParse(value.toString());
        if (numVal == null) {
          errors[field.fieldKey] = langCode == 'bn'
              ? 'সঠিক সংখ্যা প্রদান করুন'
              : 'Must be a valid number';
        } else {
          if (field.minValue != null && numVal < field.minValue!) {
            errors[field.fieldKey] = langCode == 'bn'
                ? 'সর্বনিম্ন পরিমাণ ${field.minValue}'
                : 'Minimum value is ${field.minValue}';
          }
          if (field.maxValue != null && numVal > field.maxValue!) {
            errors[field.fieldKey] = langCode == 'bn'
                ? 'সর্বোচ্চ পরিমাণ ${field.maxValue}'
                : 'Maximum value is ${field.maxValue}';
          }
        }
      }

      // 3. Regex Pattern Validation
      if (field.validationRegex != null && field.validationRegex!.isNotEmpty) {
        final regExp = RegExp(field.validationRegex!);
        if (!regExp.hasMatch(value.toString())) {
          errors[field.fieldKey] = langCode == 'bn'
              ? 'ফরম্যাটটি সঠিক নয়'
              : 'Invalid format';
        }
      }
    }

    state = state.copyWith(fieldErrors: errors);
    return errors.isEmpty;
  }

  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void setServerError(String message) {
    state = state.copyWith(isSubmitting: false, serverErrorMessage: message);
  }

  void setSuccess() {
    state = state.copyWith(isSubmitting: false, isSuccess: true);
  }
}

final dynamicFormProvider =
    StateNotifierProvider<DynamicFormNotifier, DynamicFormState>(
  (ref) => DynamicFormNotifier(),
);
