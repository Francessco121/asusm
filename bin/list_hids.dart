import 'package:asusm/hidapi.dart';
import 'package:collection/collection.dart';

void main(List<String> args) {
  final hid = HidApi(findHidApiLibrary());

  var err = hid.init();
  hid.assertError(err, 'init');

  try {
    final devices = hid.enumerateExt(0, 0);
    final groupedDevices = groupBy(devices, (d) => d.productId);
    
    for (final group in groupedDevices.values) {
      final ref = group.first;
      final id = '${ref.vendorId.toRadixString(16)}:${ref.productId.toRadixString(16)}';
      print('[$id] [${ref.manufacturer}] ${ref.product} (bus type: ${ref.busType}):');

      for (final device in group) {
        final usage = device.usage.toRadixString(16);
        final usagePage = device.usagePage.toRadixString(16);
        print('  - ${device.path}: interface: ${device.interface}, usage page: $usagePage, usage: $usage');
      }
    }
  } finally {
    hid.exit();
  }
}
