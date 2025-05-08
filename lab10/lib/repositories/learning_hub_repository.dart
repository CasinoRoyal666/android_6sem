import '../models/activity.dart';

class LearningHubRepository {
  Future<List<Activity>> getTodayActivities() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      Activity(
        type: ActivityType.dropIn,
        time: '09:00 AM',
        details: [
          'Student',
          'Mentor Study',
          'Space - Sport and Exercise',
          'Science',
        ],
      ),
      Activity(
        type: ActivityType.workshop,
        time: '11:00 AM',
        details: [
          'Resume Help',
          'Drop-In',
        ],
      ),
    ];
  }
}