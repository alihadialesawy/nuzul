// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'Nuzul';

  @override
  String get login => 'لاگ ان کریں';

  @override
  String get register => 'اکاؤنٹ بنائیں';

  @override
  String get email => 'ای میل';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get confirmPassword => 'پاس ورڈ کی تصدیق کریں';

  @override
  String get fullName => 'پورا نام';

  @override
  String get noAccountRegister => 'اکاؤنٹ نہیں ہے؟ ایک بنائیں';

  @override
  String get haveAccountLogin => 'پہلے سے اکاؤنٹ ہے؟ لاگ ان کریں';

  @override
  String get whereTo => 'کہاں جانا ہے؟ (شہر)';

  @override
  String get guests => 'مہمان';

  @override
  String get search => 'تلاش کریں';

  @override
  String get bookNow => 'ابھی بک کریں';

  @override
  String get myBookings => 'میری بکنگز';

  @override
  String get searchPrompt => 'دستیاب ہوٹل دیکھنے کے لیے ایک شہر تلاش کریں';

  @override
  String get noResults => 'اس شہر اور تاریخوں کے لیے کوئی ہوٹل دستیاب نہیں';

  @override
  String get searching => 'ہوٹل تلاش کیے جا رہے ہیں...';

  @override
  String get errorLoadResults => 'نتائج لوڈ نہیں ہو سکے، اپنا کنکشن چیک کریں';

  @override
  String get retry => 'دوبارہ کوشش کریں';

  @override
  String get perNight => 'رات';

  @override
  String get confirmBookingTitle => 'بکنگ کی تصدیق کریں';

  @override
  String get checkInLabel => 'چیک ان';

  @override
  String get checkOutLabel => 'چیک آؤٹ';

  @override
  String get nightsLabel => 'راتوں کی تعداد';

  @override
  String get guestsLabel => 'مہمانوں کی تعداد';

  @override
  String get totalLabel => 'کل';

  @override
  String get confirmBookingButton => 'بکنگ کی تصدیق کریں';

  @override
  String get paymentNote =>
      'نوٹ: Stripe کے ذریعے اصل ادائیگی اگلے مرحلے میں شامل کی جائے گی — یہ بکنگ فی الحال \"زیر التوا\" حالت میں درج ہے۔';

  @override
  String get bookingSuccessTitle => 'بکنگ کی درخواست بھیج دی گئی';

  @override
  String get ok => 'ٹھیک ہے';

  @override
  String get statusPending => 'زیر التوا';

  @override
  String get statusConfirmed => 'تصدیق شدہ';

  @override
  String get statusCancelled => 'منسوخ';

  @override
  String get cancelBooking => 'بکنگ منسوخ کریں';

  @override
  String get cancelBookingConfirmTitle => 'بکنگ منسوخ کریں';

  @override
  String get cancelBookingUndo => 'کالعدم کریں';

  @override
  String get cancelBookingYes => 'جی ہاں، منسوخ کریں';

  @override
  String get noBookingsYet => 'آپ کے پاس ابھی تک کوئی بکنگ نہیں ہے';

  @override
  String get loadingBookings => 'آپ کی بکنگز لوڈ ہو رہی ہیں...';

  @override
  String get errorLoadBookings => 'بکنگز لوڈ نہیں ہو سکیں، اپنا کنکشن چیک کریں';

  @override
  String get loginRequired => 'آپ کو پہلے سائن ان کرنا ہوگا';

  @override
  String get roomTypeSectionTitle => 'کمرے کی قسم';

  @override
  String get roomQueen => 'کوئین روم (2 بستر)';

  @override
  String get roomKing => 'کنگ روم';

  @override
  String get roomStudioSuite => 'اسٹوڈیو سویٹ';

  @override
  String get aboutAreaTitle => 'ارد گرد کے علاقے کے بارے میں';

  @override
  String aboutAreaDescription(String city) {
    return 'یہ ہوٹل $city میں ایک بہترین مقام پر واقع ہے، اہم مقامات اور ضروری سہولیات کے قریب، جو آپ کے قیام کے دوران آسانی سے آنے جانے کے لیے ایک آسان انتخاب بناتا ہے۔';
  }

  @override
  String paymentSucceededBookingError(String message) {
    return 'ادائیگی کامیاب رہی، لیکن بکنگ درج کرتے وقت ایک خرابی پیش آئی: $message';
  }

  @override
  String bookingCreateError(String message) {
    return 'بکنگ درج کرتے وقت ایک خرابی پیش آئی: $message';
  }
}
