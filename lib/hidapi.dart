import 'dart:ffi';
import 'dart:io';

export 'src/hidapi_bindings.dart';
export 'src/hidapi_extensions.dart';

DynamicLibrary findHidApiLibrary() {
  if (Platform.isWindows) {
    return DynamicLibrary.open(
        '${Directory.current.path}/hidapi.dll');
  }
  if (Platform.isMacOS) {
    return DynamicLibrary.open(
        '${Directory.current.path}/hidapi.dylib');
  } else if (Platform.isLinux) {
    return DynamicLibrary.open(
        '${Directory.current.path}/hidapi.so');
  }
  throw Exception('hidapi dynamic library not found');
}
