class MoodleSubmissionModel {
  final int id;
  final int userid;
  final String status;
  final String gradingstatus;

  MoodleSubmissionModel({
    required this.id,
    required this.userid,
    required this.status,
    required this.gradingstatus,
  });

  factory MoodleSubmissionModel.fromJson(Map<String, dynamic> json) {
    // Safely handle ID which can sometimes be string or int
    final dynamic idVal = json['id'];
    int parsedId;
    if (idVal is int) {
      parsedId = idVal;
    } else if (idVal is String) {
      parsedId = int.tryParse(idVal) ?? 0;
    } else {
      parsedId = 0;
    }

    return MoodleSubmissionModel(
      id: parsedId,
      userid: json['userid'] as int? ?? 0,
      status: json['status'] as String? ?? 'unknown',
      gradingstatus: json['gradingstatus'] as String? ?? 'unknown',
    );
  }
}

