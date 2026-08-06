import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/booking_model.dart';
import 'controllers/admin_bookings_controller.dart';

String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    default:
      return en;
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'pending':
    default:
      return Colors.orange;
  }
}

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case 'confirmed':
      return _t3(context, ar: 'مؤكد', en: 'Confirmed', es: 'Confirmada');
    case 'cancelled':
      return _t3(context, ar: 'ملغي', en: 'Cancelled', es: 'Cancelada');
    case 'pending':
    default:
      return _t3(context, ar: 'قيد الانتظار', en: 'Pending', es: 'Pendiente');
  }
}

/// شاشة إدارة الحجوزات: تبويبات (الكل/فنادق/طيران/سيارات) + بحث + فلتر
/// حالة، مع بيانات الزبون وتاريخ الحجز وتاريخ الخدمة (تشيك إن/آوت) لكل صف.
/// ملاحظة: تبويبي "طيران" و"تأجير سيارات" لسه Coming soon لحد ما تتوفر
/// موديلات/repositories الحجز الخاصة فيهم.
class AdminBookingsPage extends ConsumerStatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  ConsumerState<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends ConsumerState<AdminBookingsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  List<BookingModel> _applyFilters(List<BookingModel> bookings) {
    return bookings.where((b) {
      final matchesStatus = _statusFilter == 'all' || b.status == _statusFilter;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          (b.customerName?.toLowerCase().contains(query) ?? false) ||
          b.id.toLowerCase().contains(query) ||
          (b.hotelName?.toLowerCase().contains(query) ?? false);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(adminBookingsListProvider);

    return Scaffold(
      appBar: AppBanner(
        tabsBar: Row(
          children: [
            Expanded(
              child: Text(
                _t3(context, ar: 'إدارة الحجوزات', en: 'Manage Bookings', es: 'Gestionar Reservas'),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: _t3(context, ar: 'تحديث', en: 'Refresh', es: 'Actualizar'),
              onPressed: () => ref.invalidate(adminBookingsListProvider),
            ),
          ],
        ),
        bannerHeight: 160,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryDark,
            indicatorColor: AppColors.primaryDark,
            tabs: [
              Tab(text: _t3(context, ar: 'الكل', en: 'All', es: 'Todo')),
              Tab(text: _t3(context, ar: 'الفنادق', en: 'Hotels', es: 'Hoteles')),
              Tab(text: _t3(context, ar: 'الطيران', en: 'Flights', es: 'Vuelos')),
              Tab(text: _t3(context, ar: 'تأجير السيارات', en: 'Car Rentals', es: 'Alquiler de coches')),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHotelBookingsTab(context, bookingsAsync),
                _buildHotelBookingsTab(context, bookingsAsync),
                _buildComingSoonTab(context),
                _buildComingSoonTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab(BuildContext context) {
    return Center(
      child: Text(
        _t3(context, ar: 'قريبًا', en: 'Coming soon', es: 'Próximamente'),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    );
  }

  Widget _buildHotelBookingsTab(BuildContext context, AsyncValue<List<BookingModel>> bookingsAsync) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSearch,
                  ),
                  hintText: _t3(
                    context,
                    ar: 'بحث باسم الزبون أو رقم الحجز أو اسم الفندق',
                    en: 'Search by customer name, booking ID, or hotel name',
                    es: 'Buscar por cliente, ID de reserva u hotel',
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Text(_t3(context, ar: 'الحالة:', en: 'Status:', es: 'Estado:')),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusFilterChip(
                            label: _t3(context, ar: 'الكل', en: 'All', es: 'Todo'),
                            value: 'all',
                            groupValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          _StatusFilterChip(
                            label: _statusLabel(context, 'pending'),
                            value: 'pending',
                            groupValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          _StatusFilterChip(
                            label: _statusLabel(context, 'confirmed'),
                            value: 'confirmed',
                            groupValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                          _StatusFilterChip(
                            label: _statusLabel(context, 'cancelled'),
                            value: 'cancelled',
                            groupValue: _statusFilter,
                            onSelected: (v) => setState(() => _statusFilter = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: bookingsAsync.when(
            loading: () => LoadingView(
              message: _t3(context, ar: 'يحمّل الحجوزات...', en: 'Loading bookings...', es: 'Cargando reservas...'),
            ),
            error: (error, _) => ErrorView(
              message: _t3(
                context,
                ar: 'تعذر تحميل الحجوزات',
                en: 'Could not load bookings',
                es: 'No se pudieron cargar las reservas',
              ),
              onRetry: () => ref.invalidate(adminBookingsListProvider),
            ),
            data: (bookings) {
              final filtered = _applyFilters(bookings);
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    _t3(context, ar: 'ما فيه حجوزات مطابقة', en: 'No matching bookings', es: 'No hay reservas coincidentes'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSizes.md),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                itemBuilder: (context, index) {
                  final booking = filtered[index];
                  return _BookingTile(
                    booking: booking,
                    onTap: () => _showBookingDetails(context, booking),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => _BookingDetailsDialog(booking: booking),
    ).then((changed) {
      if (changed == true) {
        ref.invalidate(adminBookingsListProvider);
      }
    });
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
        selectedColor: AppColors.primaryDark,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _BookingTile({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (booking.hotelImages?.isNotEmpty ?? false)
                  ? Image.network(
                booking.hotelImages!.first,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.background,
                  child: const Icon(Icons.hotel_outlined),
                ),
              )
                  : Container(
                width: 56,
                height: 56,
                color: AppColors.background,
                child: const Icon(Icons.hotel_outlined),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.customerName ?? _t3(context, ar: 'زبون غير معروف', en: 'Unknown customer', es: 'Cliente desconocido'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(booking.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(context, booking.status),
                          style: TextStyle(color: _statusColor(booking.status), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.hotelName ?? '-'} · ${booking.hotelCity ?? '-'}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t3(
                      context,
                      ar: 'الإقامة: ${_formatDate(booking.checkIn)} → ${_formatDate(booking.checkOut)}',
                      en: 'Stay: ${_formatDate(booking.checkIn)} → ${_formatDate(booking.checkOut)}',
                      es: 'Estancia: ${_formatDate(booking.checkIn)} → ${_formatDate(booking.checkOut)}',
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  if (booking.createdAt != null)
                    Text(
                      _t3(
                        context,
                        ar: 'تاريخ الحجز: ${_formatDate(booking.createdAt!)}',
                        en: 'Booked on: ${_formatDate(booking.createdAt!)}',
                        es: 'Reservado el: ${_formatDate(booking.createdAt!)}',
                      ),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              '\$${booking.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingDetailsDialog extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _BookingDetailsDialog({required this.booking});

  @override
  ConsumerState<_BookingDetailsDialog> createState() => _BookingDetailsDialogState();
}

class _BookingDetailsDialogState extends ConsumerState<_BookingDetailsDialog> {
  bool _updating = false;

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _updating = true);
    final repo = ref.read(adminBookingRepositoryProvider);
    final result = await repo.updateBookingStatus(widget.booking.id, newStatus);
    if (!mounted) return;
    setState(() => _updating = false);

    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (message) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return AlertDialog(
      title: Text(_t3(context, ar: 'تفاصيل الحجز', en: 'Booking details', es: 'Detalles de la reserva')),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(label: _t3(context, ar: 'رقم الحجز', en: 'Booking ID', es: 'ID de reserva'), value: booking.id),
            _DetailRow(
              label: _t3(context, ar: 'الزبون', en: 'Customer', es: 'Cliente'),
              value: booking.customerName ?? '-',
            ),
            if (booking.customerPhone != null)
              _DetailRow(label: _t3(context, ar: 'الهاتف', en: 'Phone', es: 'Teléfono'), value: booking.customerPhone!),
            _DetailRow(label: _t3(context, ar: 'الفندق', en: 'Hotel', es: 'Hotel'), value: '${booking.hotelName ?? '-'} (${booking.hotelCity ?? '-'})'),
            _DetailRow(
              label: _t3(context, ar: 'تاريخ الوصول', en: 'Check-in', es: 'Entrada'),
              value: _formatDate(booking.checkIn),
            ),
            _DetailRow(
              label: _t3(context, ar: 'تاريخ المغادرة', en: 'Check-out', es: 'Salida'),
              value: _formatDate(booking.checkOut),
            ),
            _DetailRow(label: _t3(context, ar: 'عدد الضيوف', en: 'Guests', es: 'Huéspedes'), value: '${booking.guests}'),
            _DetailRow(
              label: _t3(context, ar: 'السعر الإجمالي', en: 'Total price', es: 'Precio total'),
              value: '\$${booking.totalPrice.toStringAsFixed(2)}',
            ),
            if (booking.createdAt != null)
              _DetailRow(
                label: _t3(context, ar: 'تاريخ إنشاء الحجز', en: 'Booking created', es: 'Reserva creada'),
                value: _formatDate(booking.createdAt!),
              ),
            _DetailRow(
              label: _t3(context, ar: 'الحالة الحالية', en: 'Current status', es: 'Estado actual'),
              value: _statusLabel(context, booking.status),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _updating ? null : () => Navigator.of(context).pop(false),
          child: Text(_t3(context, ar: 'إغلاق', en: 'Close', es: 'Cerrar')),
        ),
        if (booking.status != 'confirmed')
          TextButton(
            onPressed: _updating ? null : () => _changeStatus('confirmed'),
            child: Text(_t3(context, ar: 'تأكيد', en: 'Confirm', es: 'Confirmar'), style: const TextStyle(color: Colors.green)),
          ),
        if (booking.status != 'cancelled')
          TextButton(
            onPressed: _updating ? null : () => _changeStatus('cancelled'),
            child: Text(_t3(context, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar'), style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}