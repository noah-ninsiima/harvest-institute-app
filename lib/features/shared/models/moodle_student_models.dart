class MoodleAssignmentModel {
  final int id;
  final String name;
  final int dueDate;
  final String intro;
  // Add status field which is common in assignment responses, though not explicitly detailed in the minimal screenshot
  // The screenshots confirm `mod_assign_get_assignments` is the endpoint.

  MoodleAssignmentModel({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.intro,
  });

  factory MoodleAssignmentModel.fromJson(Map<String, dynamic> json) {
    return MoodleAssignmentModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      dueDate: json['duedate'] as int? ?? 0,
      intro: json['intro'] as String? ?? '',
    );
  }
}

class MoodleGradeModel {
  final String itemName;
  final String gradeFormatted;
  final String? feedback;
  final double? graderaw;

  MoodleGradeModel({
    required this.itemName,
    required this.gradeFormatted,
    this.feedback,
    this.graderaw,
  });

  factory MoodleGradeModel.fromJson(Map<String, dynamic> json) {
    return MoodleGradeModel(
      itemName: json['itemname'] as String? ?? 'Grade Item',
      gradeFormatted: json['gradeformatted'] as String? ?? '-',
      feedback: json['feedback'] as String?,
      graderaw: json['graderaw'] != null ? (json['graderaw'] as num).toDouble() : null,
    );
  }
}
