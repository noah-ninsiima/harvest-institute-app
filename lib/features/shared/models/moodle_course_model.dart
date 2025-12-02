class MoodleCourseModel {
  final int id;
  final String fullname;
  final String shortname;
  final double? progress;
  final String? category;
  final int? startDate;
  final int? endDate;
  final String? imageUrl;

  MoodleCourseModel({
    required this.id,
    required this.fullname,
    required this.shortname,
    this.progress,
    this.category,
    this.startDate,
    this.endDate,
    this.imageUrl,
  });

  factory MoodleCourseModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse doubles
    double? parseProgress(dynamic value) {
      if (value == null) return 0.0; // Default to 0.0 as requested
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MoodleCourseModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullname: json['fullname']?.toString() ?? '',
      shortname: json['shortname']?.toString() ?? '',
      progress: parseProgress(json['progress']),
      category: json['category']?.toString(),
      startDate: int.tryParse(json['startdate']?.toString() ?? ''),
      endDate: int.tryParse(json['enddate']?.toString() ?? ''),
      // Handle courseimage safely (Moodle sometimes returns false/null/empty string)
      imageUrl: (json['courseimage'] != null && json['courseimage'] is String && (json['courseimage'] as String).isNotEmpty)
          ? json['courseimage'] as String
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'shortname': shortname,
      'progress': progress,
      'category': category,
      'startdate': startDate,
      'enddate': endDate,
      'courseimage': imageUrl,
    };
  }
}
