// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'نزل';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get noAccountRegister => 'ليس لديك حساب؟ إنشاء حساب جديد';

  @override
  String get haveAccountLogin => 'لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get whereTo => 'وين رايح؟ (المدينة)';

  @override
  String get guests => 'ضيوف';

  @override
  String get search => 'بحث';

  @override
  String get bookNow => 'احجز الآن';

  @override
  String get myBookings => 'حجوزاتي';

  @override
  String get searchPrompt => 'ابحث عن مدينة لعرض الفنادق المتاحة';

  @override
  String get noResults => 'لا توجد فنادق متاحة لهذه المدينة والتواريخ';

  @override
  String get searching => 'يبحث عن الفنادق...';

  @override
  String get errorLoadResults => 'تعذر تحميل النتائج، تحقق من الاتصال';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get perNight => 'الليلة';

  @override
  String get confirmBookingTitle => 'تأكيد الحجز';

  @override
  String get checkInLabel => 'تاريخ الوصول';

  @override
  String get checkOutLabel => 'تاريخ المغادرة';

  @override
  String get nightsLabel => 'عدد الليالي';

  @override
  String get guestsLabel => 'عدد الضيوف';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get confirmBookingButton => 'تأكيد الحجز';

  @override
  String get paymentNote =>
      'ملاحظة: الدفع الفعلي عبر Stripe سيُضاف بالخطوة القادمة — هذا الحجز حاليًا يُسجَّل بحالة \"قيد الانتظار\".';

  @override
  String get bookingSuccessTitle => 'تم إرسال طلب الحجز';

  @override
  String get ok => 'حسنًا';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusConfirmed => 'مؤكد';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get cancelBooking => 'إلغاء الحجز';

  @override
  String get cancelBookingConfirmTitle => 'إلغاء الحجز';

  @override
  String get cancelBookingUndo => 'تراجع';

  @override
  String get cancelBookingYes => 'نعم، إلغاء';

  @override
  String get noBookingsYet => 'ماعندك أي حجوزات لحد الآن';

  @override
  String get loadingBookings => 'يحمّل حجوزاتك...';

  @override
  String get errorLoadBookings => 'تعذر تحميل الحجوزات، تحقق من الاتصال';

  @override
  String get loginRequired => 'يجب تسجيل الدخول أولاً';

  @override
  String get roomTypeSectionTitle => 'نوع الغرفة';

  @override
  String get roomQueen => 'غرفة كوين سريرين';

  @override
  String get roomKing => 'غرفة كينج';

  @override
  String get roomStudioSuite => 'جناح استوديو';

  @override
  String get aboutAreaTitle => 'عن المنطقة المحيطة';

  @override
  String aboutAreaDescription(String city) {
    return 'يقع هذا الفندق في موقع مميز داخل $city، بالقرب من أبرز المعالم والمرافق الحيوية، مما يجعله خيارًا مناسبًا للتنقل بسهولة خلال إقامتك.';
  }
}
