import 'package:image_picker/image_picker.dart';
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

List<String> getImagePaths(List<XFile>? imageFiles) {
  List<String> paths = [];
  if (imageFiles == null) {
    return paths;
  }

  for (var i in imageFiles) {
    paths.add(i.path);
  }
  return paths;
}
