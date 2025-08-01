import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('Error: $error');
      print('StackTrace: $stackTrace');
    }

    // Firebase Crashlytics'ga yuborish (keyinchalik)
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  static Widget buildErrorWidget(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Xatolik yuz berdi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // App'ni qayta ishga tushirish
              },
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }
}
