import 'dart:js_interop';

@JS('cmSplashPhase')
external JSNumber? _cmSplashPhase();

/// Where the page's loading dots are in their pulse, from 0 to 1, so the
/// splash's own dots carry on from there instead of restarting.
double loaderDotsPhase() {
  try {
    return _cmSplashPhase()?.toDartDouble.clamp(0.0, 1.0) ?? 0;
  } catch (_) {
    // A page without the loader (a custom index.html): start from the top.
    return 0;
  }
}
