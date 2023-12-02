import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'hidapi_bindings.dart';

class HidApiException implements Exception {
  final String message;

  HidApiException(this.message);

  @override
  String toString() => 'HidApiException: $message';
}

class Device {
  /// Device Vendor ID
  final int vendorId;
  /// Device Product ID
  final int productId;
  /// Manufacturer String
  final String manufacturer;
  /// Product string
  final String product;
  /// Platform-specific device path
  final String path;
  /// The USB interface which this logical device
  /// represents.
  ///
  /// Valid only if the device is a USB HID device.
  /// Set to -1 in all other cases.
  final int interface;
  /// Underlying bus type
  final int busType;
  /// Usage for this Device/Interface
  /// (Windows/Mac/hidraw only)
  final int usage;
  /// Usage Page for this Device/Interface
  /// (Windows/Mac/hidraw only)
  final int usagePage;

  Device({
    required this.vendorId,
    required this.productId,
    required this.manufacturer,
    required this.product,
    required this.path,
    required this.interface,
    required this.busType,
    required this.usage,
    required this.usagePage,
  });
}

extension HidApiExtensions on HidApi {
  /// See [HidApi.enumerate].
  List<Device> enumerateExt(int vendorId, int productId) {
    final enumerator = enumerate(0, 0);
    if (enumerator == nullptr) {
      raiseLastError('enumerate');
    }

    final devices = <Device>[];

    try {
      var devicePtr = enumerator;
      do {
        final info = devicePtr.ref;

        devices.add(Device(
          vendorId: info.vendor_id,
          productId: info.product_id,
          manufacturer: info.manufacturer_string.cast<Utf16>().toDartString(),
          product: info.product_string.cast<Utf16>().toDartString(),
          path: info.path.cast<Utf8>().toDartString(),
          interface: info.interface_number,
          busType: info.bus_type,
          usage: info.usage,
          usagePage: info.usage_page,
        ));

        devicePtr = devicePtr.ref.next;
      } while (devicePtr != nullptr);
    } finally {
      free_enumeration(enumerator);
    }

    return devices;
  }

  /// See [HidApi.open_path].
  Pointer<hid_device> openPathEx(String path) {
    final pathBytes = utf8.encode(path);
    final pathPtr = calloc<Char>(pathBytes.lengthInBytes + 1);
    for (int i = 0; i < pathBytes.lengthInBytes; i++) {
      pathPtr[i] = pathBytes[i];
    }
    pathPtr[pathBytes.lengthInBytes] = 0;

    try {
      return open_path(pathPtr);
    } finally {
      calloc.free(pathPtr);
    }
  }

  void assertError(int error, String function, [Pointer<hid_device_>? device]) {
    if (error < 0) {
      raiseLastError(function, device);
    }
  }

  Never raiseLastError(String function, [Pointer<hid_device_>? device]) {
    final strPtr = error(device ?? nullptr);
    final str = strPtr.cast<Utf16>().toDartString();

    throw HidApiException('hid $function error: $str');
  }
}
