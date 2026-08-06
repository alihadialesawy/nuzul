// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nuzul';

  @override
  String get login => 'Login';

  @override
  String get register => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get noAccountRegister => 'Don\'t have an account? Create one';

  @override
  String get haveAccountLogin => 'Already have an account? Login';

  @override
  String get whereTo => 'Where to? (City)';

  @override
  String get guests => 'guests';

  @override
  String get search => 'Search';

  @override
  String get bookNow => 'Book Now';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get searchPrompt => 'Search a city to see available hotels';

  @override
  String get noResults => 'No hotels available for this city and dates';

  @override
  String get searching => 'Searching hotels...';

  @override
  String get errorLoadResults =>
      'Failed to load results, check your connection';

  @override
  String get retry => 'Retry';

  @override
  String get perNight => 'night';

  @override
  String get confirmBookingTitle => 'Confirm Booking';

  @override
  String get checkInLabel => 'Check-in';

  @override
  String get checkOutLabel => 'Check-out';

  @override
  String get nightsLabel => 'Nights';

  @override
  String get guestsLabel => 'Guests';

  @override
  String get totalLabel => 'Total';

  @override
  String get confirmBookingButton => 'Confirm Booking';

  @override
  String get paymentNote =>
      'Note: Actual payment via Stripe will be added in the next step — this booking is currently recorded as \"pending\".';

  @override
  String get bookingSuccessTitle => 'Booking Request Sent';

  @override
  String get ok => 'OK';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get cancelBookingConfirmTitle => 'Cancel Booking';

  @override
  String get cancelBookingUndo => 'Undo';

  @override
  String get cancelBookingYes => 'Yes, Cancel';

  @override
  String get noBookingsYet => 'You have no bookings yet';

  @override
  String get loadingBookings => 'Loading your bookings...';

  @override
  String get errorLoadBookings =>
      'Failed to load bookings, check your connection';

  @override
  String get loginRequired => 'You must sign in first';

  @override
  String get roomTypeSectionTitle => 'Room Type';

  @override
  String get roomQueen => 'Queen Room (2 beds)';

  @override
  String get roomKing => 'King Room';

  @override
  String get roomStudioSuite => 'Studio Suite';

  @override
  String get aboutAreaTitle => 'About the Surrounding Area';

  @override
  String aboutAreaDescription(String city) {
    return 'This hotel enjoys a prime location in $city, close to major landmarks and essential facilities, making it a convenient choice for getting around during your stay.';
  }
}
