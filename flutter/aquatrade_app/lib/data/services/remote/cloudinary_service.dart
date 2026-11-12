import 'dart:io';

import 'package:dio/dio.dart';

import 'api_service.dart';

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.videoUrl,
    required this.videoPublicId,
  });

  final String videoUrl;
  final String videoPublicId;
}

/// Upload video thẳng Cloudinary bằng chữ ký từ `GET /media/upload-signature`.
class CloudinaryService {
  CloudinaryService(this._api);

  final ApiService _api;
  static const _videoFolder = 'aquatrade/videos';

  final Dio _uploadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
    ),
  );

  Future<CloudinaryUploadResult> uploadVideo(File file) async {
    final response = await _api.get('/media/upload-signature');
    final data = _api.parseData<Map<String, dynamic>>(response);

    final signature = data['signature']?.toString();
    final timestamp = data['timestamp'];
    final apiKey = data['apiKey']?.toString();
    final cloudName = data['cloudName']?.toString();
    final uploadPreset = data['uploadPreset']?.toString();

    if (signature == null ||
        timestamp == null ||
        apiKey == null ||
        cloudName == null ||
        uploadPreset == null) {
      throw const ApiException('Backend không trả chữ ký Cloudinary hợp lệ.');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'api_key': apiKey,
      'timestamp': timestamp.toString(),
      'signature': signature,
      'upload_preset': uploadPreset,
      'folder': _videoFolder,
    });

    final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/video/upload';
    final uploadResponse = await _uploadDio.post<Map<String, dynamic>>(
      uploadUrl,
      data: formData,
    );

    final body = uploadResponse.data;
    if (uploadResponse.statusCode != 200 || body == null) {
      throw const ApiException('Upload video Cloudinary thất bại.');
    }

    final videoUrl = body['secure_url']?.toString();
    final publicId = body['public_id']?.toString();
    if (videoUrl == null || videoUrl.isEmpty || publicId == null) {
      throw const ApiException('Cloudinary không trả URL video.');
    }

    return CloudinaryUploadResult(
      videoUrl: videoUrl,
      videoPublicId: publicId,
    );
  }
}
