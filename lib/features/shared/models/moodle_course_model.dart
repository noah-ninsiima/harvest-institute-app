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
    return MoodleCourseModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullname: json['fullname']?.toString() ?? '',
      shortname: json['shortname']?.toString() ?? '',
      progress: double.tryParse(json['progress']?.toString() ?? ''),
      category: json['category']?.toString(),
      startDate: int.tryParse(json['startdate']?.toString() ?? ''),
      endDate: int.tryParse(json['enddate']?.toString() ?? ''),
      imageUrl: json['courseimage'] is String ? json['courseimage'] as String : null,
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
