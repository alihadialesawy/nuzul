import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/destination_model.dart';
import '../../../data/repositories/hotel_repository.dart';

/// خريطة كود الدولة (ISO) لاسمها المعروض بالعربية والإنجليزية. لو
/// ظهرت دولة جديدة (بعد مزامنة إضافية) مش موجودة هنا، بيتعرض الكود
/// نفسه كـ fallback بدل ما تختفي من القائمة.
const Map<String, ({String ar, String en})> _countryNames = {
  'SA': (ar: 'السعودية', en: 'Saudi Arabia'),
  'AE': (ar: 'الإمارات', en: 'United Arab Emirates'),
  'EG': (ar: 'مصر', en: 'Egypt'),
  'TR': (ar: 'تركيا', en: 'Turkey'),
  'ES': (ar: 'إسبانيا', en: 'Spain'),
  'FR': (ar: 'فرنسا', en: 'France'),
  'MY': (ar: 'ماليزيا', en: 'Malaysia'),
  'ID': (ar: 'إندونيسيا', en: 'Indonesia'),
  'US': (ar: 'الولايات المتحدة', en: 'United States'),
  'GB': (ar: 'المملكة المتحدة', en: 'United Kingdom'),
};

String countryDisplayName(BuildContext context, String countryCode) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final entry = _countryNames[countryCode];
  if (entry == null) return countryCode;
  return isArabic ? entry.ar : entry.en;
}

/// شاشة تصفّح ثنائية المستوى: قائمة الدول المتاحة أولًا، وبعد اختيار
/// دولة، قائمة مدنها. بتُستخدم كـ modal bottom sheet من home_page.
/// [onCitySelected] بيتنادى بمجرد ما المستخدم يختار مدينة، وبيسكّر
/// الـ sheet تلقائيًا (المتحكم به من الاستدعاء، مش من هنا).
class CountryBrowser extends StatefulWidget {
  final HotelRepository repository;
  final void Function(DestinationModel destination) onCitySelected;

  const CountryBrowser({
    super.key,
    required this.repository,
    required this.onCitySelected,
  });

  @override
  State<CountryBrowser> createState() => _CountryBrowserState();
}

class _CountryBrowserState extends State<CountryBrowser> {
  List<CountrySummary>? _countries;
  String? _selectedCountryCode;
  List<DestinationModel>? _cities;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.repository.getAvailableCountries();
    if (!mounted) return;
    result.when(
      success: (countries) => setState(() {
        _countries = countries;
        _loading = false;
      }),
      failure: (message) => setState(() {
        _error = message;
        _loading = false;
      }),
    );
  }

  Future<void> _selectCountry(String countryCode) async {
    setState(() {
      _selectedCountryCode = countryCode;
      _loading = true;
      _error = null;
    });
    final result = await widget.repository.getDestinationsByCountry(countryCode);
    if (!mounted) return;
    result.when(
      success: (cities) => setState(() {
        _cities = cities;
        _loading = false;
      }),
      failure: (message) => setState(() {
        _error = message;
        _loading = false;
      }),
    );
  }

  void _backToCountries() {
    setState(() {
      _selectedCountryCode = null;
      _cities = null;
    });
  }

  bool get _isArabic {
    final locale = Localizations.maybeLocaleOf(context);
    return locale?.languageCode == 'ar';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                AppSizes.md,
                AppSizes.md,
                AppSizes.sm,
              ),
              child: Row(
                children: [
                  if (_selectedCountryCode != null)
                    IconButton(
                      onPressed: _backToCountries,
                      icon: Icon(_isArabic ? Icons.arrow_forward : Icons.arrow_back),
                    ),
                  Expanded(
                    child: Text(
                      _selectedCountryCode == null
                          ? (_isArabic ? 'تصفّح حسب الدولة' : 'Browse by country')
                          : countryDisplayName(context, _selectedCountryCode!),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(scrollController)),
          ],
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Text(
            _isArabic ? 'تعذر تحميل القائمة' : 'Could not load the list',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (_selectedCountryCode == null) {
      final countries = _countries ?? const [];
      if (countries.isEmpty) {
        return Center(
          child: Text(
            _isArabic ? 'لا توجد دول متاحة حاليًا' : 'No countries available yet',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      }
      return ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        itemCount: countries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = countries[index];
          return ListTile(
            leading: const Icon(Icons.public, color: AppColors.primary),
            title: Text(countryDisplayName(context, c.countryCode)),
            trailing: Text(
              _isArabic ? '${c.cityCount} مدينة' : '${c.cityCount} cities',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            onTap: () => _selectCountry(c.countryCode),
          );
        },
      );
    }

    final cities = _cities ?? const [];
    if (cities.isEmpty) {
      return Center(
        child: Text(
          _isArabic ? 'لا توجد مدن متاحة لهذه الدولة' : 'No cities available for this country',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      itemCount: cities.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final d = cities[index];
        return ListTile(
          leading: const Icon(Icons.location_city, color: AppColors.primary),
          title: Text(d.name),
          onTap: () => widget.onCitySelected(d),
        );
      },
    );
  }
}