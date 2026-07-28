class SubjectResource {
  final int? id;
  final int subjectId;
  final String title;
  final String url;
  final String type;

  SubjectResource({
    this.id,
    required this.subjectId,
    required this.title,
    required this.url,
    this.type = 'other',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'url': url,
      'type': type,
    };
  }

  factory SubjectResource.fromMap(Map<String, dynamic> map) {
    return SubjectResource(
      id: map['id'],
      subjectId: map['subject_id'],
      title: map['title'],
      url: map['url'],
      type: map['type'] ?? 'other',
    );
  }
}