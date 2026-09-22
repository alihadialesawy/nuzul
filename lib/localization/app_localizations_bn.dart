// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'Nuzul';

  @override
  String get login => 'লগ ইন করুন';

  @override
  String get register => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get email => 'ইমেইল';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get confirmPassword => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get fullName => 'পুরো নাম';

  @override
  String get noAccountRegister => 'অ্যাকাউন্ট নেই? নতুন অ্যাকাউন্ট তৈরি করুন';

  @override
  String get haveAccountLogin => 'আগে থেকেই অ্যাকাউন্ট আছে? লগ ইন করুন';

  @override
  String get whereTo => 'কোথায় যাচ্ছেন? (শহর)';

  @override
  String get guests => 'অতিথি';

  @override
  String get search => 'অনুসন্ধান করুন';

  @override
  String get bookNow => 'এখনই বুক করুন';

  @override
  String get myBookings => 'আমার বুকিং';

  @override
  String get searchPrompt => 'উপলব্ধ হোটেল দেখতে একটি শহর খুঁজুন';

  @override
  String get noResults => 'এই শহর ও তারিখের জন্য কোনো হোটেল পাওয়া যায়নি';

  @override
  String get searching => 'হোটেল খোঁজা হচ্ছে...';

  @override
  String get errorLoadResults =>
      'ফলাফল লোড করা যায়নি, আপনার সংযোগ পরীক্ষা করুন';

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get perNight => 'প্রতি রাত';

  @override
  String get confirmBookingTitle => 'বুকিং নিশ্চিত করুন';

  @override
  String get checkInLabel => 'চেক-ইন তারিখ';

  @override
  String get checkOutLabel => 'চেক-আউট তারিখ';

  @override
  String get nightsLabel => 'রাতের সংখ্যা';

  @override
  String get guestsLabel => 'অতিথির সংখ্যা';

  @override
  String get totalLabel => 'মোট';

  @override
  String get confirmBookingButton => 'বুকিং নিশ্চিত করুন';

  @override
  String get paymentNote =>
      'দ্রষ্টব্য: Stripe এর মাধ্যমে প্রকৃত পেমেন্ট পরবর্তী ধাপে যোগ করা হবে — এই বুকিং বর্তমানে \"অপেক্ষমাণ\" অবস্থায় সংরক্ষিত।';

  @override
  String get bookingSuccessTitle => 'বুকিং অনুরোধ পাঠানো হয়েছে';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get statusPending => 'অপেক্ষমাণ';

  @override
  String get statusConfirmed => 'নিশ্চিত হয়েছে';

  @override
  String get statusCancelled => 'বাতিল হয়েছে';

  @override
  String get cancelBooking => 'বুকিং বাতিল করুন';

  @override
  String get cancelBookingConfirmTitle => 'বুকিং বাতিল করুন';

  @override
  String get cancelBookingUndo => 'পূর্বাবস্থায় ফিরুন';

  @override
  String get cancelBookingYes => 'হ্যাঁ, বাতিল করুন';

  @override
  String get noBookingsYet => 'এখনও আপনার কোনো বুকিং নেই';

  @override
  String get loadingBookings => 'আপনার বুকিং লোড হচ্ছে...';

  @override
  String get errorLoadBookings =>
      'বুকিং লোড করা যায়নি, আপনার সংযোগ পরীক্ষা করুন';

  @override
  String get loginRequired => 'প্রথমে আপনাকে লগ ইন করতে হবে';

  @override
  String get roomTypeSectionTitle => 'রুমের ধরন';

  @override
  String get roomQueen => 'দুই বিছানার কুইন রুম';

  @override
  String get roomKing => 'কিং রুম';

  @override
  String get roomStudioSuite => 'স্টুডিও স্যুট';

  @override
  String get aboutAreaTitle => 'আশেপাশের এলাকা সম্পর্কে';

  @override
  String aboutAreaDescription(String city) {
    return 'এই হোটেলটি $city-এ একটি চমৎকার অবস্থানে রয়েছে, গুরুত্বপূর্ণ স্থান ও সুবিধার কাছাকাছি, যা আপনার থাকাকালীন চলাচল সহজ করে তোলে।';
  }

  @override
  String paymentSucceededBookingError(String message) {
    return 'পেমেন্ট সফল হয়েছে, কিন্তু বুকিং রেকর্ড করার সময় একটি ত্রুটি ঘটেছে: $message';
  }

  @override
  String bookingCreateError(String message) {
    return 'বুকিং রেকর্ড করার সময় একটি ত্রুটি ঘটেছে: $message';
  }
}
