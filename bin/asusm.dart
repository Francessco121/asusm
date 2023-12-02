import 'package:args/command_runner.dart';
import 'package:asusm/asusm.dart';
import 'package:asusm/hidapi.dart';

Future<int> main(List<String> args) async {
  final hid = HidApi(findHidApiLibrary());

  final initErr = hid.init();
  hid.assertError(initErr, 'init');

  try {
    final runner = CommandRunner<int>('asusm', 'Manage settings for ASUS mice.')
      ..addCommand(GetCommand(hid))
      ..addCommand(SetCommand(hid));
    
    return await runner.run(args) ?? 0;
  } finally {
    hid.exit();
  }
}

class GetCommand extends Command<int> {
  @override
  final String name = 'get';

  @override
  final String description = 'Get current mouse settings.';

  final HidApi _hid;

  GetCommand(this._hid) {
    argParser
      .addFlag('dpi', abbr: 'd', defaultsTo: false, negatable: false, help: 'Display current DPI settings.');
  }

  @override
  int run() {
    final showDpi = argResults!['dpi'] as bool;

    final (AsusMouse? mouse, Device? device) = _findMouse(_hid);
    if (mouse == null || device == null) {
      print('Failed to find compatible mouse.');
      return 1;
    }

    print(device.product);
    print('-' * device.product.length);

    mouse.openDevice(_hid, device.path);

    try {
      if (showDpi) {
        _getDpi(mouse);
      }
    } finally {
      mouse.closeDevice();
    }

    return 0;
  }

  void _getDpi(AsusMouse mouse) {
    print('DPI (current profile):');
    if (mouse is! DpiLevels) {
      print('  DPI information not available.');
      return;
    }

    print('  Range: ${mouse.minDpi}-${mouse.maxDpi} (inc: ${mouse.dpiIncrement})');

    print('  DPI levels:');
    final dpis = mouse.getDpiLevels();
    for (final (i, dpi) in dpis.indexed) {
      print('    ${i + 1}: $dpi');
    }
  }
}

class SetCommand extends Command<int> {
  @override
  final String name = 'set';

  @override
  final String description = 'Set new mouse settings.';

  final HidApi _hid;

  SetCommand(this._hid) {
    argParser
      .addMultiOption('dpi', abbr: 'd', help: 'Set DPI for a DPI level. In the format: level=dpi,...');
  }

  @override
  int run() {
    final dpiSets = argResults!['dpi'] as List<String>?;

    final (AsusMouse? mouse, Device? device) = _findMouse(_hid);
    if (mouse == null || device == null) {
      print('Failed to find compatible mouse.');
      return 1;
    }

    print(device.product);
    print('-' * device.product.length);

    mouse.openDevice(_hid, device.path);

    try {
      if (dpiSets != null) {
        _setDpi(mouse, dpiSets);
      }

      mouse.flushSettings();
    } finally {
      mouse.closeDevice();
    }

    return 0;
  }

  void _setDpi(AsusMouse mouse, List<String> dpiSets) {
    if (mouse is! DpiLevels) {
      print('DPI settings not available.');
      return;
    }

    for (final str in dpiSets) {
      final kv = str.split('=');
      if (kv.length != 2) {
        print('Invalid DPI set: $str');
        continue;
      }

      final level = int.tryParse(kv[0]);
      final dpi = int.tryParse(kv[1]);
      if (level == null || dpi == null) {
        print('Invalid DPI set: $str');
        continue;
      }

      mouse.setDpiForLevel(dpi, level - 1);

      print('Set DPI level $level to $dpi DPI');
    }
  }
}

(AsusMouse?, Device?) _findMouse(HidApi hid) {
  final devices = hid.enumerateExt(0, 0);

  for (final device in devices) {
    for (final mouse in miceList) {
      if (device.vendorId == mouse.vendorId &&
          device.productId == mouse.productId &&
          device.usage == mouse.usage &&
          device.usagePage == mouse.usagePage) {
        return (mouse.ctor(), device);
      }
    }
  }

  return (null, null);
}
