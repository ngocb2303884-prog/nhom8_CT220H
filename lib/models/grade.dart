class Grade {
  final int? id;
  final int subjectId;
  final String type;
  final double score;
  final double weight;
  double get weightedScore => score * weight;
  Grade({
    this.id,
    required this.subjectId,
    required this.type,
    required this.score,
    required this.weight,
  });

  //chuyen du lieu thanh Map de dua vao DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId, // phai dung chinh xac ten cot trong db_helper
      'type': type,
      'score': score,
      'weight': weight,
    };
  }

  // chuyen du lieu tu db ra thanh Grade de hien thi
  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      subjectId: map['subject_id'],
      type: map['type'],
      score: map['score'],
      weight: map['weight'],
    );
  }
}