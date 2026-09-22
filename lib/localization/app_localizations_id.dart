// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Nuzul';

  @override
  String get login => 'Masuk';

  @override
  String get register => 'Buat Akun';

  @override
  String get email => 'Email';

  @override
  String get password => 'Kata Sandi';

  @override
  String get confirmPassword => 'Konfirmasi Kata Sandi';

  @override
  String get fullName => 'Nama Lengkap';

  @override
  String get noAccountRegister => 'Belum punya akun? Buat akun baru';

  @override
  String get haveAccountLogin => 'Sudah punya akun? Masuk';

  @override
  String get whereTo => 'Mau ke mana? (Kota)';

  @override
  String get guests => 'tamu';

  @override
  String get search => 'Cari';

  @override
  String get bookNow => 'Pesan Sekarang';

  @override
  String get myBookings => 'Pesanan Saya';

  @override
  String get searchPrompt => 'Cari kota untuk melihat hotel yang tersedia';

  @override
  String get noResults =>
      'Tidak ada hotel yang tersedia untuk kota dan tanggal ini';

  @override
  String get searching => 'Mencari hotel...';

  @override
  String get errorLoadResults => 'Gagal memuat hasil, periksa koneksi Anda';

  @override
  String get retry => 'Coba Lagi';

  @override
  String get perNight => 'malam';

  @override
  String get confirmBookingTitle => 'Konfirmasi Pemesanan';

  @override
  String get checkInLabel => 'Check-in';

  @override
  String get checkOutLabel => 'Check-out';

  @override
  String get nightsLabel => 'Jumlah Malam';

  @override
  String get guestsLabel => 'Jumlah Tamu';

  @override
  String get totalLabel => 'Total';

  @override
  String get confirmBookingButton => 'Konfirmasi Pemesanan';

  @override
  String get paymentNote =>
      'Catatan: Pembayaran sebenarnya melalui Stripe akan ditambahkan pada langkah berikutnya — pemesanan ini saat ini tercatat dengan status \"menunggu\".';

  @override
  String get bookingSuccessTitle => 'Permintaan Pemesanan Terkirim';

  @override
  String get ok => 'OK';

  @override
  String get statusPending => 'Menunggu';

  @override
  String get statusConfirmed => 'Dikonfirmasi';

  @override
  String get statusCancelled => 'Dibatalkan';

  @override
  String get cancelBooking => 'Batalkan Pemesanan';

  @override
  String get cancelBookingConfirmTitle => 'Batalkan Pemesanan';

  @override
  String get cancelBookingUndo => 'Batalkan Tindakan';

  @override
  String get cancelBookingYes => 'Ya, Batalkan';

  @override
  String get noBookingsYet => 'Anda belum memiliki pesanan';

  @override
  String get loadingBookings => 'Memuat pesanan Anda...';

  @override
  String get errorLoadBookings => 'Gagal memuat pesanan, periksa koneksi Anda';

  @override
  String get loginRequired => 'Anda harus masuk terlebih dahulu';

  @override
  String get roomTypeSectionTitle => 'Tipe Kamar';

  @override
  String get roomQueen => 'Kamar Queen (2 tempat tidur)';

  @override
  String get roomKing => 'Kamar King';

  @override
  String get roomStudioSuite => 'Suite Studio';

  @override
  String get aboutAreaTitle => 'Tentang Area Sekitar';

  @override
  String aboutAreaDescription(String city) {
    return 'Hotel ini memiliki lokasi yang sangat baik di $city, dekat dengan landmark utama dan fasilitas penting, menjadikannya pilihan yang praktis untuk berkeliling selama menginap Anda.';
  }

  @override
  String paymentSucceededBookingError(String message) {
    return 'Pembayaran berhasil, tetapi terjadi kesalahan saat mencatat pesanan: $message';
  }

  @override
  String bookingCreateError(String message) {
    return 'Terjadi kesalahan saat mencatat pesanan: $message';
  }
}
