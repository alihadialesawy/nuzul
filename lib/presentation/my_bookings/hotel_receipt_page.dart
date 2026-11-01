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

/// نصوص الإيصال بلغة المستخدم (اللغات التسع).
/// ترتيب كل قائمة: [en, ar, es, tr, id, hi, ur, fr, bn].
class _ReceiptText {
  final String lang;
  const _ReceiptText(this.lang);

  static const _langs = ['en', 'ar', 'es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'];

  static _ReceiptText of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return _ReceiptText(_langs.contains(code) ? code : 'en');
  }

  String _p(List<String> v) => v[_langs.indexOf(lang)];

  String get receipt => _p(const [
    'Receipt', 'الإيصال', 'Recibo', 'Makbuz', 'Kuitansi', 'रसीद', 'رسید', 'Reçu', 'রসিদ',
  ]);
  String get paymentReceipt => _p(const [
    'Payment receipt', 'إيصال دفع', 'Recibo de pago', 'Ödeme makbuzu', 'Kuitansi pembayaran',
    'भुगतान रसीद', 'ادائیگی کی رسید', 'Reçu de paiement', 'পেমেন্টের রসিদ',
  ]);
  String get cancelledBadge => _p(const [
    'CANCELLED', 'ملغى', 'CANCELADA', 'İPTAL EDİLDİ', 'DIBATALKAN', 'रद्द', 'منسوخ', 'ANNULÉE', 'বাতিল',
  ]);
  String get flynoomRef => _p(const [
    'Flynoom reference', 'رقم Flynoom', 'Referencia Flynoom', 'Flynoom numarası', 'Kode Flynoom',
    'Flynoom नंबर', 'Flynoom نمبر', 'Référence Flynoom', 'Flynoom নম্বর',
  ]);
  String get bookingRef => _p(const [
    'Booking reference', 'رقم الحجز', 'Referencia de reserva', 'Rezervasyon numarası', 'Kode pemesanan',
    'बुकिंग नंबर', 'بکنگ نمبر', 'Référence de réservation', 'বুকিং নম্বর',
  ]);
  String get paymentDate => _p(const [
    'Payment date', 'تاريخ الدفع', 'Fecha de pago', 'Ödeme tarihi', 'Tanggal pembayaran',
    'भुगतान तिथि', 'تاریخِ ادائیگی', 'Date de paiement', 'পেমেন্টের তারিখ',
  ]);
  String get paidBy => _p(const [
    'Paid by', 'الدافع', 'Pagado por', 'Ödeyen', 'Dibayar oleh', 'भुगतानकर्ता', 'ادا کنندہ', 'Payé par',
    'পরিশোধকারী',
  ]);
  String get email => _p(const [
    'Email', 'البريد الإلكتروني', 'Correo', 'E-posta', 'Email', 'ईमेल', 'ای میل', 'E-mail', 'ইমেইল',
  ]);
  String get stay => _p(const [
    'Stay', 'الإقامة', 'Estancia', 'Konaklama', 'Menginap', 'ठहराव', 'قیام', 'Séjour', 'থাকা',
  ]);
  String get hotel => _p(const [
    'Hotel', 'الفندق', 'Hotel', 'Otel', 'Hotel', 'होटल', 'ہوٹل', 'Hôtel', 'হোটেল',
  ]);
  String get dates => _p(const [
    'Dates', 'التواريخ', 'Fechas', 'Tarihler', 'Tanggal', 'तारीखें', 'تاریخیں', 'Dates', 'তারিখ',
  ]);
  String get nights => _p(const [
    'Nights', 'عدد الليالي', 'Noches', 'Gece sayısı', 'Jumlah malam', 'रातें', 'راتیں', 'Nuits', 'রাত',
  ]);
  String get room => _p(const [
    'Room', 'الغرفة', 'Habitación', 'Oda', 'Kamar', 'कमरा', 'کمرہ', 'Chambre', 'রুম',
  ]);
  String get payment => _p(const [
    'Payment', 'الدفع', 'Pago', 'Ödeme', 'Pembayaran', 'भुगतान', 'ادائیگی', 'Paiement', 'পেমেন্ট',
  ]);
  String get totalPaid => _p(const [
    'Total paid online', 'المبلغ المدفوع عبر الموقع', 'Total pagado en línea', 'Çevrim içi ödenen toplam',
    'Total dibayar online', 'ऑनलाइन भुगतान की कुल राशि', 'آن لائن ادا کی گئی کل رقم', 'Total payé en ligne',
    'অনলাইনে মোট পরিশোধ',
  ]);
  String get includesTaxes => _p(const [
    'Includes taxes and fees collected by Flynoom.',
    'يشمل الضرائب والرسوم التي حصّلتها Flynoom.',
    'Incluye impuestos y cargos cobrados por Flynoom.',
    'Flynoom tarafından tahsil edilen vergi ve ücretler dahildir.',
    'Termasuk pajak dan biaya yang ditagih oleh Flynoom.',
    'Flynoom द्वारा लिए गए कर और शुल्क शामिल हैं।',
    'Flynoom کی وصول کردہ ٹیکس اور فیس شامل ہیں۔',
    'Comprend les taxes et frais perçus par Flynoom.',
    'Flynoom-এর আদায় করা কর ও ফি অন্তর্ভুক্ত।',
  ]);
  String get paidWith => _p(const [
    'Paid with', 'طريقة الدفع', 'Pagado con', 'Ödeme yöntemi', 'Dibayar dengan', 'भुगतान का तरीका',
    'ادائیگی کا طریقہ', 'Payé avec', 'পরিশোধের মাধ্যম',
  ]);
  String get cancellationFee => _p(const [
    'Cancellation fee', 'رسوم الإلغاء', 'Cargo por cancelación', 'İptal ücreti', 'Biaya pembatalan',
    'रद्दीकरण शुल्क', 'منسوخی فیس', 'Frais d\'annulation', 'বাতিল ফি',
  ]);
  String get refunded => _p(const [
    'Refunded to your card', 'المبلغ المسترد إلى بطاقتك', 'Reembolsado a tu tarjeta', 'Kartınıza iade edilen',
    'Dikembalikan ke kartu Anda', 'आपके कार्ड में वापस', 'آپ کے کارڈ میں واپس', 'Remboursé sur votre carte',
    'আপনার কার্ডে ফেরত',
  ]);
  String get cancelledOn => _p(const [
    'Cancelled on', 'أُلغي في', 'Cancelada el', 'İptal tarihi:', 'Dibatalkan pada', 'रद्द करने की तिथि:',
    'منسوخی کی تاریخ:', 'Annulée le', 'বাতিলের তারিখ:',
  ]);
  String get payableAtHotel => _p(const [
    'Payable at the hotel', 'يُدفع في الفندق', 'A pagar en el hotel', 'Otelde ödenecek', 'Dibayar di hotel',
    'होटल में देय', 'ہوٹل میں قابلِ ادائیگی', 'À payer à l\'hôtel', 'হোটেলে প্রদেয়',
  ]);
  String get payAtHotelNote => _p(const [
    'Not included in the amount paid online. Paid directly to the hotel.',
    'غير مشمول في المبلغ المدفوع عبر الموقع، ويُدفع للفندق مباشرة.',
    'No incluido en el importe pagado en línea. Se paga directamente al hotel.',
    'Çevrim içi ödenen tutara dahil değildir. Doğrudan otele ödenir.',
    'Tidak termasuk dalam jumlah yang dibayar online. Dibayar langsung ke hotel.',
    'ऑनलाइन भुगतान की गई राशि में शामिल नहीं। सीधे होटल को दिया जाता है।',
    'آن لائن ادا کی گئی رقم میں شامل نہیں۔ براہِ راست ہوٹل کو ادا کی جاتی ہے۔',
    'Non inclus dans le montant payé en ligne. À régler directement à l\'hôtel.',
    'অনলাইনে পরিশোধিত অর্থে অন্তর্ভুক্ত নয়। সরাসরি হোটেলে দিতে হয়।',
  ]);
  String get statementNote => _p(const [
    'The charge appears on your card statement as FLYNOOM.',
    'يظهر المبلغ في كشف بطاقتك باسم FLYNOOM.',
    'El cargo aparece en el extracto de tu tarjeta como FLYNOOM.',
    'Ödeme, kart ekstrenizde FLYNOOM olarak görünür.',
    'Tagihan muncul di laporan kartu Anda sebagai FLYNOOM.',
    'यह शुल्क आपके कार्ड स्टेटमेंट में FLYNOOM के नाम से दिखता है।',
    'یہ رقم آپ کے کارڈ اسٹیٹمنٹ میں FLYNOOM کے نام سے نظر آتی ہے۔',
    'Le débit apparaît sur votre relevé de carte sous le nom FLYNOOM.',
    'চার্জটি আপনার কার্ড স্টেটমেন্টে FLYNOOM নামে দেখা যায়।',
  ]);
  String get printTip => _p(const [
    'Tip: on the website, press Ctrl+P to print or save this receipt as PDF.',
    'تلميح: على الموقع اضغط Ctrl+P لطباعة الإيصال أو حفظه بصيغة PDF.',
    'Consejo: en el sitio web, pulsa Ctrl+P para imprimir o guardar este recibo en PDF.',
    'İpucu: web sitesinde bu makbuzu yazdırmak veya PDF olarak kaydetmek için Ctrl+P\'ye basın.',
    'Tips: di situs web, tekan Ctrl+P untuk mencetak atau menyimpan kuitansi ini sebagai PDF.',
    'सुझाव: वेबसाइट पर इस रसीद को प्रिंट करने या PDF के रूप में सहेजने के लिए Ctrl+P दबाएँ।',
    'مشورہ: ویب سائٹ پر اس رسید کو پرنٹ کرنے یا PDF کے طور پر محفوظ کرنے کے لیے Ctrl+P دبائیں۔',
    'Astuce : sur le site, appuyez sur Ctrl+P pour imprimer ou enregistrer ce reçu en PDF.',
    'টিপ: ওয়েবসাইটে এই রসিদ প্রিন্ট বা PDF হিসেবে সংরক্ষণ করতে Ctrl+P চাপুন।',
  ]);

  static const _months = <String, List<String>>{
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'ar': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
    'es': ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'],
    'tr': ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'],
    'id': ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'],
    'hi': ['जन॰', 'फ़र॰', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुल॰', 'अग॰', 'सित॰', 'अक्तू॰', 'नव॰', 'दिस॰'],
    'ur': ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'],
    'fr': ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
    'bn': ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'],
  };

  /// الإنجليزية: Oct 31, 2026 — باقي اللغات: 31 <الشهر> 2026.
  String date(DateTime d) {
    final m = _months[lang]![d.month - 1];
    return lang == 'en' ? '$m ${d.day}, ${d.year}' : '${d.day} $m ${d.year}';
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