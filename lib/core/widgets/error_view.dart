import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// عرض موحد لحالة الخطأ — رسالة + زر إعادة المحاولة
///
/// FittedBox اتشالت من هنا: كانت بتنكسر (RenderFittedBox 'child!.hasSize'
/// is not true / BoxConstraints forces an infinite width) لما الودجت
/// يترسم أثناء تغيّر ديناميكي في حجم الشاشة (مثلًا فتح الكيبورد فوق
/// شاشة فيها bottom sheet مفتوحة، زي شاشة المجتمع). استبدلناها بـ Column
/// بسيط بدون أي عنصر تمرير إضافي (بدون SingleChildScrollView، بما إن
/// إضافة عنصر تمرير جديد جوه تخطيط Stack/Offstage بالصفحة الرئيسية
/// معروف إنه يسبب كراش hit-test مختلف وأخطر — راجع home_page.dart).
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// "إعادة المحاولة" بلغة المستخدم (كانت مكتوبة بالعربية لكل اللغات).
  static String _retryLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ar':
        return 'إعادة المحاولة';
      case 'es':
        return 'Reintentar';
      case 'tr':
        return 'Tekrar dene';
      case 'id':
        return 'Coba lagi';
      case 'hi':
        return 'फिर से कोशिश करें';
      case 'ur':
        return 'دوبارہ کوشش کریں';
      case 'fr':
        return 'Réessayer';
      case 'bn':
        return 'আবার চেষ্টা করুন';
      default:
        return 'Try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_retryLabel(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}