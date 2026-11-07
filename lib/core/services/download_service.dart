import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<String> downloadFile({
    required String url,
    required String fileName,
    Directory? directory,
  }) async {
    final targetDirectory = directory ?? await getApplicationDocumentsDirectory();
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final filePath = '${targetDirectory.path}/$fileName';
    final response = await _dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final file = File(filePath);
    await file.writeAsBytes(response.data as List<int>);
    return filePath;
  }
}
