class MoodleGradeModel {
  final String itemName;
  final String gradeFormatted;
  final String? feedback;
  final int? gradeDateGraded;

  MoodleGradeModel({
    required this.itemName,
    required this.gradeFormatted,
    this.feedback,
    this.gradeDateGraded,
  });

  factory MoodleGradeModel.fromJson(Map<String, dynamic> json) {
    return MoodleGradeModel(
      itemName: json['itemname'] as String? ?? 'Grade Item',
      gradeFormatted: json['gradeformatted'] as String? ?? '-',
      feedback: json['feedback'] as String?,
      gradeDateGraded: json['gradedategraded'] as int?,
    );
  }
}

class MoodleUserGrade {
  final int courseId;
  final List<MoodleGradeModel> gradeItems;

  MoodleUserGrade({
    required this.courseId,
    required this.gradeItems,
  });

  factory MoodleUserGrade.fromJson(Map<String, dynamic> json) {
    return MoodleUserGrade(
      courseId: json['courseid'] as int? ?? 0,
      gradeItems: (json['gradeitems'] as List<dynamic>?)
              ?.map((e) => MoodleGradeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

