// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Nuzul';

  @override
  String get login => 'Giriş Yap';

  @override
  String get register => 'Hesap Oluştur';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get noAccountRegister => 'Hesabınız yok mu? Hesap oluşturun';

  @override
  String get haveAccountLogin => 'Zaten bir hesabınız var mı? Giriş yapın';

  @override
  String get whereTo => 'Nereye? (Şehir)';

  @override
  String get guests => 'misafir';

  @override
  String get search => 'Ara';

  @override
  String get bookNow => 'Şimdi Rezervasyon Yap';

  @override
  String get myBookings => 'Rezervasyonlarım';

  @override
  String get searchPrompt => 'Uygun otelleri görmek için bir şehir arayın';

  @override
  String get noResults => 'Bu şehir ve tarihler için uygun otel yok';

  @override
  String get searching => 'Oteller aranıyor...';

  @override
  String get errorLoadResults =>
      'Sonuçlar yüklenemedi, bağlantınızı kontrol edin';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get perNight => 'gece';

  @override
  String get confirmBookingTitle => 'Rezervasyonu Onayla';

  @override
  String get checkInLabel => 'Giriş Tarihi';

  @override
  String get checkOutLabel => 'Çıkış Tarihi';

  @override
  String get nightsLabel => 'Gece Sayısı';

  @override
  String get guestsLabel => 'Misafir Sayısı';

  @override
  String get totalLabel => 'Toplam';

  @override
  String get confirmBookingButton => 'Rezervasyonu Onayla';

  @override
  String get paymentNote =>
      'Not: Stripe üzerinden gerçek ödeme bir sonraki adımda eklenecek — bu rezervasyon şu anda \"beklemede\" durumunda kaydedildi.';

  @override
  String get bookingSuccessTitle => 'Rezervasyon Talebi Gönderildi';

  @override
  String get ok => 'Tamam';

  @override
  String get statusPending => 'Beklemede';

  @override
  String get statusConfirmed => 'Onaylandı';

  @override
  String get statusCancelled => 'İptal Edildi';

  @override
  String get cancelBooking => 'Rezervasyonu İptal Et';

  @override
  String get cancelBookingConfirmTitle => 'Rezervasyonu İptal Et';

  @override
  String get cancelBookingUndo => 'Geri Al';

  @override
  String get cancelBookingYes => 'Evet, İptal Et';

  @override
  String get noBookingsYet => 'Henüz rezervasyonunuz yok';

  @override
  String get loadingBookings => 'Rezervasyonlarınız yükleniyor...';

  @override
  String get errorLoadBookings =>
      'Rezervasyonlar yüklenemedi, bağlantınızı kontrol edin';

  @override
  String get loginRequired => 'Önce giriş yapmalısınız';

  @override
  String get roomTypeSectionTitle => 'Oda Tipi';

  @override
  String get roomQueen => 'Queen Oda (2 yatak)';

  @override
  String get roomKing => 'King Oda';

  @override
  String get roomStudioSuite => 'Stüdyo Süit';

  @override
  String get aboutAreaTitle => 'Çevredeki Bölge Hakkında';

  @override
  String aboutAreaDescription(String city) {
    return 'Bu otel $city içinde, önemli simge yapılara ve temel olanaklara yakın, avantajlı bir konumda yer alır ve konaklamanız boyunca kolay ulaşım sağlar.';
  }

  @override
  String paymentSucceededBookingError(String message) {
    return 'Ödeme başarılı oldu, ancak rezervasyon kaydedilirken bir hata oluştu: $message';
  }

  @override
  String bookingCreateError(String message) {
    return 'Rezervasyon kaydedilirken bir hata oluştu: $message';
  }
}
