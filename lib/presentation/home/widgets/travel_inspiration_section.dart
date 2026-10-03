import 'package:flutter/material.dart';

/// A single destination row shown inside a ranked list (Trending
/// destinations / Cheap flights / Best deals / Popular to Asia ...).
class TravelDestinationItem {
  final String name;
  final String date;
  final String price;
  final String imageUrl;
  final bool isNetworkImage;

  const TravelDestinationItem({
    required this.name,
    required this.date,
    required this.price,
    required this.imageUrl,
    this.isNetworkImage = true,
  });
}

/// One ranked column (e.g. "Trending destinations", "Cheap flights",
/// "Best deals", "Popular to Asia"). Pass 1 or 2 of these to the section.
class TravelDestinationList {
  final String title;
  final Color titleColor;
  final Color badgeColor;
  final List<TravelDestinationItem> items;
  final VoidCallback? onViewMore;

  const TravelDestinationList({
    required this.title,
    required this.titleColor,
    required this.badgeColor,
    required this.items,
    this.onViewMore,
  });
}

/// A small floating price bubble on the "Explore the world" banner
/// (e.g. Vancouver — From $85.90).
class ExploreWorldTag {
  final String city;
  final String price;
  const ExploreWorldTag({required this.city, required this.price});
}

/// The full "Travel inspiration" section: header + blue globe banner
/// + one or two ranked destination-list cards side by side (stacks on
/// narrow / mobile widths).
class TravelInspirationSection extends StatelessWidget {
  final String originCity;
  final List<ExploreWorldTag> exploreTags;
  final List<TravelDestinationList> lists; // 1 or 2 lists
  final VoidCallback? onExploreTap;
  final void Function(TravelDestinationItem item)? onItemTap;

  const TravelInspirationSection({
    super.key,
    required this.originCity,
    required this.exploreTags,
    required this.lists,
    this.onExploreTap,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildExploreBanner(context),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;
            if (isNarrow) {
              return Column(
                children: [
                  for (int i = 0; i < lists.length; i++) ...[
                    _buildListCard(context, lists[i]),
                    if (i != lists.length - 1) const SizedBox(height: 16),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < lists.length; i++) ...[
                  Expanded(child: _buildListCard(context, lists[i])),
                  if (i != lists.length - 1) const SizedBox(width: 16),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Travel inspiration',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: Colors.black87),
            const SizedBox(width: 4),
            Text(
              originCity,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExploreBanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1F6B), Color(0xFF162B8C)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GlobePainter())),
            Positioned(
              top: 20,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Explore the world',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: onExploreTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward,
                          color: Color(0xFF0B1F6B)),
                    ),
                  ),
                ],
              ),
            ),
            if (exploreTags.isNotEmpty)
              Positioned(
                top: 90,
                left: 40,
                child: _ExploreTagBubble(tag: exploreTags[0]),
              ),
            if (exploreTags.length > 1)
              Positioned(
                top: 130,
                left: 160,
                child: _ExploreTagBubble(tag: exploreTags[1]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, TravelDestinationList list) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            list.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: list.titleColor,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < list.items.length; i++) ...[
            _buildDestinationRow(context, i + 1, list.items[i], list.badgeColor),
            if (i != list.items.length - 1) const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: list.onViewMore,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('View more', style: TextStyle(color: Colors.black54)),
                  Icon(Icons.chevron_right, color: Colors.black54, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationRow(
      BuildContext context,
      int rank,
      TravelDestinationItem item,
      Color badgeColor,
      ) {
    return InkWell(
      onTap: onItemTap == null ? null : () => onItemTap!(item),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.isNetworkImage
                    ? Image.network(
                  item.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  ),
                )
                    : Image.asset(
                  item.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                top: -4,
                left: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.date,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreTagBubble extends StatelessWidget {
  final ExploreWorldTag tag;
  const _ExploreTagBubble({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.city,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'From ${tag.price}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 16, top: 2),
          width: 20,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

/// Faint dotted-globe backdrop for the banner (no image asset needed).
class _GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.5, size.height * 1.05);
    final radius = size.width * 0.75;

    const dotSpacing = 10.0;
    for (double y = -radius; y <= radius; y += dotSpacing) {
      for (double x = -radius; x <= radius; x += dotSpacing) {
        final dx = center.dx + x;
        final dy = center.dy + y;
        final distance = (Offset(dx, dy) - center).distance;
        if (distance <= radius) {
          canvas.drawCircle(Offset(dx, dy), 1.0, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ---------------------------------------------------------------
/// EXAMPLE USAGE — place below your flight results / "Popular to Asia"
/// cards on the Flights tab. Replace the sample data with real prices
/// (e.g. from your Duffel search / price_watches data).
/// ---------------------------------------------------------------
///
/// TravelInspirationSection(
///   originCity: 'Los Angeles',
///   exploreTags: const [
///     ExploreWorldTag(city: 'Vancouver', price: '\$85.90'),
///     ExploreWorldTag(city: 'Guadalajara', price: '\$113.10'),
///   ],
///   lists: [
///     TravelDestinationList(
///       title: 'Popular to Asia',
///       titleColor: Colors.deepOrange,
///       badgeColor: Colors.deepOrange,
///       items: const [
///         TravelDestinationItem(
///           name: 'Tokyo',
///           date: 'Sat, Sep 26',
///           price: '\$412.10',
///           imageUrl: 'https://example.com/tokyo.jpg',
///         ),
///         TravelDestinationItem(
///           name: 'Kuala Lumpur',
///           date: 'Tue, Sep 29',
///           price: '\$389.80',
///           imageUrl: 'https://example.com/kl.jpg',
///         ),
///       ],
///       onViewMore: () {
///         // navigate to full Asia destinations list
///       },
///     ),
///     TravelDestinationList(
///       title: 'Best deals',
///       titleColor: Colors.pink,
///       badgeColor: Colors.pink,
///       items: const [
///         TravelDestinationItem(
///           name: 'Bangkok',
///           date: 'Wed, Sep 30',
///           price: '\$310.30',
///           imageUrl: 'https://example.com/bangkok.jpg',
///         ),
///       ],
///     ),
///   ],
///   onExploreTap: () {},
///   onItemTap: (item) {
///     // prefill search with item.name and run search
///   },
/// )