/// Barrel que exporta a factory correta via conditional import.
///
/// - Na Web: stub (UnsupportedError)
/// - Em plataformas nativas (Android/Windows): implementação real
library;

export 'webview_factory_stub.dart'
    if (dart.library.io) 'webview_factory_native.dart';
