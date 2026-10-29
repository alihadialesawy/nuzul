import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/booking_model.dart';

/// وثائق FLYNOOM بصيغة PDF: الفاتورة، والإيصال، والقسيمة، والتقرير المالي.
///
/// لماذا PDF وليس Ctrl+P؟ Flutter Web يطبع غالبًا الجزء الظاهر من الشاشة فقط،
/// أما ملف PDF فيُطبع أو يُحفظ كاملًا ومرتبًا على الويب و Android.
///
/// الوثائق بالإنجليزية عمدًا (اللغة المعتادة للوثائق المحاسبية في أمريكا).
/// الخطوط: Noto Sans (من Google Fonts عبر حزمة printing) مع خط عربي احتياطي
/// حتى تظهر أسماء العملاء العربية صحيحة. لو تعذّر تحميل الخطوط نستخدم الخط الافتراضي.
class FlynoomPdf {
  FlynoomPdf._();

  static const _company = 'FLYNOOM LLC';
  static const _companyLines = ['Livonia, Michigan, USA', 'flynoom.com · support@flynoom.com'];

  static const _navy = PdfColor.fromInt(0xFF0B3A6B);
  static const _orange = PdfColor.fromInt(0xFFF7931E);
  static const _grey = PdfColor.fromInt(0xFF6B7280);
  static const _light = PdfColor.fromInt(0xFFF3F4F6);
  static const _red = PdfColor.fromInt(0xFFB91C1C);
  static const _green = PdfColor.fromInt(0xFF15803D);

  static final _money = NumberFormat('#,##0.00', 'en_US');
  static final _day = DateFormat('MMM d, yyyy', 'en_US');
  static final _dayTime = DateFormat('MMM d, yyyy HH:mm', 'en_US');

  static String usd(num? v) => v == null ? '—' : '\$${_money.format(v)}';

  // ───────────────────────── الأساسيات ─────────────────────────

  static pw.ThemeData? _theme;
  static pw.MemoryImage? _logo;

  static Future<pw.ThemeData> _loadTheme() async {
    if (_theme != null) return _theme!;
    try {
      final base = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      final arabic = await PdfGoogleFonts.notoNaskhArabicRegular();
      _theme = pw.ThemeData.withFont(base: base, bold: bold, fontFallback: [arabic]);
    } catch (_) {
      _theme = pw.ThemeData.base();
    }
    return _theme!;
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    if (_logo != null) return _logo;
    try {
      final data = await rootBundle.load('assets/images/logo_flynoom_dark.png');
      _logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}
    return _logo;
  }

