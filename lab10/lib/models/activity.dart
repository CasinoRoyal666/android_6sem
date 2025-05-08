enum ActivityType { dropIn, workshop }

class Activity {
  final ActivityType type;
  final String time;
  final List<String> details;

  Activity({
    required this.type,
    required this.time,
    required this.details,
  });

  String get typeLabel {
    switch (type) {
      case ActivityType.dropIn:
        return 'DROP-IN';
      case ActivityType.workshop:
        return 'WORKSHOP';
    }
  }

  String get typeColor {
    switch (type) {
      case ActivityType.dropIn:
        return 'red';
      case ActivityType.workshop:
        return 'blue';
    }
  }
}