import 'package:cloud_firestore/cloud_firestore.dart';

class HeartRateSample {
  const HeartRateSample({
    required this.id,
    required this.bpm,
    required this.timestamp,
  });

  final String id;
  final int bpm;
  final DateTime timestamp;

  factory HeartRateSample.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawDate = data['timestamp'];

    return HeartRateSample(
      id: doc.id,
      bpm: (data['bpm'] as num?)?.toInt() ?? 0,
      timestamp: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
    );
  }

  factory HeartRateSample.fromJson(Map<String, dynamic> json) {
    return HeartRateSample(
      id: json['id']?.toString() ?? '',
      bpm: (json['bpm'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
