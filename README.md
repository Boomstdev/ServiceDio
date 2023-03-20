# ServiceDio

please init to print log

 if (kDebugMode) {
    Service.dio.interceptors.add(PrettyDioLogger(
      request: true,
      requestHeader: true,
      responseBody: true,
      requestBody: true,
      responseHeader: true,
      compact: true,
      error: true,
    ));
    // Service.dio.interceptors
    //     .add(CurlLoggerDioInterceptor(printOnSuccess: true));
  }
