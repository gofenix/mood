import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime) {
  return DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);
}

String formatDate(DateTime dateTime) {
  return DateFormat("yyyy-MM-dd").format(dateTime);
}

String formatHourMinute(DateTime dateTime) {
  return DateFormat("HH:mm").format(dateTime);
}

String getKey(DateTime dateTime) {
  return DateFormat("yyyy-MM-dd").format(dateTime);
}
