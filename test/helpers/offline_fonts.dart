import 'dart:io';

// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as gf;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _fontsDir = 'test/fixtures/fonts/be_vietnam_pro';

/// google_fonts requests each file by its sha256; map it to the readable name
/// the file is stored under. Add a row when the app starts using a new weight.
const _fileByHash = {
  'e9429918b033a0c12e2dd4091a7d7d11bed161efa7ae17c1c03c1348d31fcaaa': 'BeVietnamPro-Regular',
  'fbb96d46d021840a81fd08a7429ea2cddeed64329ae11bab0b635902f262a327': 'BeVietnamPro-Medium',
  '00d35b55610fb4c5b0db57c07244806c807dd82dffb333846f0b970f16d2f8b4': 'BeVietnamPro-SemiBold',
  'bb637e409b7022b7f6a1788cc2aae91fa93e55017cc13309620f4ae6884f6e2a': 'BeVietnamPro-Bold',
  '5e8fdddc5b06efd1bb411a40d91cf021ebaf526acad5e44c31eca97c8a4416f5': 'BeVietnamPro-ExtraBold',
  '89f136b4c9270c59ab7bb1469cb11a7459f6b767f83627ac46b1277346bec5f7': 'BeVietnamPro-ExtraBoldItalic',
  '817a4b39ed86a90c52a873b399f1c8b88954489fe9376b6685195cac99d75dea': 'BeVietnamPro-Black',
};

/// Tests can't reach the network (every HTTP call returns 400), so google_fonts
/// fails to load Be Vietnam Pro. Serve its requests from the checked-in .ttf
/// files so the real font renders in widget and golden tests.
void useOfflineGoogleFonts() {
  gf.httpClient = MockClient((request) async {
    final hash = request.url.pathSegments.last.replaceAll('.ttf', '');
    final name = _fileByHash[hash];
    final file = File('$_fontsDir/$name.ttf');
    if (name == null || !file.existsSync()) {
      return http.Response('no test font for $hash', 404);
    }
    return http.Response.bytes(file.readAsBytesSync(), 200);
  });
}
