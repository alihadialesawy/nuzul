import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/hotel_model.dart';
import 'controllers/admin_hotels_controller.dart';

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

const List<String> _propertyTypes = [
  'Hotels',
  'Apartments',
  'Resorts',
  'Villas',
  'Hostels',
];

/// شاشة إدارة الفنادق: قائمة كل الفنادق مع إمكانية إضافة فندق جديد،
/// تعديل فندق موجود، أو حذفه.
class AdminHotelsPage extends ConsumerWidget {
  const AdminHotelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(adminHotelsListProvider);

    return Scaffold(
      appBar: AppBanner(
        tabsBar: Text(
          _t3(context, ar: 'إدارة الفنادق', en: 'Manage Hotels', es: 'Gestionar Hoteles'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bannerHeight: 160,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openHotelForm(context, ref, existing: null),
        icon: const Icon(Icons.add),
        label: Text(_t3(context, ar: 'إضافة فندق', en: 'Add Hotel', es: 'Añadir Hotel')),
      ),
      body: hotelsAsync.when(
        loading: () => LoadingView(
          message: _t3(context, ar: 'يحمّل الفنادق...', en: 'Loading hotels...', es: 'Cargando hoteles...'),
        ),
        error: (error, _) => ErrorView(
          message: _t3(
            context,
            ar: 'تعذر تحميل الفنادق',
            en: 'Could not load hotels',
            es: 'No se pudieron cargar los hoteles',
          ),
          onRetry: () => ref.invalidate(adminHotelsListProvider),
        ),
        data: (hotels) {
          if (hotels.isEmpty) {
            return Center(
              child: Text(
                _t3(context, ar: 'ما فيه فنادق مضافة بعد', en: 'No hotels added yet', es: 'Aún no hay hoteles'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: hotels.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              return _HotelAdminTile(
                hotel: hotel,
                onEdit: () => _openHotelForm(context, ref, existing: hotel),
                onDelete: () => _confirmDelete(context, ref, hotel),
              );
            },
          );
        },
      ),
    );
  }

  void _openHotelForm(BuildContext context, WidgetRef ref, {required HotelModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _HotelFormSheet(existing: existing),
    ).then((saved) {
      if (saved == true) {
        ref.invalidate(adminHotelsListProvider);
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, HotelModel hotel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t3(dialogContext, ar: 'حذف الفندق', en: 'Delete hotel', es: 'Eliminar hotel')),
        content: Text(
          _t3(
            dialogContext,
            ar: 'متأكد إنك تبي تحذف "${hotel.name}"؟ هذا الإجراء ما ينرجع.',
            en: 'Are you sure you want to delete "${hotel.name}"? This cannot be undone.',
            es: '¿Seguro que quieres eliminar "${hotel.name}"? Esto no se puede deshacer.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              _t3(dialogContext, ar: 'حذف', en: 'Delete', es: 'Eliminar'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(adminHotelRepositoryProvider);
    final result = await repo.deleteHotel(hotel.id);
    if (!context.mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(adminHotelsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t3(context, ar: 'انحذف الفندق', en: 'Hotel deleted', es: 'Hotel eliminado'))),
        );
      },
      failure: (message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      ),
    );
  }
}

class _HotelAdminTile extends StatelessWidget {
  final HotelModel hotel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HotelAdminTile({required this.hotel, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: hotel.images.isNotEmpty
                ? Image.network(
              hotel.images.first,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: AppColors.background,
                child: const Icon(Icons.hotel_outlined),
              ),
            )
                : Container(
              width: 64,
              height: 64,
              color: AppColors.background,
              child: const Icon(Icons.hotel_outlined),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hotel.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${hotel.city} · ${hotel.propertyType}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text('${hotel.rating} (${hotel.reviewCount})', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: AppSizes.md),
                    Text(
                      '\$${hotel.pricePerNight.toStringAsFixed(0)}/night',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            tooltip: _t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
            tooltip: _t3(context, ar: 'حذف', en: 'Delete', es: 'Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// نموذج إضافة/تعديل فندق. يرجع `true` عبر Navigator.pop لو انحفظ بنجاح،
/// عشان الشاشة الأم تعرف تعمل invalidate للقائمة.
class _HotelFormSheet extends ConsumerStatefulWidget {
  final HotelModel? existing;
  const _HotelFormSheet({required this.existing});

  @override
  ConsumerState<_HotelFormSheet> createState() => _HotelFormSheetState();
}

class _HotelFormSheetState extends ConsumerState<_HotelFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _priceController;
  late final TextEditingController _ratingController;
  late final TextEditingController _reviewCountController;
  late final TextEditingController _maxGuestsController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _amenitiesController;
  late final TextEditingController _imagesController;
  late String _propertyType;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _nameController = TextEditingController(text: h?.name ?? '');
    _cityController = TextEditingController(text: h?.city ?? '');
    _priceController = TextEditingController(text: h?.pricePerNight.toString() ?? '');
    _ratingController = TextEditingController(text: h?.rating.toString() ?? '');
    _reviewCountController = TextEditingController(text: h?.reviewCount.toString() ?? '0');
    _maxGuestsController = TextEditingController(text: h?.maxGuests.toString() ?? '2');
    _neighborhoodController = TextEditingController(text: h?.neighborhood ?? '');
    _amenitiesController = TextEditingController(text: h?.amenities.join(', ') ?? '');
    _imagesController = TextEditingController(text: h?.images.join(', ') ?? '');
    _propertyType = h?.propertyType ?? _propertyTypes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _reviewCountController.dispose();
    _maxGuestsController.dispose();
    _neighborhoodController.dispose();
    _amenitiesController.dispose();
    _imagesController.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final hotel = HotelModel(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      pricePerNight: double.parse(_priceController.text.trim()),
      rating: double.parse(_ratingController.text.trim()),
      reviewCount: int.parse(_reviewCountController.text.trim()),
      images: _splitCsv(_imagesController.text),
      amenities: _splitCsv(_amenitiesController.text),
      propertyType: _propertyType,
      neighborhood: _neighborhoodController.text.trim().isEmpty
          ? null
          : _neighborhoodController.text.trim(),
      maxGuests: int.parse(_maxGuestsController.text.trim()),
    );

    final repo = ref.read(adminHotelRepositoryProvider);
    final result = _isEditing ? await repo.updateHotel(hotel) : await repo.createHotel(hotel);

    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (message) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t3(context, ar: 'هذا الحقل مطلوب', en: 'This field is required', es: 'Este campo es obligatorio');
    }
    return null;
  }

  String? _numberValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    if (double.tryParse(value!.trim()) == null) {
      return _t3(context, ar: 'أدخل رقم صحيح', en: 'Enter a valid number', es: 'Ingresa un número válido');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing
                    ? _t3(context, ar: 'تعديل فندق', en: 'Edit Hotel', es: 'Editar Hotel')
                    : _t3(context, ar: 'إضافة فندق جديد', en: 'Add New Hotel', es: 'Añadir Hotel Nuevo'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: _t3(context, ar: 'اسم الفندق', en: 'Hotel name', es: 'Nombre del hotel')),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: _t3(context, ar: 'المدينة', en: 'City', es: 'Ciudad')),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSizes.sm),
              DropdownButtonFormField<String>(
                initialValue: _propertyType,
                decoration: InputDecoration(labelText: _t3(context, ar: 'نوع العقار', en: 'Property type', es: 'Tipo de propiedad')),
                items: _propertyTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _propertyType = value ?? _propertyType),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _neighborhoodController,
                decoration: InputDecoration(
                  labelText: _t3(context, ar: 'الحي (اختياري)', en: 'Neighborhood (optional)', es: 'Barrio (opcional)'),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: _t3(context, ar: 'السعر لليلة', en: 'Price per night', es: 'Precio por noche')),
                      validator: _numberValidator,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _maxGuestsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: _t3(context, ar: 'أقصى عدد ضيوف', en: 'Max guests', es: 'Máx. huéspedes')),
                      validator: _numberValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ratingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: _t3(context, ar: 'التقييم (0-5)', en: 'Rating (0-5)', es: 'Calificación (0-5)')),
                      validator: _numberValidator,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _reviewCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: _t3(context, ar: 'عدد التقييمات', en: 'Review count', es: 'N.º de reseñas')),
                      validator: _numberValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _amenitiesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _t3(context, ar: 'المرافق (مفصولة بفاصلة)', en: 'Amenities (comma-separated)', es: 'Comodidades (separadas por comas)'),
                  hintText: 'WiFi, Pool, Parking',
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _imagesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _t3(context, ar: 'روابط الصور (مفصولة بفاصلة)', en: 'Image URLs (comma-separated)', es: 'URLs de imágenes (separadas por comas)'),
                  hintText: 'https://..., https://...',
                ),
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(_t3(context, ar: 'حفظ', en: 'Save', es: 'Guardar')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}