// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Nuzul';

  @override
  String get login => 'लॉग इन करें';

  @override
  String get register => 'खाता बनाएं';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get noAccountRegister => 'खाता नहीं है? एक बनाएं';

  @override
  String get haveAccountLogin => 'पहले से खाता है? लॉग इन करें';

  @override
  String get whereTo => 'कहाँ जाना है? (शहर)';

  @override
  String get guests => 'मेहमान';

  @override
  String get search => 'खोजें';

  @override
  String get bookNow => 'अभी बुक करें';

  @override
  String get myBookings => 'मेरी बुकिंग';

  @override
  String get searchPrompt => 'उपलब्ध होटल देखने के लिए एक शहर खोजें';

  @override
  String get noResults => 'इस शहर और तारीखों के लिए कोई होटल उपलब्ध नहीं है';

  @override
  String get searching => 'होटल खोजे जा रहे हैं...';

  @override
  String get errorLoadResults => 'परिणाम लोड नहीं हो सके, अपना कनेक्शन जांचें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get perNight => 'रात';

  @override
  String get confirmBookingTitle => 'बुकिंग की पुष्टि करें';

  @override
  String get checkInLabel => 'चेक-इन';

  @override
  String get checkOutLabel => 'चेक-आउट';

  @override
  String get nightsLabel => 'रातों की संख्या';

  @override
  String get guestsLabel => 'मेहमानों की संख्या';

  @override
  String get totalLabel => 'कुल';

  @override
  String get confirmBookingButton => 'बुकिंग की पुष्टि करें';

  @override
  String get paymentNote =>
      'नोट: Stripe के ज़रिए वास्तविक भुगतान अगले चरण में जोड़ा जाएगा — यह बुकिंग फ़िलहाल \"लंबित\" स्थिति में दर्ज है।';

  @override
  String get bookingSuccessTitle => 'बुकिंग अनुरोध भेजा गया';

  @override
  String get ok => 'ठीक है';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusConfirmed => 'पुष्टि हो गई';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String get cancelBooking => 'बुकिंग रद्द करें';

  @override
  String get cancelBookingConfirmTitle => 'बुकिंग रद्द करें';

  @override
  String get cancelBookingUndo => 'पूर्ववत करें';

  @override
  String get cancelBookingYes => 'हाँ, रद्द करें';

  @override
  String get noBookingsYet => 'आपके पास अभी तक कोई बुकिंग नहीं है';

  @override
  String get loadingBookings => 'आपकी बुकिंग लोड हो रही हैं...';

  @override
  String get errorLoadBookings =>
      'बुकिंग लोड नहीं हो सकीं, अपना कनेक्शन जांचें';

  @override
  String get loginRequired => 'आपको पहले साइन इन करना होगा';

  @override
  String get roomTypeSectionTitle => 'कमरे का प्रकार';

  @override
  String get roomQueen => 'क्वीन रूम (2 बिस्तर)';

  @override
  String get roomKing => 'किंग रूम';

  @override
  String get roomStudioSuite => 'स्टूडियो सुइट';

  @override
  String get aboutAreaTitle => 'आसपास के क्षेत्र के बारे में';

  @override
  String aboutAreaDescription(String city) {
    return 'यह होटल $city में एक शानदार स्थान पर स्थित है, प्रमुख स्थलों और आवश्यक सुविधाओं के करीब, जो आपके ठहरने के दौरान आसानी से आने-जाने के लिए एक सुविधाजनक विकल्प बनाता है।';
  }

  @override
  String paymentSucceededBookingError(String message) {
    return 'भुगतान सफल हुआ, लेकिन बुकिंग दर्ज करते समय एक त्रुटि हुई: $message';
  }

  @override
  String bookingCreateError(String message) {
    return 'बुकिंग दर्ज करते समय एक त्रुटि हुई: $message';
  }
}
