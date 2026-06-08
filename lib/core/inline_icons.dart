import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/painting.dart';

// Tiny transparent 1x1 PNG used as placeholder for icons so the app can run
// without external asset files. Replace the base64 strings with real icon
// images when available.
const String _kTransparentPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';

Uint8List _decode(String b64) => base64Decode(b64);

class InlineIcons {
  // Provide MemoryImage instances (ImageProvider) so widgets can use them
  static final MemoryImage home = MemoryImage(_decode(_kTransparentPngBase64));
  static final MemoryImage chat = MemoryImage(_decode(_kTransparentPngBase64));
  static final MemoryImage bell = MemoryImage(_decode(_kTransparentPngBase64));
  static final MemoryImage user = MemoryImage(_decode(_kTransparentPngBase64));
  static final MemoryImage menu = MemoryImage(_decode(_kTransparentPngBase64));
  static final MemoryImage mail = MemoryImage(_decode(_kTransparentPngBase64));
  static final MemoryImage handshake = MemoryImage(_decode(_kTransparentPngBase64));
}
