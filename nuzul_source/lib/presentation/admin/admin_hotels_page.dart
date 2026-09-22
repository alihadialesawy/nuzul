import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/hotel_model.dart';
import 'controllers/admin_hotels_controller.dart';

/// يختار النص المناسب حسب اللغة الحالية (عربي/إنجليزي/إسباني/تركي/إندونيسي/هندي/أوردو/فرنسي/بنغالي).
String _t3(
    BuildContext context, {
      required String ar,
      required String en,
      required String es,
      required String tr,
      required String id,
      required String hi,
      required String ur,
      required String fr,
      required String bn,
    }) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'es':
      return es;
    case 'tr':
      return tr;
    case 'id':
      return id;
    case 'hi':
      return hi;
    case 'ur':
      return ur;
    case 'fr':
      return fr;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

/// نفس أنواع العقارات المستخدمة بالظبط في فلتر "Property Type" بشريط
/// الفلاتر الجانبي (search_filters_sidebar.dart، _propertyTypeCounts).
/// لازم القائمتين تفضلوا متطابقين حرفيًا — فندق مضاف من هنا بنوع
/// عقار مش موجود في القائمة دي مستحيل يظهر لو المستخدم فلتر بنوع
/// عقار في نتائج البحث.
const List<String> _propertyTypes = [
  'Hotels',
  'Condo Hotels',
  'Apartments',
  'Guesthouses',
  'Bed and Breakfasts',
  'Motels',
  'Hostels',
  'Homestays',
  'Entire homes & apartments',
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
          _t3(context, ar: 'إدارة الفنادق', en: 'Manage Hotels', es: 'Gestionar Hoteles', tr: 'Otelleri Yönet', id: 'Kelola Hotel',
              hi: 'होटल प्रबंधित करें',
              ur: 'ہوٹلز کا انتظام کریں',
              fr: 'Gérer les hôtels',
              bn: 'হোটেল পরিচালনা করুন'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bannerHeight: 160,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openHotelForm(context, ref, existing: null),
        icon: const Icon(Icons.add),
        label: Text(_t3(context, ar: 'إضافة فندق', en: 'Add Hotel', es: 'Añadir Hotel', tr: 'Otel Ekle', id: 'Tambah Hotel',
            hi: 'होटल जोड़ें',
            ur: 'ہوٹل شامل کریں',
            fr: 'Ajouter un hôtel',
            bn: 'হোটেল যোগ করুন')),
      ),
      body: hotelsAsync.when(
        loading: () => LoadingView(
          message: _t3(context, ar: 'يحمّل الفنادق...', en: 'Loading hotels...', es: 'Cargando hoteles...', tr: 'Oteller yükleniyor...', id: 'Memuat hotel...',
              hi: 'होटल लोड हो रहे हैं...',
              ur: 'ہوٹل لوڈ ہو رہے ہیں...',
              fr: 'Chargement des hôtels...',
              bn: 'হোটেল লোড হচ্ছে...'),
        ),
        error: (error, _) => ErrorView(
          message: _t3(
            context,
            ar: 'تعذر تحميل الفنادق',
            en: 'Could not load hotels',
            es: 'No se pudieron cargar los hoteles',
            tr: 'Oteller yüklenemedi',
            id: 'Gagal memuat hotel',
            hi: 'होटल लोड नहीं हो सके',
            ur: 'ہوٹل لوڈ نہیں ہو سکے',
            fr: 'Impossible de charger les hôtels',
            bn: 'হোটেল লোড করা যায়নি',
          ),
          onRetry: () => ref.invalidate(adminHotelsListProvider),
        ),
        data: (hotels) {
          if (hotels.isEmpty) {
            return Center(
              child: Text(
                _t3(context, ar: 'لا توجد فنادق مضافة بعد', en: 'No hotels added yet', es: 'Aún no hay hoteles', tr: 'Henüz otel eklenmedi', id: 'Belum ada hotel yang ditambahkan',
                    hi: 'अभी तक कोई होटल नहीं जोड़ा गया',
                    ur: 'ابھی تک کوئی ہوٹل شامل نہیں کیا گیا',
                    fr: 'Aucun hôtel ajouté pour le moment',
                    bn: 'এখনও কোনো হোটেল যোগ করা হয়নি'),
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
        title: Text(_t3(dialogContext, ar: 'حذف الفندق', en: 'Delete hotel', es: 'Eliminar hotel', tr: 'Oteli Sil', id: 'Hapus Hotel',
            hi: 'होटल हटाएं',
            ur: 'ہوٹل حذف کریں',
            fr: 'Supprimer l\'hôtel',
            bn: 'হোটেল মুছুন')),
        content: Text(
          _t3(
            dialogContext,
            ar: 'هل أنت متأكد من حذف "${hotel.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
            en: 'Are you sure you want to delete "${hotel.name}"? This cannot be undone.',
            es: '¿Seguro que quieres eliminar "${hotel.name}"? Esto no se puede deshacer.',
            tr: '"${hotel.name}" adlı oteli silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            id: 'Apakah Anda yakin ingin menghapus "${hotel.name}"? Tindakan ini tidak dapat dibatalkan.',
            hi: 'क्या आप वाकई "${hotel.name}" को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
            ur: 'کیا آپ واقعی "${hotel.name}" کو حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں کیا جا سکتا۔',
            fr: 'Êtes-vous sûr de vouloir supprimer « ${hotel.name} » ? Cette action est irréversible.',
            bn: 'আপনি কি নিশ্চিত যে "${hotel.name}" মুছে ফেলতে চান? এই কাজটি ফিরিয়ে আনা যাবে না।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t3(dialogContext, ar: 'إلغاء', en: 'Cancel', es: 'Cancelar', tr: 'İptal', id: 'Batal',
                hi: 'रद्द करें',
                ur: 'منسوخ کریں',
                fr: 'Annuler',
                bn: 'বাতিল করুন')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              _t3(dialogContext, ar: 'حذف', en: 'Delete', es: 'Eliminar', tr: 'Sil', id: 'Hapus',
                  hi: 'हटाएं',
                  ur: 'حذف کریں',
                  fr: 'Supprimer',
                  bn: 'মুছুন'),
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
          SnackBar(content: Text(_t3(context, ar: 'تم حذف الفندق', en: 'Hotel deleted', es: 'Hotel eliminado', tr: 'Otel silindi', id: 'Hotel dihapus',
              hi: 'होटल हटा दिया गया',
              ur: 'ہوٹل حذف کر دیا گیا',
              fr: 'Hôtel supprimé',
              bn: 'হোটেল মুছে ফেলা হয়েছে'))),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hotel.images.isNotEmpty
                ? Image.network(
              hotel.images.first,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: AppColors.background,
                child: const Icon(Icons.hotel_outlined, size: 32),
              ),
            )
                : Container(
              width: 100,
              height: 100,
              color: AppColors.background,
              child: const Icon(Icons.hotel_outlined, size: 32),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(_t3(context, ar: 'تعديل', en: 'Edit', es: 'Editar', tr: 'Düzenle', id: 'Edit',
                          hi: 'संपादित करें',
                          ur: 'ترمیم کریں',
                          fr: 'Modifier',
                          bn: 'সম্পাদনা করুন')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: Text(
                        _t3(context, ar: 'حذف', en: 'Delete', es: 'Eliminar', tr: 'Sil', id: 'Hapus',
                            hi: 'हटाएं',
                            ur: 'حذف کریں',
                            fr: 'Supprimer',
                            bn: 'মুছুন'),
                        style: const TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    // لو الفندق الحالي عنده propertyType مش موجود في القائمة الموحّدة
    // (زي فنادق قديمة اتحفظت بـ "Resorts"/"Villas" قبل التوحيد)، نرجع
    // لأول قيمة في القائمة بدل ما نكسر الـ dropdown بقيمة مش معروفة.
    _propertyType = _propertyTypes.contains(h?.propertyType)
        ? h!.propertyType
        : _propertyTypes.first;
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
      return _t3(context, ar: 'هذا الحقل مطلوب', en: 'This field is required', es: 'Este campo es obligatorio', tr: 'Bu alan zorunludur', id: 'Bidang ini wajib diisi',
          hi: 'यह फ़ील्ड आवश्यक है',
          ur: 'یہ خانہ ضروری ہے',
          fr: 'Ce champ est obligatoire',
          bn: 'এই ক্ষেত্রটি আবশ্যক');
    }
    return null;
  }

  String? _numberValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    if (double.tryParse(value!.trim()) == null) {
      return _t3(context, ar: 'أدخل رقم صحيح', en: 'Enter a valid number', es: 'Ingresa un número válido', tr: 'Geçerli bir sayı girin', id: 'Masukkan angka yang valid',
          hi: 'एक मान्य संख्या दर्ज करें',
          ur: 'ایک درست نمبر درج کریں',
          fr: 'Entrez un nombre valide',
          bn: 'একটি বৈধ সংখ্যা লিখুন');
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
                    ? _t3(context, ar: 'تعديل فندق', en: 'Edit Hotel', es: 'Editar Hotel', tr: 'Oteli Düzenle', id: 'Edit Hotel',
                    hi: 'होटल संपादित करें',
                    ur: 'ہوٹل میں ترمیم کریں',
                    fr: 'Modifier l\'hôtel',
                    bn: 'হোটেল সম্পাদনা করুন')
                    : _t3(context, ar: 'إضافة فندق جديد', en: 'Add New Hotel', es: 'Añadir Hotel Nuevo', tr: 'Yeni Otel Ekle', id: 'Tambah Hotel Baru',
                    hi: 'नया होटल जोड़ें',
                    ur: 'نیا ہوٹل شامل کریں',
                    fr: 'Ajouter un nouvel hôtel',
                    bn: 'নতুন হোটেল যোগ করুন'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: _t3(context, ar: 'اسم الفندق', en: 'Hotel name', es: 'Nombre del hotel', tr: 'Otel Adı', id: 'Nama Hotel',
                    hi: 'होटल का नाम',
                    ur: 'ہوٹل کا نام',
                    fr: 'Nom de l\'hôtel',
                    bn: 'হোটেলের নাম')),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: _t3(context, ar: 'المدينة', en: 'City', es: 'Ciudad', tr: 'Şehir', id: 'Kota',
                    hi: 'शहर',
                    ur: 'شہر',
                    fr: 'Ville',
                    bn: 'শহর')),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSizes.sm),
              DropdownButtonFormField<String>(
                initialValue: _propertyType,
                decoration: InputDecoration(labelText: _t3(context, ar: 'نوع العقار', en: 'Property type', es: 'Tipo de propiedad', tr: 'Mülk Tipi', id: 'Tipe Properti',
                    hi: 'प्रॉपर्टी का प्रकार',
                    ur: 'پراپرٹی کی قسم',
                    fr: 'Type de propriété',
                    bn: 'সম্পত্তির ধরন')),
                items: _propertyTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _propertyType = value ?? _propertyType),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _neighborhoodController,
                decoration: InputDecoration(
                  labelText: _t3(context, ar: 'الحي (اختياري)', en: 'Neighborhood (optional)', es: 'Barrio (opcional)', tr: 'Semt (isteğe bağlı)', id: 'Lingkungan (opsional)',
                      hi: 'इलाका (वैकल्पिक)',
                      ur: 'علاقہ (اختیاری)',
                      fr: 'Quartier (facultatif)',
                      bn: 'এলাকা (ঐচ্ছিক)'),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: _t3(context, ar: 'السعر لليلة', en: 'Price per night', es: 'Precio por noche', tr: 'Gecelik Fiyat', id: 'Harga per Malam',
                          hi: 'प्रति रात कीमत',
                          ur: 'فی رات قیمت',
                          fr: 'Prix par nuit',
                          bn: 'প্রতি রাতের মূল্য')),
                      validator: _numberValidator,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _maxGuestsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: _t3(context, ar: 'أقصى عدد ضيوف', en: 'Max guests', es: 'Máx. huéspedes', tr: 'Maks. Misafir', id: 'Maks. Tamu',
                          hi: 'अधिकतम मेहमान',
                          ur: 'زیادہ سے زیادہ مہمان',
                          fr: 'Voyageurs max.',
                          bn: 'সর্বোচ্চ অতিথি')),
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
                      decoration: InputDecoration(labelText: _t3(context, ar: 'التقييم (0-5)', en: 'Rating (0-5)', es: 'Calificación (0-5)', tr: 'Puan (0-5)', id: 'Rating (0-5)',
                          hi: 'रेटिंग (0-5)',
                          ur: 'ریٹنگ (0-5)',
                          fr: 'Note (0-5)',
                          bn: 'রেটিং (0-5)')),
                      validator: _numberValidator,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _reviewCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: _t3(context, ar: 'عدد التقييمات', en: 'Review count', es: 'N.º de reseñas', tr: 'Değerlendirme Sayısı', id: 'Jumlah Ulasan',
                          hi: 'समीक्षाओं की संख्या',
                          ur: 'جائزوں کی تعداد',
                          fr: 'Nombre d\'avis',
                          bn: 'রিভিউ সংখ্যা')),
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
                  labelText: _t3(context, ar: 'المرافق (مفصولة بفاصلة)', en: 'Amenities (comma-separated)', es: 'Comodidades (separadas por comas)', tr: 'Olanaklar (virgülle ayırın)', id: 'Fasilitas (pisahkan dengan koma)',
                      hi: 'सुविधाएं (कॉमा से अलग करें)',
                      ur: 'سہولیات (کاما سے الگ کریں)',
                      fr: 'Équipements (séparés par des virgules)',
                      bn: 'সুবিধা (কমা দ্বারা পৃথক)'),
                  hintText: 'WiFi, Pool, Parking',
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _imagesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _t3(context, ar: 'روابط الصور (مفصولة بفاصلة)', en: 'Image URLs (comma-separated)', es: 'URLs de imágenes (separadas por comas)', tr: 'Görsel Bağlantıları (virgülle ayırın)', id: 'URL Gambar (pisahkan dengan koma)',
                      hi: 'छवि URL (कॉमा से अलग करें)',
                      ur: 'تصویری URLs (کاما سے الگ کریں)',
                      fr: 'URL des images (séparées par des virgules)',
                      bn: 'ছবির URL (কমা দ্বারা পৃথক)'),
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
                      : Text(_t3(context, ar: 'حفظ', en: 'Save', es: 'Guardar', tr: 'Kaydet', id: 'Simpan',
                      hi: 'सहेजें',
                      ur: 'محفوظ کریں',
                      fr: 'Enregistrer',
                      bn: 'সংরক্ষণ করুন')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}