import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../hidapi.dart';

abstract class AsusMouse {
  @protected
  Pointer<hid_device> devicePtr = nullptr; 
  @protected
  late final HidApi hid;
  @protected
  final int packetSize;

  AsusMouse({required this.packetSize});

  /// Opens this mouse's HID.
  void openDevice(HidApi hid, String path) {
    this.hid = hid;
    devicePtr = hid.openPathEx(path);
    if (devicePtr == nullptr) {
      hid.raiseLastError('open_path');
    }
  }

  /// Closes this mouse's HID.
  void closeDevice() {
    if (devicePtr != nullptr) {
      hid.close(devicePtr);
      devicePtr = nullptr;
    }
  }

  /// Flushes the mouse's configuration to persistent storage.
  void flushSettings();

  /// Sends a request packet to the mouse HID.
  /// 
  /// Throws a [AsusMouseRequestException] if the mouse returns an error response.
  @protected
  Uint8List sendRequest(Uint8List packet) {
    if (packet.lengthInBytes > packetSize) {
      throw ArgumentError.value(packet, 'packet', 'Packet cannot be larger than $packetSize for this mouse!');
    }

    final request = calloc<UnsignedChar>(packetSize + 1);
    final response = calloc<UnsignedChar>(packetSize + 1);

    request[0] = 0x00; // report type
    for (int i = 0; i < packet.lengthInBytes; i++) {
      request[i + 1] = packet[i];
    }

    try {
      final written = hid.write(devicePtr, request, packetSize + 1);
      hid.assertError(written, 'write');

      if (written != packetSize + 1) {
        throw UnimplementedError('HID write wrote different number of bytes than packet size.');
      }

      final read = hid.read(devicePtr, response, packetSize + 1);
      hid.assertError(read, 'read');

      final responseData = Uint8List(packetSize);
      for (int i = 0; i < read && i < packetSize; i++) {
        responseData[i] = response[i];
      }

      if (_isResponseError(responseData)) {
        throw AsusMouseRequestException('Response indicated an error.', responseData);
      }

      return responseData;
    } finally {
      calloc.free(request);
      calloc.free(response);
    }
  }

  bool _isResponseError(Uint8List response) {
    return response[0] == 0xFF && response[1] == 0xAA;
  }
}

class AsusMouseRequestException implements Exception {
  final String message;
  final Uint8List response;

  AsusMouseRequestException(this.message, this.response);

  @override
  String toString() => 'AsusMouseRequestException: $message';
}

typedef AsusMouseConstructor = AsusMouse Function();

/// Used to identify an ASUS mouse.
class AsusMouseDeviceDescriptor {
  /// Mouse name.
  final String name;

  /// ASUS vendor ID.
  final int vendorId;
  /// Mouse product ID.
  final int productId;
  /// Usage ID for the HID of this mouse that communicates mouse configuration.
  final int usage;
  /// Usage page ID for the HID of this mouse that communicates mouse configuration.
  final int usagePage;

  /// Constructor for an interface for this mouse.
  final AsusMouseConstructor ctor;

  const AsusMouseDeviceDescriptor({
    required this.name,
    required this.vendorId,
    required this.productId,
    required this.usage,
    required this.usagePage,
    required this.ctor,
  });
}
