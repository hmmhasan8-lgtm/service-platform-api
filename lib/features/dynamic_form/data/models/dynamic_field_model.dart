class DynamicFieldModel {
  final String id;
  final String fieldKey;
  final String fieldType; // 'text', 'currency', 'number', 'select', 'multiselect', 'geo_point', 'phone'
  final Map<String, dynamic> labels;
  final Map<String, dynamic> placeholders;
  final Map<String, dynamic> helpTexts;
  final bool isRequired;
  final String? validationRegex;
  final double? minValue;
  final double? maxValue;
  final List<dynamic> options;
  final bool isPrivate; // true = Locked until unlock fee paid (displays 🔒 badge)
  final bool isSearchable;
  final bool isHighlighted;
  final String section;
  final List<dynamic> targetCountries;

  DynamicFieldModel({
    required this.id,
    required this.fieldKey,
    required this.fieldType,
    required this.labels,
    required this.placeholders,
    this.helpTexts = const {},
    required this.isRequired,
    this.validationRegex,
    this.minValue,
    this.maxValue,
    this.options = const [],
    required this.isPrivate,
    this.isSearchable = true,
    this.isHighlighted = false,
    this.section = 'general',
    this.targetCountries = const ['*'],
  });

  factory DynamicFieldModel.fromJson(Map<String, dynamic> json) {
    return DynamicFieldModel(
      id: json['id']?.toString() ?? '',
      fieldKey: json['field_key']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? 'text',
      labels: Map<String, dynamic>.from(json['labels'] ?? {}),
      placeholders: Map<String, dynamic>.from(json['placeholders'] ?? {}),
      helpTexts: Map<String, dynamic>.from(json['help_texts'] ?? {}),
      isRequired: json['is_required'] == true,
      validationRegex: json['validation_regex']?.toString(),
      minValue: json['min_value'] != null ? (json['min_value'] as num).toDouble() : null,
      maxValue: json['max_value'] != null ? (json['max_value'] as num).toDouble() : null,
      options: json['options'] is List ? List<dynamic>.from(json['options']) : [],
      isPrivate: json['is_private'] == true,
      isSearchable: json['is_searchable'] != false,
      isHighlighted: json['is_highlighted'] == true,
      section: json['section']?.toString() ?? 'general',
      targetCountries: json['target_countries'] is List ? List<dynamic>.from(json['target_countries']) : const ['*'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_key': fieldKey,
      'field_type': fieldType,
      'labels': labels,
      'placeholders': placeholders,
      'help_texts': helpTexts,
      'is_required': isRequired,
      'validation_regex': validationRegex,
      'min_value': minValue,
      'max_value': maxValue,
      'options': options,
      'is_private': isPrivate,
      'is_searchable': isSearchable,
      'is_highlighted': isHighlighted,
      'section': section,
      'target_countries': targetCountries,
    };
  }

  String getLocalizedLabel(String langCode) {
    if (labels.containsKey(langCode) && labels[langCode].toString().isNotEmpty) {
      return labels[langCode].toString();
    }
    if (labels.containsKey('en') && labels['en'].toString().isNotEmpty) {
      return labels['en'].toString();
    }
    return fieldKey;
  }

  String getLocalizedPlaceholder(String langCode) {
    if (placeholders.containsKey(langCode) && placeholders[langCode].toString().isNotEmpty) {
      return placeholders[langCode].toString();
    }
    if (placeholders.containsKey('en') && placeholders['en'].toString().isNotEmpty) {
      return placeholders['en'].toString();
    }
    return '';
  }
}
