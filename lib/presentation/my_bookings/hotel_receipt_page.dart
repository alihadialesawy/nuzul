import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/booking_model.dart';

/// إيصال الدفع للعميل (منفصل عن القسيمة).
///
/// القسيمة (Voucher) يعرضها النزيل على الفندق، فتبقى بالإنجليزية ولا يظهر
/// فيها السعر. أما الإيصال فللعميل وحده، فيظهر بلغته (عربي/إنجليزي/إسباني؛
/// أي لغة أخرى تظهر بالإنجليزية): المبلغ المدفوع، والرسوم التي تُدفع في
/// الفندق، والاسترداد إن أُلغي الحجز.
///
/// ⚠️ لا نعرض مبلغ ضريبة مفصّلًا: HotelBeds لا ترسل تفصيل الضرائب في أغلب
/// الحجوزات، واحتساب ضريبة الإقامة على هامش الربح ما زال قيد المراجعة مع
/// المحاسب. الصيغة المعتمدة: "Total includes taxes and fees".
class HotelReceiptPage extends StatelessWidget {
  final BookingModel booking;
  const HotelReceiptPage({super.key, required this.booking});

  static String _usd(double v) => '\$${v.toStringAsFixed(2)} USD';

  static String _cardBrand(String? b) {
    switch ((b ?? '').toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'American Express';
      case 'discover':
        return 'Discover';
      case 'diners':
        return 'Diners Club';
      case 'jcb':
        return 'JCB';
      case 'unionpay':
        return 'UnionPay';
      default:
        return (b ?? '').isEmpty ? 'Card' : b![0].toUpperCase() + b.substring(1);
    }
  }

