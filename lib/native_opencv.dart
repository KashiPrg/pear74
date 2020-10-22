import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// C function signatures
// typedef _version_func = ffi.Pointer<Utf8> Function();
// typedef _process_image_func = ffi.Pointer<Utf8> Function(
// ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
// typedef _process_image_func = ffi.Void Function(
// ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

// Dart function signatures
typedef _VersionFunc = ffi.Pointer<Utf8> Function();
typedef _ProcessImageFunc = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
// typedef _ProcessImageFunc = void Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

// Getting a library that holds needed symbols
ffi.DynamicLibrary _lib = Platform.isAndroid
    ? ffi.DynamicLibrary.open('libnative_opencv.so')
    : ffi.DynamicLibrary.process();

// Looking for the functions
final _VersionFunc _version =
    _lib.lookup<ffi.NativeFunction<_VersionFunc>>('version').asFunction();
final _ProcessImageFunc _processImage = _lib
    .lookup<ffi.NativeFunction<_ProcessImageFunc>>('process_image')
    .asFunction();

String opencvVersion() {
  return Utf8.fromUtf8(_version());
}

String processImage(String inputPath, String outputPath) {
  return Utf8.fromUtf8(
      _processImage(Utf8.toUtf8(inputPath), Utf8.toUtf8(outputPath)));
}
