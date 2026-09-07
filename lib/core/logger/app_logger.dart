import 'package:logger/logger.dart';

/// App-wide logger. Never use print(). Import [log] anywhere.
final Logger log = Logger(
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
);