  static String _title(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final t = _ReceiptText.of(context);
    final b = booking;
    final paid = b.chargeAmount ?? 0;
    final cancelled = b.status == 'cancelled';
    final refund = b.refundAmount ?? 0;
    final nights = b.checkOut.difference(b.checkIn).inDays;

    return Scaffold(
      appBar: AppBar(title: Text(t.receipt)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── الرأس ──
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        'assets/images/logo_flynoom_dark.png',
                                        height: 40,
                                        alignment: AlignmentDirectional.centerStart,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder: (_, __, ___) => const Text(
                                          'FLYNOOM',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(t.paymentReceipt,
                                          style: const TextStyle(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (cancelled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.error),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(t.cancelledBadge,
                                        style: const TextStyle(
                                            color: AppColors.error, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const Divider(height: AppSizes.xl),

                            // ── المراجع ──
                            if (b.clientReference != null)
                              _Row(t.flynoomRef, b.clientReference!, ltr: true),
                            if (b.supplierReference != null)
                              _Row(t.bookingRef, b.supplierReference!, ltr: true),
                            if (b.createdAt != null) _Row(t.paymentDate, t.date(b.createdAt!.toLocal())),
                            _Row(t.paidBy, b.holderFullName),
                            if ((b.holderEmail ?? '').isNotEmpty) _Row(t.email, b.holderEmail!, ltr: true),

                            const SizedBox(height: AppSizes.md),
                            _Section(t.stay),
                            _Row(t.hotel, b.hotelName ?? ''),
                            _Row(t.dates, '${t.date(b.checkIn)} – ${t.date(b.checkOut)}'),
                            _Row(t.nights, '$nights'),
                            if ((b.roomName ?? '').isNotEmpty)
                              _Row(
                                t.room,
                                [b.roomName, b.boardName].where((s) => (s ?? '').isNotEmpty).join(' · '),
                              ),

                            // ── المبالغ ──
                            const SizedBox(height: AppSizes.md),
                            _Section(t.payment),
                            _AmountRow(t.totalPaid, _usd(paid), bold: true),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                t.includesTaxes,
                                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                            ),
                            if (b.cardLast4 != null)
                              _Row(t.paidWith, '${_cardBrand(b.cardBrand)} •••• ${b.cardLast4}', ltr: true),
                            if (cancelled) ...[
                              _AmountRow(
                                t.cancellationFee,
                                _usd(b.cancellationFee ?? (paid - refund).clamp(0, paid).toDouble()),
                              ),
                              _AmountRow(t.refunded, _usd(refund),
                                  color: refund > 0 ? AppColors.success : null),
                              if (b.cancelledAt != null)
                                Text('${t.cancelledOn} ${t.date(b.cancelledAt!.toLocal())}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                            ],

                            if (b.payAtHotelFees.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.md),
                              _Section(t.payableAtHotel),
                              for (final f in b.payAtHotelFees)
                                _AmountRow(
                                  _title((f['type'] ?? 'Fee').toString()),
                                  '${((f['amount'] as num?) ?? 0).toStringAsFixed(2)} ${f['currency'] ?? ''}',
                                ),
                              Text(
                                t.payAtHotelNote,
                                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                            ],

                            const Divider(height: AppSizes.xl),
                            // بيانات الشركة تبقى بالإنجليزية (الاسم القانوني وما يظهر في كشف البطاقة).
                            Text(
                              'FLYNOOM LLC · Michigan, USA · flynoom.com · support@flynoom.com\n'
                                  '${t.statementNote}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    t.printTip,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نصوص الإيصال بلغة المستخدم (العربية/الإسبانية، وغيرهما بالإنجليزية).
class _ReceiptText {
  final String lang;
  const _ReceiptText(this.lang);

  static _ReceiptText of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return _ReceiptText(code == 'ar' || code == 'es' ? code : 'en');
  }

  String _p(String en, String ar, String es) => lang == 'ar' ? ar : (lang == 'es' ? es : en);

  String get receipt => _p('Receipt', 'الإيصال', 'Recibo');
  String get paymentReceipt => _p('Payment receipt', 'إيصال دفع', 'Recibo de pago');
  String get cancelledBadge => _p('CANCELLED', 'ملغى', 'CANCELADA');
  String get flynoomRef => _p('Flynoom reference', 'رقم Flynoom', 'Referencia Flynoom');
  String get bookingRef => _p('Booking reference', 'رقم الحجز', 'Referencia de reserva');
  String get paymentDate => _p('Payment date', 'تاريخ الدفع', 'Fecha de pago');
  String get paidBy => _p('Paid by', 'الدافع', 'Pagado por');
  String get email => _p('Email', 'البريد الإلكتروني', 'Correo');
  String get stay => _p('Stay', 'الإقامة', 'Estancia');
  String get hotel => _p('Hotel', 'الفندق', 'Hotel');
  String get dates => _p('Dates', 'التواريخ', 'Fechas');
  String get nights => _p('Nights', 'عدد الليالي', 'Noches');
  String get room => _p('Room', 'الغرفة', 'Habitación');
  String get payment => _p('Payment', 'الدفع', 'Pago');
  String get totalPaid => _p('Total paid online', 'المبلغ المدفوع عبر الموقع', 'Total pagado en línea');
  String get includesTaxes => _p(
    'Includes taxes and fees collected by Flynoom.',
    'يشمل الضرائب والرسوم التي حصّلتها Flynoom.',
    'Incluye impuestos y cargos cobrados por Flynoom.',
  );
  String get paidWith => _p('Paid with', 'طريقة الدفع', 'Pagado con');
  String get cancellationFee => _p('Cancellation fee', 'رسوم الإلغاء', 'Cargo por cancelación');
  String get refunded => _p('Refunded to your card', 'المبلغ المسترد إلى بطاقتك', 'Reembolsado a tu tarjeta');
  String get cancelledOn => _p('Cancelled on', 'أُلغي في', 'Cancelada el');
  String get payableAtHotel => _p('Payable at the hotel', 'يُدفع في الفندق', 'A pagar en el hotel');
  String get payAtHotelNote => _p(
    'Not included in the amount paid online. Paid directly to the hotel.',
    'غير مشمول في المبلغ المدفوع عبر الموقع، ويُدفع للفندق مباشرة.',
    'No incluido en el importe pagado en línea. Se paga directamente al hotel.',
  );
  String get statementNote => _p(
    'The charge appears on your card statement as FLYNOOM.',
    'يظهر المبلغ في كشف بطاقتك باسم FLYNOOM.',
    'El cargo aparece en el extracto de tu tarjeta como FLYNOOM.',
  );
  String get printTip => _p(
    'Tip: on the website, press Ctrl+P to print or save this receipt as PDF.',
    'تلميح: على الموقع اضغط Ctrl+P لطباعة الإيصال أو حفظه بصيغة PDF.',
    'Consejo: en el sitio web, pulsa Ctrl+P para imprimir o guardar este recibo en PDF.',
  );

  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const _monthsEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];

  String date(DateTime d) {
    switch (lang) {
      case 'ar':
        return '${d.day} ${_monthsAr[d.month - 1]} ${d.year}';
      case 'es':
        return '${d.day} ${_monthsEs[d.month - 1]} ${d.year}';
      default:
        return '${_monthsEn[d.month - 1]} ${d.day}, ${d.year}';
    }
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary)),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  /// قيم إنجليزية/رقمية (المراجع، البريد، البطاقة) تُعرض من اليسار لليمين
  /// حتى لا تنقلب رموزها داخل صفحة عربية.
  final bool ltr;
  const _Row(this.label, this.value, {this.ltr = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool bold;
  final Color? color;
  const _AmountRow(this.label, this.amount, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(amount,
            // المبلغ والعملة يبقيان بالترتيب نفسه في كل اللغات: $161.44 USD
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 14,
              color: color,
            )),
      ],
    ),
  );
}