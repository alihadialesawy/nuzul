import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'نزل'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get register;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @noAccountRegister.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ إنشاء حساب جديد'**
  String get noAccountRegister;

  /// No description provided for @haveAccountLogin.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟ تسجيل الدخول'**
  String get haveAccountLogin;

  /// No description provided for @whereTo.
  ///
  /// In ar, this message translates to:
  /// **'وين رايح؟ (المدينة)'**
  String get whereTo;

  /// No description provided for @guests.
  ///
  /// In ar, this message translates to:
  /// **'ضيوف'**
  String get guests;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @bookNow.
  ///
  /// In ar, this message translates to:
  /// **'احجز الآن'**
  String get bookNow;

  /// No description provided for @myBookings.
  ///
  /// In ar, this message translates to:
  /// **'حجوزاتي'**
  String get myBookings;

  /// No description provided for @searchPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مدينة لعرض الفنادق المتاحة'**
  String get searchPrompt;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فنادق متاحة لهذه المدينة والتواريخ'**
  String get noResults;

  /// No description provided for @searching.
  ///
  /// In ar, this message translates to:
  /// **'يبحث عن الفنادق...'**
  String get searching;

  /// No description provided for @errorLoadResults.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل النتائج، تحقق من الاتصال'**
  String get errorLoadResults;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @perNight.
  ///
  /// In ar, this message translates to:
  /// **'الليلة'**
  String get perNight;

  /// No description provided for @confirmBookingTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحجز'**
  String get confirmBookingTitle;

  /// No description provided for @checkInLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الوصول'**
  String get checkInLabel;

  /// No description provided for @checkOutLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ المغادرة'**
  String get checkOutLabel;

  /// No description provided for @nightsLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد الليالي'**
  String get nightsLabel;

  /// No description provided for @guestsLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد الضيوف'**
  String get guestsLabel;

  /// No description provided for @totalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get totalLabel;

  /// No description provided for @confirmBookingButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحجز'**
  String get confirmBookingButton;

  /// No description provided for @paymentNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة: الدفع الفعلي عبر Stripe سيُضاف بالخطوة القادمة — هذا الحجز حاليًا يُسجَّل بحالة \"قيد الانتظار\".'**
  String get paymentNote;

  /// No description provided for @bookingSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب الحجز'**
  String get bookingSuccessTitle;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'حسنًا'**
  String get ok;

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get statusConfirmed;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get statusCancelled;

  /// No description provided for @cancelBooking.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحجز'**
  String get cancelBooking;

  /// No description provided for @cancelBookingConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحجز'**
  String get cancelBookingConfirmTitle;

  /// No description provided for @cancelBookingUndo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get cancelBookingUndo;

  /// No description provided for @cancelBookingYes.
  ///
  /// In ar, this message translates to:
  /// **'نعم، إلغاء'**
  String get cancelBookingYes;

  /// No description provided for @noBookingsYet.
  ///
  /// In ar, this message translates to:
  /// **'ماعندك أي حجوزات لحد الآن'**
  String get noBookingsYet;

  /// No description provided for @loadingBookings.
  ///
  /// In ar, this message translates to:
  /// **'يحمّل حجوزاتك...'**
  String get loadingBookings;

  /// No description provided for @errorLoadBookings.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الحجوزات، تحقق من الاتصال'**
  String get errorLoadBookings;

  /// No description provided for @loginRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول أولاً'**
  String get loginRequired;

  /// No description provided for @roomTypeSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'نوع الغرفة'**
  String get roomTypeSectionTitle;

  /// No description provided for @roomQueen.
  ///
  /// In ar, this message translates to:
  /// **'غرفة كوين سريرين'**
  String get roomQueen;

  /// No description provided for @roomKing.
  ///
  /// In ar, this message translates to:
  /// **'غرفة كينج'**
  String get roomKing;

  /// No description provided for @roomStudioSuite.
  ///
  /// In ar, this message translates to:
  /// **'جناح استوديو'**
  String get roomStudioSuite;

  /// No description provided for @aboutAreaTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن المنطقة المحيطة'**
  String get aboutAreaTitle;

  /// No description provided for @aboutAreaDescription.
  ///
  /// In ar, this message translates to:
  /// **'يقع هذا الفندق في موقع مميز داخل {city}، بالقرب من أبرز المعالم والمرافق الحيوية، مما يجعله خيارًا مناسبًا للتنقل بسهولة خلال إقامتك.'**
  String aboutAreaDescription(String city);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
