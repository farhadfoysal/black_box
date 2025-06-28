class ClassRoutine {
  final int? id;
  final String? uniqueId;
  final String? scheduleId;
  final String? day;
  final String? startTime;
  final String? endTime;
  final String? major;
  final String courseCode;
  final String teacher;
  final String? room;
  final String? section;
  final String? shift;

  ClassRoutine({
    this.id,
    this.uniqueId,
    this.scheduleId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.major,
    required this.courseCode,
    required this.teacher,
    required this.room,
    required this.section,
    required this.shift,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'schedule_id': scheduleId,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
      'major': major,
      'course_code': courseCode,
      'teacher': teacher,
      'room': room,
      'section': section,
      'shift': shift,
    };
  }

  factory ClassRoutine.fromMap(Map<String, dynamic> map) {
    return ClassRoutine(
      id: map['id'],
      uniqueId: map['unique_id'],
      scheduleId: map['schedule_id'],
      day: map['day'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      major: map['major'],
      courseCode: map['course_code'],
      teacher: map['teacher'],
      room: map['room'],
      section: map['section'],
      shift: map['shift'],
    );
  }
}
