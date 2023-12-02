import 'dart:math';
import 'dart:typed_data';

import '../capabilities.dart';
import '../mouse.dart';

class TufGamingM4Air extends AsusMouse implements DpiLevels {
  @override
  final int minDpi = 100;
  @override
  final int maxDpi = 16000;
  @override
  final int dpiIncrement = 100;
  @override
  final int numDpiLevels = 4;

  TufGamingM4Air() : super(packetSize: 64);

  @override
  void flushSettings() {
    final packet = ByteData(2);
    packet.setUint8(0, 0x50);
    packet.setUint8(1, 0x03);

    sendRequest(packet.buffer.asUint8List());
  }

  @override
  List<int> getDpiLevels() {
    final packet = ByteData(3);
    packet.setUint8(0, 0x12);
    packet.setUint8(1, 0x04);
    packet.setUint8(2, 0x00);

    final response = sendRequest(packet.buffer.asUint8List());
    assert(response[0] == 0x12 && response[1] == 0x04 && response[2] == 0x00);

    final responseData = ByteData.sublistView(response);
    final dpiProfiles = <int>[];

    for (int i = 0; i < numDpiLevels; i++) {
      final offset = 4 + (i * 2);
      final dpiEncoded = responseData.getUint16(offset, Endian.little);
      final dpi = (dpiEncoded * dpiIncrement) + dpiIncrement;

      dpiProfiles.add(dpi);
    }

    return dpiProfiles;
  }

  @override
  void setDpiForLevel(int dpi, int level) {
    dpi = min(max(dpi, minDpi), maxDpi);

    final dpiEncoded = (dpi - dpiIncrement) ~/ dpiIncrement;

    final packet = ByteData(6);
    packet.setUint8(0, 0x51);
    packet.setUint8(1, 0x31);
    packet.setUint8(2, level);
    packet.setUint8(3, 0x00);
    packet.setUint16(4, dpiEncoded, Endian.little);

    sendRequest(packet.buffer.asUint8List());
  }
}
