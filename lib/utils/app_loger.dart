import 'package:logger/logger.dart';

// Configura el logger con niveles, color y timestamp
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    colors: true,
    printEmojis: true,
    dateTimeFormat:(time) => time.toLocal().toString() ,
  ),
);
