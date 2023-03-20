import 'dart:convert';
import 'package:dio/adapter.dart';
import '../app_import.dart';
import '../models/response_model.dart';

class Service {
  static final Dio _dio = Dio();
  static Dio get dio => _dio;
  static const int _sendTimeout = 100000;
  static const int _receiveTimeout = 100000;

  static Future<ResponseModel> post(
    String url, {
    Map<String, dynamic>? data,
    FormData? form,
    Object? object,
    String? token,
    String? jwt,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    bool sslEnable = false,
    int? receiveTimeout,
    int? sendTimeout,
  }) async {
    try {
      if (!kIsWeb && !sslEnable) {
        _configBadCert();
      }

      var requestHeaders = <String, dynamic>{};
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      Object? requestBody;

      if (form != null) {
        requestHeaders[HttpHeaders.contentTypeHeader] = "application/x-www-form-urlencoded";
        requestBody = form;
      } else if (data != null) {
        requestHeaders[HttpHeaders.contentTypeHeader] = "application/x-www-form-urlencoded";
        requestBody = FormData.fromMap(data);
      } else if (object != null) {
        requestHeaders[HttpHeaders.contentTypeHeader] = "application/json";
        requestBody = jsonEncode(object);
      } else {
        requestBody = null;
      }

      final response = await _dio.post(
        url,
        data: requestBody,
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: sendTimeout ?? _sendTimeout,
          receiveTimeout: receiveTimeout ?? _receiveTimeout,
          headers: _defaultHeaders(requestHeaders, token: token, jwt: jwt),
          extra: {'refresh': true},
        ),
      );

      return ResponseModel(response);
    } on DioError catch (e) {
      return _handleError(e);
    } catch (e, stacktrace) {
      debugPrint(stacktrace.toString());
      return ResponseModel.exception(e);
    }
  }

  static Future<ResponseModel> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    String? token,
    String? jwt,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    bool cache = true,
    bool sslEnable = false,
    int? receiveTimeout,
    int? sendTimeout,
  }) async {
    try {
      if (!kIsWeb && !sslEnable) {
        _configBadCert();
      }

      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: sendTimeout ?? _sendTimeout,
          receiveTimeout: receiveTimeout ?? _receiveTimeout,
          headers: _defaultHeaders(headers, token: token, jwt: jwt),
        ),
      );

      return ResponseModel(response);
    } on DioError catch (e) {
      return _handleError(e);
    } catch (e, stacktrace) {
      print(stacktrace);
      return ResponseModel.exception(e);
    }
  }

  static Future<ResponseModel> delete(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Object? object,
    String? token,
    String? jwt,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    bool sslEnable = false,
    int? receiveTimeout,
    int? sendTimeout,
  }) async {
    try {
      if (!kIsWeb && !sslEnable) {
        _configBadCert();
      }

      var requestHeaders = <String, dynamic>{};
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      Object? requestBody;
      if (data != null) {
        requestBody = FormData.fromMap(data);
      } else if (object != null) {
        requestHeaders[HttpHeaders.contentTypeHeader] = "application/json";
        requestBody = jsonEncode(object);
      } else {
        requestBody = null;
      }

      final response = await _dio.delete(
        url,
        data: requestBody,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: sendTimeout ?? _sendTimeout,
          receiveTimeout: receiveTimeout ?? _receiveTimeout,
          headers: _defaultHeaders(requestHeaders, token: token, jwt: jwt),
          extra: {'refresh': true},
        ),
      );

      return ResponseModel(response);
    } on DioError catch (e) {
      return _handleError(e);
    } catch (e, stacktrace) {
      print(stacktrace);
      return ResponseModel.exception(e);
    }
  }

  static Future<bool> download(
    String url,
    String savePath, {
    ProgressCallback? callback,
    bool sslEnable = false,
  }) async {
    try {
      Dio dio = Dio();

      Response response = await dio.get(
        url,
        onReceiveProgress: callback,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );

      print(response.headers);

      File file = File(savePath);
      var raf = file.openSync(mode: FileMode.write);
      raf.writeFromSync(response.data);
      await raf.close();
      return true;
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
      return false;
    }
  }

  static Map<String, dynamic>? _defaultHeaders(Map<String, dynamic>? headers, {String? token, String? jwt}) {
    var newHeader = <String, dynamic>{};

    if (headers != null) {
      newHeader.addAll(headers);
    }

    if (token != null) {
      newHeader[HttpHeaders.authorizationHeader] = "token $token";
    }

    if (jwt != null) {
      newHeader[HttpHeaders.authorizationHeader] = "Bearer $jwt";
    }

    return newHeader;
  }

  static MultipartFile uploadInfo({
    required File file,
    String? fileName,
    MediaType? contentType,
  }) =>
      MultipartFile.fromFileSync(file.path, contentType: contentType);

  static FormData form(Map<String, dynamic> other) => FormData.fromMap(other);

  static _configBadCert() {
    final clientAdapter = _dio.httpClientAdapter;

    if (clientAdapter is DefaultHttpClientAdapter) {
      clientAdapter.onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  static setCustomClientAdapter(HttpClientAdapter adapter) {
    _dio.httpClientAdapter = adapter;
  }

  static ResponseModel _handleError(DioError error) {
    switch (error.type) {
      case DioErrorType.connectTimeout:
        return ResponseModel.connectionError("Connection timeout");
      case DioErrorType.sendTimeout:
        return ResponseModel.connectionError("Connection timeout");
      case DioErrorType.receiveTimeout:
        return ResponseModel.connectionError("Connection timeout");
      case DioErrorType.response:
        return ResponseModel(error.response);
      case DioErrorType.cancel:
        return ResponseModel.connectionError("Request cancelled");
      case DioErrorType.other:
        return ResponseModel.connectionError(error.error?.toString() ?? "Client error");
    }
  }
}
