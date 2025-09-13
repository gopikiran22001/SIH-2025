import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ErrorHandler {
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
           error is TimeoutException ||
           error.toString().contains('Network') ||
           error.toString().contains('timeout') ||
           error.toString().contains('connection');
  }

  static String getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timeout - check your internet';
    }
    if (error is SocketException) {
      return 'No internet connection';
    }
    if (error.toString().contains('timeout')) {
      return 'Request timed out - you may be offline';
    }
    if (error.toString().contains('Network')) {
      return 'Network error - check your connection';
    }
    return 'Something went wrong - using cached data';
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    if (!isNetworkError(error)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getErrorMessage(error)),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static Widget buildErrorWidget(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}