  static pw.Widget _brand(pw.MemoryImage? logo) => logo != null
      ? pw.Image(logo, height: 30)
      : pw.Text('FLYNOOM',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _navy, letterSpacing: 2));

  static pw.Widget _label(String s) =>
      pw.Text(s.toUpperCase(), style: pw.TextStyle(fontSize: 8, color: _grey, letterSpacing: 1, fontWeight: pw.FontWeight.bold));

  static pw.Widget _kv(String k, String v, {bool bold = false, PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(width: 120, child: pw.Text(k, style: const pw.TextStyle(fontSize: 9, color: _grey))),
          pw.Expanded(
            child: pw.Text(v,
                style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : null, color: color)),
          ),
        ]),
      );

  static pw.Widget _footer(pw.Context ctx, String note) => pw.Column(children: [
        pw.Divider(color: _light),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(note, style: const pw.TextStyle(fontSize: 7, color: _grey)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: _grey)),
        ]),
      ]);

  static int _nights(BookingModel b) => b.checkOut.difference(b.checkIn).inDays;

  static String _title(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

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
      default:
        return (b ?? '').isEmpty ? 'Card' : b![0].toUpperCase() + b.substring(1);
    }
  }

  // ───────────────────────── الفاتورة / الإيصال ─────────────────────────

  /// [receipt] = true → "Payment receipt"، false → "Invoice".
  static Future<Uint8List> invoice(BookingModel b, {bool receipt = false}) async {
    final theme = await _loadTheme();
    final logo = await _loadLogo();
    final doc = pw.Document(theme: theme, title: '${receipt ? 'Receipt' : 'Invoice'} ${b.clientReference ?? ''}');

    final paid = b.chargeAmount ?? 0;
    final cancelled = b.status == 'cancelled';
    final refund = cancelled ? (b.refundAmount ?? 0) : 0.0;
    final fee = cancelled ? (b.cancellationFee ?? (paid - refund)).clamp(0, paid).toDouble() : 0.0;
    final net = paid - refund;
    final number = '${receipt ? 'RCT' : 'INV'}-${b.clientReference ?? b.id.substring(0, 8).toUpperCase()}';
    final issued = (b.createdAt ?? DateTime.now()).toLocal();

    String statusText;
    PdfColor statusColor;
    if (!cancelled) {
      statusText = 'PAID';
      statusColor = _green;
    } else if (refund >= paid && paid > 0) {
      statusText = 'CANCELLED · REFUNDED';
      statusColor = _red;
    } else if (refund > 0) {
      statusText = 'CANCELLED · PARTIALLY REFUNDED';
      statusColor = _red;
    } else {
      statusText = 'CANCELLED · NO REFUND';
      statusColor = _red;
    }

    final rooms = b.voucherRooms;
    final roomLine = rooms.isNotEmpty
        ? rooms.map((r) => '${r.rooms} × ${_title(r.name)}${r.boardName != null ? ' · ${_title(r.boardName!)}' : ''}').join('\n')
        : [b.roomName, b.boardName].whereType<String>().where((s) => s.isNotEmpty).map(_title).join(' · ');

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      footer: (ctx) => _footer(ctx, '$_company · $number'),
      build: (ctx) => [
        // ── الرأس ──
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _brand(logo),
              pw.SizedBox(height: 6),
              pw.Text(_company, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              for (final l in _companyLines) pw.Text(l, style: const pw.TextStyle(fontSize: 9, color: _grey)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(receipt ? 'PAYMENT RECEIPT' : 'INVOICE',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _navy)),
              pw.SizedBox(height: 4),
              pw.Text(number, style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Date: ${_day.format(issued)}', style: const pw.TextStyle(fontSize: 9, color: _grey)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: statusColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text(statusText, style: pw.TextStyle(fontSize: 8, color: statusColor, fontWeight: pw.FontWeight.bold)),
              ),
            ]),
          ],
        ),
        pw.SizedBox(height: 24),

        // ── العميل والحجز ──
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _label(receipt ? 'Received from' : 'Bill to'),
              pw.SizedBox(height: 4),
              pw.Text(b.holderFullName.isEmpty ? '—' : b.holderFullName,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              if ((b.holderEmail ?? '').isNotEmpty) pw.Text(b.holderEmail!, style: const pw.TextStyle(fontSize: 9)),
              if ((b.holderPhone ?? '').isNotEmpty) pw.Text(b.holderPhone!, style: const pw.TextStyle(fontSize: 9)),
            ]),
          ),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _label('Booking'),
              pw.SizedBox(height: 4),
              _kv('Flynoom reference', b.clientReference ?? '—'),
              _kv('Hotel booking ref.', b.supplierReference ?? '—'),
              if (b.cardLast4 != null) _kv('Paid with', '${_cardBrand(b.cardBrand)} •••• ${b.cardLast4}'),
            ]),
          ),
        ]),
        pw.SizedBox(height: 20),

        // ── البنود ──
        pw.Table(
          border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _light)),
          columnWidths: const {
            0: pw.FlexColumnWidth(5),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _light),
              children: [
                for (final h in ['Description', 'Dates', 'Nights', 'Amount (USD)'])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        textAlign: h.startsWith('Amount') ? pw.TextAlign.right : pw.TextAlign.left,
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
              ],
            ),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Hotel accommodation — ${b.hotelName ?? ''}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  if ((b.hotelCity ?? '').isNotEmpty) pw.Text(b.hotelCity!, style: const pw.TextStyle(fontSize: 8, color: _grey)),
                  if (roomLine.isNotEmpty) pw.Text(roomLine, style: const pw.TextStyle(fontSize: 8, color: _grey)),
                ]),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('${_day.format(b.checkIn)} – ${_day.format(b.checkOut)}', style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('${_nights(b)}', style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(usd(paid), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9)),
              ),
            ]),
          ],
        ),
        pw.SizedBox(height: 12),

        // ── المجاميع ──
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 260,
            child: pw.Column(children: [
              _totalRow('Total (taxes and fees included)', usd(paid), bold: !cancelled),
              _totalRow(receipt ? 'Amount received' : 'Amount paid', usd(paid)),
              if (cancelled) ...[
                _totalRow('Cancellation fee', usd(fee)),
                _totalRow('Refunded to card', '−${usd(refund)}', color: _green),
                pw.Divider(color: _grey, height: 8),
                _totalRow('Net amount charged', usd(net), bold: true),
              ] else ...[
                pw.Divider(color: _grey, height: 8),
                _totalRow('Balance due', usd(0), bold: true),
              ],
            ]),
          ),
        ),
        pw.SizedBox(height: 16),

        if (cancelled && b.cancelledAt != null)
          pw.Text(
            'Booking cancelled on ${_dayTime.format(b.cancelledAt!.toLocal())}'
            '${b.cancellationReference != null ? ' (cancellation ref. ${b.cancellationReference})' : ''}.',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),

        if (b.payAtHotelFees.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _label('Payable at the hotel (not included above)'),
          pw.SizedBox(height: 3),
          for (final f in b.payAtHotelFees)
            pw.Text(
              '${_title((f['type'] ?? 'Fee').toString())}: ${((f['amount'] as num?) ?? 0).toStringAsFixed(2)} ${f['currency'] ?? ''}',
              style: const pw.TextStyle(fontSize: 8),
            ),
        ],

        pw.SizedBox(height: 24),
        pw.Text(
          'Prices include taxes and fees collected by Flynoom. The charge appears on the card statement as FLYNOOM. '
          'Questions? support@flynoom.com',
          style: const pw.TextStyle(fontSize: 8, color: _grey),
        ),
      ],
    ));

    return doc.save();
  }

  static pw.Widget _totalRow(String k, String v, {bool bold = false, PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(k, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : null))),
          pw.Text(v, style: pw.TextStyle(fontSize: bold ? 11 : 9, fontWeight: bold ? pw.FontWeight.bold : null, color: color)),
        ]),
      );

  // ───────────────────────── القسيمة ─────────────────────────

  static Future<Uint8List> voucher(BookingModel b) async {
    final theme = await _loadTheme();
    final logo = await _loadLogo();
    final doc = pw.Document(theme: theme, title: 'Voucher ${b.supplierReference ?? ''}');
    final rooms = b.voucherRooms;
    final roomComments = rooms.map((r) => r.rateComments).whereType<String>().where((c) => c.trim().isNotEmpty).toSet();
    final comments = roomComments.isNotEmpty ? roomComments.join('\n\n') : (b.rateComments ?? '');
    final cancelled = b.status == 'cancelled';

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      footer: (ctx) => _footer(ctx, 'Booked by $_company · flynoom.com'),
      build: (ctx) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _brand(logo),
            pw.SizedBox(height: 4),
            pw.Text('Hotel booking voucher', style: const pw.TextStyle(fontSize: 10, color: _grey)),
          ]),
          if (cancelled)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _red), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Text('CANCELLED', style: pw.TextStyle(color: _red, fontWeight: pw.FontWeight.bold)),
            ),
        ]),
        pw.Divider(color: _orange, thickness: 2),
        pw.SizedBox(height: 6),
        _kv('Booking reference', b.supplierReference ?? '—', bold: true),
        _kv('Flynoom reference', b.clientReference ?? '—'),
        if (cancelled && b.cancellationReference != null) _kv('Cancellation reference', b.cancellationReference!),
        pw.SizedBox(height: 12),
        _label('Hotel'),
        pw.SizedBox(height: 3),
        pw.Text(b.hotelName ?? '', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        if (b.hotelAddress != null) pw.Text(b.hotelAddress!, style: const pw.TextStyle(fontSize: 9)),
        if (b.hotelAddress == null && b.hotelCity != null) pw.Text(b.hotelCity!, style: const pw.TextStyle(fontSize: 9)),
        if (b.hotelPhone != null) pw.Text('Phone: ${b.hotelPhone}', style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 12),
        _label('Stay'),
        pw.SizedBox(height: 3),
        _kv('Check-in', DateFormat('EEE, MMM d, yyyy', 'en_US').format(b.checkIn)),
        _kv('Check-out', DateFormat('EEE, MMM d, yyyy', 'en_US').format(b.checkOut)),
        _kv('Nights', '${_nights(b)}'),
        _kv('Lead guest', b.holderFullName.isEmpty ? '—' : b.holderFullName),
        pw.SizedBox(height: 12),
        _label('Rooms'),
        pw.SizedBox(height: 3),
        if (rooms.isEmpty)
          pw.Text([b.roomName, b.boardName].whereType<String>().map(_title).join(' · '), style: const pw.TextStyle(fontSize: 9)),
        for (final r in rooms)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('${r.rooms} × ${_title(r.name)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              if (r.boardName != null) pw.Text('Board: ${_title(r.boardName!)}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                'Guests per room: ${r.adults} adult${r.adults == 1 ? '' : 's'}'
                '${r.children > 0 ? ', ${r.children} child${r.children == 1 ? '' : 'ren'}' : ''}'
                '${r.childAges.isNotEmpty ? ' (ages ${r.childAges.join(', ')})' : ''}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ]),
          ),
        if (b.payAtHotelFees.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _label('Payable at the hotel'),
          for (final f in b.payAtHotelFees)
            pw.Text(
              '${_title((f['type'] ?? 'Fee').toString())}: ${((f['amount'] as num?) ?? 0).toStringAsFixed(2)} ${f['currency'] ?? ''}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.Text('Mandatory fees not included in the amount paid online.', style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ],
        if (comments.trim().isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _label('Important information'),
          pw.SizedBox(height: 3),
          pw.Text(comments.trim(), style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ],
        pw.SizedBox(height: 14),
        pw.Divider(color: _light),
        // العبارة الإلزامية من HotelBeds.
        pw.Text(
          'Payable through ${b.supplierName ?? 'HOTELBEDS'}, acting as agent for the service operating company, '
          'details of which can be provided upon request. VAT: ${b.supplierVat ?? '—'} Reference: ${b.supplierReference ?? '—'}',
          style: const pw.TextStyle(fontSize: 8, color: _grey),
        ),
      ],
    ));
    return doc.save();
  }

  // ───────────────────────── التقرير المالي ─────────────────────────

  static const reportColumns = [
    'Date', 'Flynoom ref', 'Hotel', 'City', 'Status', 'Paid', 'Refunded', 'Kept', 'Hotel cost', 'Stripe fee*', 'Profit*',
  ];

  static List<String> _reportCells(Map<String, dynamic> r) {
    String m(dynamic v) => v == null ? '—' : _money.format((v as num).toDouble());
    final created = DateTime.tryParse('${r['created_at']}')?.toLocal();
    return [
      created == null ? '' : DateFormat('yyyy-MM-dd').format(created),
      '${r['client_reference'] ?? ''}',
      '${r['hotel_name'] ?? ''}',
      '${r['hotel_city'] ?? ''}',
      '${r['status'] ?? ''}',
      m(r['paid']),
      m(r['refunded']),
      m(r['kept']),
      m(r['cost']),
      m(r['fee']),
      m(r['profit']),
    ];
  }

  static Future<Uint8List> financialReport({
    required String periodLabel,
    required Map<String, dynamic> data,
  }) async {
    final theme = await _loadTheme();
    final logo = await _loadLogo();
    final rows = ((data['rows'] as List?) ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    final s = Map<String, dynamic>.from((data['summary'] as Map?) ?? const {});
    final byCity = ((data['by_city'] as List?) ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    final doc = pw.Document(theme: theme, title: 'Financial report $periodLabel');

    pw.Widget box(String k, dynamic v, {bool money = true}) => pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 6),
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(color: _light),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(k, style: const pw.TextStyle(fontSize: 7, color: _grey)),
              pw.Text(money ? usd(v as num?) : '${v ?? 0}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
        );

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(28),
      footer: (ctx) => _footer(
        ctx,
        '$_company · Management report generated ${_dayTime.format(DateTime.now())} · '
        '*Stripe fees are estimated (2.9% + \$0.30). Use Stripe and HotelBeds statements as the official records.',
      ),
      build: (ctx) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          _brand(logo),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('FINANCIAL REPORT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _navy)),
            pw.Text(periodLabel, style: const pw.TextStyle(fontSize: 10)),
          ]),
        ]),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          box('Bookings', s['bookings'], money: false),
          box('Gross sales', s['gross_sales']),
          box('Refunds', s['refunds']),
          box('Net revenue', s['net_revenue']),
          box('Hotel cost (HotelBeds)', s['supplier_cost']),
          box('Stripe fees*', s['stripe_fees_est']),
          box('Profit*', s['profit_est']),
        ]),
        if ((s['unknown_cost_count'] ?? 0) as num > 0)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '${s['unknown_cost_count']} booking(s) have no recorded hotel cost and are excluded from profit.',
              style: const pw.TextStyle(fontSize: 7, color: _red),
            ),
          ),
        pw.SizedBox(height: 10),
        if (rows.isEmpty)
          pw.Text('No bookings in this period.', style: const pw.TextStyle(fontSize: 10, color: _grey))
        else
          pw.TableHelper.fromTextArray(
            headers: reportColumns,
            data: rows.map(_reportCells).toList(),
            headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: _light),
            cellAlignments: {for (var i = 5; i < reportColumns.length; i++) i: pw.Alignment.centerRight},
            border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _light, width: 0.5)),
          ),
        if (byCity.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _label('By city'),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: const ['City', 'Bookings', 'Net revenue', 'Hotel cost'],
            data: byCity
                .map((c) => ['${c['city']}', '${c['bookings']}', usd(c['net_revenue'] as num?), usd(c['supplier_cost'] as num?)])
                .toList(),
            headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: _light),
            cellAlignments: const {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          ),
        ],
      ],
    ));
    return doc.save();
  }

  /// نفس بيانات التقرير بصيغة CSV (يُفتح في Excel). مع BOM حتى تظهر الأحرف الخاصة صحيحة.
  static Uint8List financialReportCsv(Map<String, dynamic> data) {
    final rows = ((data['rows'] as List?) ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    String raw(dynamic v) => v == null ? '' : (v as num).toStringAsFixed(2);
    final b = StringBuffer()
      ..writeln([
        'Date', 'Flynoom ref', 'HotelBeds ref', 'Hotel', 'City', 'Check-in', 'Check-out', 'Guest', 'Status',
        'Paid', 'Refunded', 'Kept', 'Hotel cost', 'Stripe fee (est.)', 'Profit (est.)', 'Markup %',
      ].map(esc).join(','));
    for (final r in rows) {
      final created = DateTime.tryParse('${r['created_at']}')?.toLocal();
      b.writeln([
        esc(created == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(created)),
        esc('${r['client_reference'] ?? ''}'),
        esc('${r['supplier_reference'] ?? ''}'),
        esc('${r['hotel_name'] ?? ''}'),
        esc('${r['hotel_city'] ?? ''}'),
        esc('${r['check_in'] ?? ''}'),
        esc('${r['check_out'] ?? ''}'),
        esc('${r['guest'] ?? ''}'),
        esc('${r['status'] ?? ''}'),
        raw(r['paid']),
        raw(r['refunded']),
        raw(r['kept']),
        raw(r['cost']),
        raw(r['fee']),
        raw(r['profit']),
        r['markup_pct'] == null ? '' : '${r['markup_pct']}',
      ].join(','));
    }
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(b.toString())]);
  }

  // ───────────────────────── العرض ─────────────────────────

  /// يفتح نافذة الطباعة (ومنها: "Save as PDF").
  static Future<void> printBytes(Uint8List bytes, String name) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: name);

  /// يحفظ الملف (تنزيل على الويب، مشاركة على Android).
  static Future<void> saveBytes(Uint8List bytes, String filename) =>
      Printing.sharePdf(bytes: bytes, filename: filename);
}