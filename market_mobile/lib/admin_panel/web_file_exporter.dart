import 'dart:html' as html;
import 'package:intl/intl.dart';

void exportCsvWeb(String csvData, String baseFileName) {
  final blob = html.Blob([csvData], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Dosya adını oluştururken DateFormat doğru kullanımı
  final String formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final String fileName = '${baseFileName}_$formattedDate.csv';

  // ignore: unsafe_html
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName; // Düzeltilmiş dosya adı
  
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
} 