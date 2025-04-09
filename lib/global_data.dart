import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

Future<Map<String, int>> loadLSOATheftCounts() async {
  final csvString = await rootBundle.loadString(
    'assets/geojson/PhoneTheft_Total_Only.csv',
  );
  final rows = const CsvToListConverter().convert(csvString, eol: '\n');

  final header = rows.first;
  final lsoaIndex = header.indexOf('LSOA Code');
  final theftCountIndex = header.length - 1;

  if (lsoaIndex == -1 || theftCountIndex == -1) return {};

  final counts = <String, int>{};
  for (var row in rows.skip(1)) {
    final code = row[lsoaIndex].toString();
    final thefts = int.tryParse(row[theftCountIndex].toString()) ?? 0;
    counts[code] = thefts;
  }

  return counts;
}

String? globalAddress;