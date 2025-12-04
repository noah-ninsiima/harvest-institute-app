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
    return MoodleSubmissionModel(
      id: json['id'] as int,
      userid: json['userid'] as int,
      status: json['status'] as String? ?? 'unknown',
      gradingstatus: json['gradingstatus'] as String? ?? 'unknown',
    );
  }
}

