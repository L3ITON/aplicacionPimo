import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  static String formatOnlyTime(DateTime dateTime) {
    return DateFormat('HH:mm a').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}