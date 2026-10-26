import 'dart:io';

import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;

/// On iOS and macOS, Apple's URLSession, so the app's encryption stays within
/// the operating system (see ITSAppUsesNonExemptEncryption in ios/Runner/Info.plist).
http.Client platformHttpClient() =>
    Platform.isIOS || Platform.isMacOS ? CupertinoClient.defaultSessionConfiguration() : http.Client();
