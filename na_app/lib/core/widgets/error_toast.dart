import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/theme/app_colors.dart';

class ErrorToast {
  ErrorToast._();

  static void show(BuildContext context, Object error) {
    final message = _extractMessage(error);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBgElevated : AppColors.bgSunken,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.darkBorderStrong : AppColors.borderStrong,
          ),
        ),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static String _extractMessage(Object error) {
    if (error is DioException) {
      final apiError = error.error;
      if (apiError is ApiException) {
        return _humanizeApiException(apiError);
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    if (error is ApiException) {
      return _humanizeApiException(error);
    }
    return 'An unexpected error occurred.';
  }

  static String _humanizeApiException(ApiException e) {
    if (e.isRateLimited) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (e.isUnauthorized) {
      return 'Session expired. Please sign in again.';
    }
    if (e.isForbidden) {
      return 'You don\'t have permission to do this.';
    }
    if (e.isNotFound) {
      return 'The requested resource was not found.';
    }
    if (e.isGone) {
      return 'This link has expired. Please request a new one.';
    }
    if (e.isClientError) {
      return e.message.isNotEmpty
          ? e.message
          : 'Invalid request. Please check your input.';
    }
    if (e.statusCode >= 500) {
      return 'Server error. Please try again later.';
    }
    return e.message.isNotEmpty
        ? e.message
        : 'Something went wrong. Please try again.';
  }
}
