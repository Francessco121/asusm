import 'mouse.dart';

abstract class DpiLevels implements AsusMouse {
  int get minDpi;
  int get maxDpi;
  int get dpiIncrement;
  int get numDpiLevels;

  void setDpiForLevel(int dpi, int level);
  List<int> getDpiLevels();
}
