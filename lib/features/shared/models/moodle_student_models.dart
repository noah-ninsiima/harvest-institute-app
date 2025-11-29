class MoodleAssignmentModel {
  final int id;
  final String name;
  final int dueDate;
  final String intro;

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

  MoodleGradeModel({
    required this.itemName,
    required this.gradeFormatted,
    this.feedback,
  });

  factory MoodleGradeModel.fromJson(Map<String, dynamic> json) {
    return MoodleGradeModel(
      itemName: json['itemname'] as String? ?? 'Grade Item',
      gradeFormatted: json['gradeformatted'] as String? ?? '-',
      feedback: json['feedback'] as String?,
    );
  }
}

