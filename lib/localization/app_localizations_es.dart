// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Safr-AI';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get register => 'Crear cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get noAccountRegister => '¿No tienes una cuenta? Crear cuenta nueva';

  @override
  String get haveAccountLogin => '¿Ya tienes una cuenta? Iniciar sesión';

  @override
  String get whereTo => '¿A dónde vas? (Ciudad)';

  @override
  String get guests => 'Huéspedes';

  @override
  String get search => 'Buscar';

  @override
  String get bookNow => 'Reservar ahora';

  @override
  String get myBookings => 'Mis reservas';

  @override
  String get searchPrompt =>
      'Busca una ciudad para ver los hoteles disponibles';

  @override
  String get noResults =>
      'No hay hoteles disponibles para esta ciudad y fechas';

  @override
  String get searching => 'Buscando hoteles...';

  @override
  String get errorLoadResults =>
      'No se pudieron cargar los resultados, revisa tu conexión';

  @override
  String get retry => 'Reintentar';

  @override
  String get perNight => 'por noche';

  @override
  String get confirmBookingTitle => 'Confirmar reserva';

  @override
  String get checkInLabel => 'Fecha de entrada';

  @override
  String get checkOutLabel => 'Fecha de salida';

  @override
  String get nightsLabel => 'Número de noches';

  @override
  String get guestsLabel => 'Número de huéspedes';

  @override
  String get totalLabel => 'Total';

  @override
  String get confirmBookingButton => 'Confirmar reserva';

  @override
  String get paymentNote =>
      'Nota: el pago real a través de Stripe se añadirá en el siguiente paso — esta reserva se registra actualmente con estado \"pendiente\".';

  @override
  String get bookingSuccessTitle => 'Solicitud de reserva enviada';

  @override
  String get ok => 'Aceptar';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusConfirmed => 'Confirmada';

  @override
  String get statusCancelled => 'Cancelada';

  @override
  String get cancelBooking => 'Cancelar reserva';

  @override
  String get cancelBookingConfirmTitle => 'Cancelar reserva';

  @override
  String get cancelBookingUndo => 'Deshacer';

  @override
  String get cancelBookingYes => 'Sí, cancelar';

  @override
  String get noBookingsYet => 'Aún no tienes ninguna reserva';

  @override
  String get loadingBookings => 'Cargando tus reservas...';

  @override
  String get errorLoadBookings =>
      'No se pudieron cargar las reservas, revisa tu conexión';

  @override
  String get loginRequired => 'Debes iniciar sesión primero';

  @override
  String get roomTypeSectionTitle => 'Tipo de habitación';

  @override
  String get roomQueen => 'Habitación con dos camas queen';

  @override
  String get roomKing => 'Habitación king';

  @override
  String get roomStudioSuite => 'Suite estudio';

  @override
  String get aboutAreaTitle => 'Sobre la zona';

  @override
  String aboutAreaDescription(String city) {
    return 'Este hotel está ubicado en una zona privilegiada de $city, cerca de los principales lugares de interés y servicios esenciales, lo que lo convierte en una opción práctica para moverte fácilmente durante tu estancia.';
  }
}
