import '../models/class_info.dart';

class DashboardRepository {
  Future<ClassInfo> getNextClass() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    return ClassInfo(
      date: 'Thu 16 March',
      time: '11:00AM',
      title: 'Foundation of Nursing and Midwifery',
    );
  }
}