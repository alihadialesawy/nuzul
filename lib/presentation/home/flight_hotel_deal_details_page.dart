import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/price_text.dart';
import 'widgets/flight_hotel_deals_section.dart';

/// صفحة تفاصيل عرض طيران + فندق واحد: تفاصيل رحلة الذهاب والعودة فوق،
/// وتفاصيل الفندق (بمقارنة سعر الحجز منفصل مقابل الباقة المدمجة) تحت.
/// البيانات هنا مبنية على FlightHotelDeal نفسه (بيانات نموذجية sample
/// -- راجع الملاحظة في flight_hotel_deals_section.dart)، مش على عرض
/// حقيقي من Duffel/HotelBeds لسه.
class FlightHotelDealDetailsPage extends StatelessWidget {
  final String origin;
  final FlightHotelDeal deal;

  const FlightHotelDealDetailsPage({
    super.key,
    required this.origin,
    required this.deal,
  });

  @override
  Widget build(BuildContext context) {
    // أسعار الفندق منفصل مقابل الباقة المدمجة -- نموذجية (sample)
    // بنفس منطق الكارت في القائمة.
    final separateTotal = deal.originalPriceSar * 1.15;
    final bundledTotal = deal.finalPriceSar;

    return Scaffold(
      appBar: const AppBanner(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$origin ⇌ ${deal.destinationCity}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deal.dateLabel,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // ================= قسم الطيران =================
                    Row(
                      children: const [
                        Icon(Icons.flight, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Flight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    _FlightLegCard(
                      dateLabel: deal.dateLabel.split(' - ').first,
                      originCode: _airportCodeFor(origin),
                      destinationCode: _airportCodeFor(deal.destinationCity),
                      departTime: '9:10 AM',
                      arriveTime: '11:45 AM',
                      duration: '2h 35m',
                    ),
                    const SizedBox(height: AppSizes.sm),
                    _FlightLegCard(
                      dateLabel: deal.dateLabel.split(' - ').last,
                      originCode: _airportCodeFor(deal.destinationCity),
                      destinationCode: _airportCodeFor(origin),
                      departTime: '6:20 PM',
                      arriveTime: '8:55 PM',
                      duration: '2h 35m',
                    ),

                    const SizedBox(height: AppSizes.xl),

                    // ================= قسم الفندق =================
                    Row(
                      children: const [
                        Icon(Icons.hotel, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Hotel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 110,
                              height: 110,
                              child: Image.asset(
                                deal.imageAsset,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.hotel_outlined, color: AppColors.textHint, size: 32),
                                ),
                              ),
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
                                        deal.hotelName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        deal.hotelStars,
                                            (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${deal.destinationCity}, ${deal.destinationCountry}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Booked separately',
                                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                        PriceText(
                                          sarAmount: separateTotal,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            decoration: TextDecoration.lineThrough,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Flight + Hotel',
                                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11),
                                        ),
                                        PriceText(
                                          sarAmount: bundledTotal,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  'Per person, ${deal.dateLabel}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Book this deal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // كود مطار تقريبي للعرض بس (مش من مصدر IATA رسمي) -- عشان يوريك
  // شكل الرحلة، مش قيمة حقيقية للحجز الفعلي.
  static String _airportCodeFor(String city) {
    const codes = {
      'Detroit': 'DTW',
      'New York': 'JFK',
      'Boston': 'BOS',
      'Los Angeles': 'LAX',
      'Dallas': 'DFW',
      'Chicago': 'ORD',
    };
    return codes[city] ?? city.substring(0, city.length > 3 ? 3 : city.length).toUpperCase();
  }
}

class _FlightLegCard extends StatelessWidget {
  final String dateLabel;
  final String originCode;
  final String destinationCode;
  final String departTime;
  final String arriveTime;
  final String duration;

  const _FlightLegCard({
    required this.dateLabel,
    required this.originCode,
    required this.destinationCode,
    required this.departTime,
    required this.arriveTime,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(departTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(originCode, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Icon(Icons.flight, size: 14, color: AppColors.textSecondary),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const Text('Nonstop', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(arriveTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(destinationCode, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}