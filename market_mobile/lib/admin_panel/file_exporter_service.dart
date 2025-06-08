export 'stub_file_exporter.dart' // Varsayılan olarak stub kullanılır
    if (dart.library.html) 'web_file_exporter.dart'; // Web ise web_file_exporter kullanılır 