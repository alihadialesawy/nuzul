// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Nuzul';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Créer un compte';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get noAccountRegister => 'Vous n\'avez pas de compte ? Créez-en un';

  @override
  String get haveAccountLogin => 'Vous avez déjà un compte ? Connectez-vous';

  @override
  String get whereTo => 'Où allez-vous ? (Ville)';

  @override
  String get guests => 'voyageurs';

  @override
  String get search => 'Rechercher';

  @override
  String get bookNow => 'Réserver maintenant';

  @override
  String get myBookings => 'Mes réservations';

  @override
  String get searchPrompt =>
      'Recherchez une ville pour voir les hôtels disponibles';

  @override
  String get noResults =>
      'Aucun hôtel disponible pour cette ville et ces dates';

  @override
  String get searching => 'Recherche d\'hôtels en cours...';

  @override
  String get errorLoadResults =>
      'Impossible de charger les résultats, vérifiez votre connexion';

  @override
  String get retry => 'Réessayer';

  @override
  String get perNight => 'nuit';

  @override
  String get confirmBookingTitle => 'Confirmer la réservation';

  @override
  String get checkInLabel => 'Arrivée';

  @override
  String get checkOutLabel => 'Départ';

  @override
  String get nightsLabel => 'Nombre de nuits';

  @override
  String get guestsLabel => 'Nombre de voyageurs';

  @override
  String get totalLabel => 'Total';

  @override
  String get confirmBookingButton => 'Confirmer la réservation';

  @override
  String get paymentNote =>
      'Remarque : le paiement réel via Stripe sera ajouté à l\'étape suivante — cette réservation est actuellement enregistrée avec le statut « en attente ».';

  @override
  String get bookingSuccessTitle => 'Demande de réservation envoyée';

  @override
  String get ok => 'OK';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusConfirmed => 'Confirmée';

  @override
  String get statusCancelled => 'Annulée';

  @override
  String get cancelBooking => 'Annuler la réservation';

  @override
  String get cancelBookingConfirmTitle => 'Annuler la réservation';

  @override
  String get cancelBookingUndo => 'Annuler';

  @override
  String get cancelBookingYes => 'Oui, annuler';

  @override
  String get noBookingsYet => 'Vous n\'avez encore aucune réservation';

  @override
  String get loadingBookings => 'Chargement de vos réservations...';

  @override
  String get errorLoadBookings =>
      'Impossible de charger les réservations, vérifiez votre connexion';

  @override
  String get loginRequired => 'Vous devez d\'abord vous connecter';

  @override
  String get roomTypeSectionTitle => 'Type de chambre';

  @override
  String get roomQueen => 'Chambre Queen (2 lits)';

  @override
  String get roomKing => 'Chambre King';

  @override
  String get roomStudioSuite => 'Suite studio';

  @override
  String get aboutAreaTitle => 'À propos des environs';

  @override
  String aboutAreaDescription(String city) {
    return 'Cet hôtel bénéficie d\'un emplacement privilégié à $city, à proximité des principaux sites touristiques et des commodités essentielles, ce qui en fait un choix pratique pour vous déplacer facilement pendant votre séjour.';
  }

  @override
  String paymentSucceededBookingError(String message) {
    return 'Le paiement a réussi, mais une erreur s\'est produite lors de l\'enregistrement de la réservation : $message';
  }

  @override
  String bookingCreateError(String message) {
    return 'Une erreur s\'est produite lors de l\'enregistrement de la réservation : $message';
  }
}
