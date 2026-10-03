import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // أضف image_picker في pubspec.yaml لو مش موجودة

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../data/models/community_post_model.dart';
import '../../data/models/community_comment_model.dart';
import 'controllers/community_controller.dart';

/// نفس نمط الترجمة المستخدم في باقي صفحات المشروع (_t3، 9 لغات).
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

class CommunityPage extends ConsumerWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      appBar: AppBanner(
        tabsBar: Text(
          _t3(context,
              ar: 'المجتمع', en: 'Community', es: 'Comunidad', tr: 'Topluluk',
              id: 'Komunitas', hi: 'समुदाय', ur: 'کمیونٹی', fr: 'Communauté', bn: 'কমিউনিটি'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bannerHeight: 160,
      ),
      // LayoutBuilder عشان نحدد عرض أقصى لمحتوى الفييد على الشاشات العريضة
      // (ويب/سطح المكتب). من غيره، الكروت بتمتد لعرض الشاشة كله وارتفاع
      // الصورة الثابت (220) بيبقى نسبة ضيقة جدًا مقارنة بالعرض، فيحصل قص
      // شديد للصورة (crop) بيخفي جزء كبير منها بدل ما يعرضها بشكل طبيعي.
      body: LayoutBuilder(
        builder: (context, constraints) {
          const maxContentWidth = 600.0;
          final isWide = constraints.maxWidth > maxContentWidth;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(communityFeedProvider),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? maxContentWidth : double.infinity,
                ),
                child: feedAsync.when(
                  loading: () => LoadingView(
                    message: _t3(context,
                        ar: 'يحمّل المنشورات...', en: 'Loading posts...', es: 'Cargando publicaciones...', tr: 'Gönderiler yükleniyor...',
                        id: 'Memuat postingan...', hi: 'पोस्ट लोड हो रही हैं...', ur: 'پوسٹس لوڈ ہو رہی ہیں...', fr: 'Chargement des publications...', bn: 'পোস্ট লোড হচ্ছে...'),
                  ),
                  error: (error, _) => ErrorView(
                    message: _t3(context,
                        ar: 'تعذر تحميل المجتمع', en: 'Could not load community', es: 'No se pudo cargar la comunidad', tr: 'Topluluk yüklenemedi',
                        id: 'Gagal memuat komunitas', hi: 'समुदाय लोड नहीं हो सका', ur: 'کمیونٹی لوڈ نہیں ہو سکی', fr: 'Impossible de charger la communauté', bn: 'কমিউনিটি লোড করা যায়নি'),
                    onRetry: () => ref.invalidate(communityFeedProvider),
                  ),
                  data: (posts) {
                    if (posts.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, innerConstraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: innerConstraints.maxHeight),
                            child: Center(
                              child: Text(
                                _t3(context,
                                    ar: 'لا توجد منشورات بعد. شارك أول رحلة!', en: 'No posts yet. Share your first trip!',
                                    es: 'Aún no hay publicaciones. ¡Comparte tu primer viaje!', tr: 'Henüz gönderi yok. İlk seyahatini paylaş!',
                                    id: 'Belum ada postingan. Bagikan perjalanan pertama Anda!', hi: 'अभी तक कोई पोस्ट नहीं। अपनी पहली यात्रा साझा करें!',
                                    ur: 'ابھی تک کوئی پوسٹ نہیں۔ اپنا پہلا سفر شیئر کریں!', fr: 'Aucune publication pour le moment. Partagez votre premier voyage !',
                                    bn: 'এখনও কোনো পোস্ট নেই। আপনার প্রথম ভ্রমণ শেয়ার করুন!'),
                                style: const TextStyle(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.md),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                      itemBuilder: (context, index) => _PostCard(post: posts[index]),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePostSheet(context, ref),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(_t3(context,
            ar: 'شارك رحلتك', en: 'Share a trip', es: 'Comparte un viaje', tr: 'Seyahatini paylaş',
            id: 'Bagikan perjalanan', hi: 'यात्रा साझा करें', ur: 'سفر شیئر کریں', fr: 'Partager un voyage', bn: 'ভ্রমণ শেয়ার করুন')),
      ),
    );
  }

  void _openCreatePostSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _CreatePostSheet(),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final CommunityPostModel post;
  const _PostCard({required this.post});

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _CommentsSheet(postId: post.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.authorAvatarUrl != null
                      ? NetworkImage(post.authorAvatarUrl!)
                      : null,
                  child: post.authorAvatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorDisplayName ??
                            _t3(context,
                                ar: 'مسافر', en: 'Traveler', es: 'Viajero', tr: 'Gezgin',
                                id: 'Wisatawan', hi: 'यात्री', ur: 'مسافر', fr: 'Voyageur', bn: 'ভ্রমণকারী'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (post.destinationCity != null)
                        Text(
                          post.destinationCity!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (post.isVerifiedTrip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _t3(context,
                              ar: 'رحلة موثّقة', en: 'Verified Trip', es: 'Viaje verificado', tr: 'Doğrulanmış seyahat',
                              id: 'Perjalanan terverifikasi', hi: 'सत्यापित यात्रा', ur: 'تصدیق شدہ سفر', fr: 'Voyage vérifié', bn: 'যাচাইকৃত ভ্রমণ'),
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (post.imageUrls.isNotEmpty)
            AspectRatio(
              // 4:3 عشان نضمن نسبة عرض/ارتفاع طبيعية ومعقولة لأي صورة سفر
              // عادية، بدل ارتفاع ثابت بالبكسل كان بيعمل قص شديد على
              // الشاشات العريضة (راجع كومنت الـ LayoutBuilder في CommunityPage).
              aspectRatio: 4 / 3,
              child: PageView.builder(
                itemCount: post.imageUrls.length,
                itemBuilder: (context, i) => Image.network(
                  post.imageUrls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.rating != null) _RatingStars(rating: post.rating!),
                if (post.rating != null) const SizedBox(height: 6),
                Text(post.caption),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    _LikeButton(post: post),
                    const SizedBox(width: AppSizes.md),
                    InkWell(
                      onTap: () => _openComments(context),
                      child: Row(
                        children: [
                          const Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${post.commentsCount}', style: const TextStyle(color: AppColors.textSecondary)),
                        ],
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

class _RatingStars extends StatelessWidget {
  final int rating;
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
            (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        ),
      ),
    );
  }
}

class _LikeButton extends ConsumerStatefulWidget {
  final CommunityPostModel post;
  const _LikeButton({required this.post});

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
  late bool _liked = widget.post.likedByMe;
  late int _count = widget.post.likesCount;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _liked = !_liked;
      _count += _liked ? 1 : -1;
    });
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.toggleLike(widget.post.id, !_liked);
    result.when(
      success: (_) {},
      failure: (_) {
        if (mounted) {
          setState(() {
            _liked = !_liked;
            _count += _liked ? 1 : -1;
          });
        }
      },
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      child: Row(
        children: [
          Icon(
            _liked ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: _liked ? Colors.red : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text('$_count', style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// شاشة سفلية (bottom sheet) تعرض تعليقات منشور معيّن + حقل إضافة
/// تعليق جديد. بتتفتح لما تدوس على أيقونة/عداد التعليقات تحت أي
/// منشور (سواء فيه صور ولا لأ).
class _CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  List<CommunityCommentModel>? _comments;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.fetchComments(widget.postId);
    if (!mounted) return;
    result.when(
      success: (comments) => setState(() {
        _comments = comments;
        _loading = false;
      }),
      failure: (message) => setState(() {
        _error = message;
        _loading = false;
      }),
    );
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.addComment(postId: widget.postId, content: text);
    if (!mounted) return;

    result.when(
      success: (comment) {
        setState(() {
          _comments = [...?_comments, comment];
          _controller.clear();
          _sending = false;
        });
      },
      failure: (message) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  _t3(context,
                      ar: 'التعليقات', en: 'Comments', es: 'Comentarios', tr: 'Yorumlar',
                      id: 'Komentar', hi: 'टिप्पणियाँ', ur: 'تبصرے', fr: 'Commentaires', bn: 'মন্তব্য'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : (_comments == null || _comments!.isEmpty)
                    ? Center(
                  child: Text(
                    _t3(context,
                        ar: 'لا توجد تعليقات بعد. كن أول من يعلّق!', en: 'No comments yet. Be the first!',
                        es: 'Aún no hay comentarios. ¡Sé el primero!', tr: 'Henüz yorum yok. İlk sen ol!',
                        id: 'Belum ada komentar. Jadilah yang pertama!', hi: 'अभी तक कोई टिप्पणी नहीं। पहले आप बनें!',
                        ur: 'ابھی تک کوئی تبصرہ نہیں۔ پہلے آپ بنیں!', fr: 'Aucun commentaire pour le moment. Soyez le premier !',
                        bn: 'এখনও কোনো মন্তব্য নেই। প্রথম হন!'),
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  itemCount: _comments!.length,
                  itemBuilder: (context, index) {
                    final c = _comments![index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: c.authorAvatarUrl != null
                                ? NetworkImage(c.authorAvatarUrl!)
                                : null,
                            child: c.authorAvatarUrl == null
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.authorDisplayName ??
                                      _t3(context,
                                          ar: 'مسافر', en: 'Traveler', es: 'Viajero', tr: 'Gezgin',
                                          id: 'Wisatawan', hi: 'यात्री', ur: 'مسافر', fr: 'Voyageur', bn: 'ভ্রমণকারী'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(c.content, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: _t3(context,
                              ar: 'اكتب تعليقًا...', en: 'Write a comment...', es: 'Escribe un comentario...', tr: 'Bir yorum yaz...',
                              id: 'Tulis komentar...', hi: 'एक टिप्पणी लिखें...', ur: 'تبصرہ لکھیں...', fr: 'Écrire un commentaire...', bn: 'একটি মন্তব্য লিখুন...'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    _sending
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : IconButton(
                      onPressed: _submitComment,
                      icon: const Icon(Icons.send, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet();

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _captionController = TextEditingController();
  final _cityController = TextEditingController();
  final List<File> _images = [];
  int? _rating;
  bool _submitting = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked.map((x) => File(x.path)).take(5 - _images.length));
      });
    }
  }

  Future<void> _submit() async {
    if (_captionController.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    final repo = ref.read(communityRepositoryProvider);

    List<String> imageUrls = [];
    if (_images.isNotEmpty) {
      final uploadResult = await repo.uploadImages(_images);
      imageUrls = uploadResult.when(
        success: (urls) => urls,
        failure: (_) => <String>[],
      );
    }

    final post = CommunityPostModel(
      id: '',
      userId: '',
      caption: _captionController.text.trim(),
      destinationCity: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      rating: _rating,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      // TODO: اربط bookingType/bookingId هنا لو المستخدم اختار حجز فعلي
      // من My Bookings بدل منشور عام — ده اللي بيفعّل شارة Verified Trip.
    );

    final result = await repo.createPost(post);
    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(communityFeedProvider);
        Navigator.of(context).pop();
      },
      failure: (message) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
    setState(() => _submitting = false);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t3(context,
                  ar: 'شارك رحلتك', en: 'Share a trip', es: 'Comparte un viaje', tr: 'Seyahatini paylaş',
                  id: 'Bagikan perjalanan', hi: 'यात्रा साझा करें', ur: 'سفر شیئر کریں', fr: 'Partager un voyage', bn: 'ভ্রমণ শেয়ার করুন'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.map(
                        (file) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  if (_images.length < 5)
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: _t3(context,
                    ar: 'الوجهة (اختياري)', en: 'Destination (optional)', es: 'Destino (opcional)', tr: 'Varış noktası (isteğe bağlı)',
                    id: 'Tujuan (opsional)', hi: 'गंतव्य (वैकल्पिक)', ur: 'منزل (اختیاری)', fr: 'Destination (facultatif)', bn: 'গন্তব্য (ঐচ্ছিক)'),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _t3(context,
                    ar: 'احكِ عن رحلتك', en: 'Tell us about your trip', es: 'Cuéntanos sobre tu viaje', tr: 'Seyahatinden bahset',
                    id: 'Ceritakan tentang perjalanan Anda', hi: 'अपनी यात्रा के बारे में बताएं', ur: 'اپنے سفر کے بارے میں بتائیں', fr: 'Parlez-nous de votre voyage', bn: 'আপনার ভ্রমণ সম্পর্কে বলুন'),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: List.generate(
                5,
                    (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    (_rating ?? 0) > i ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(_t3(context,
                    ar: 'نشر', en: 'Post', es: 'Publicar', tr: 'Paylaş',
                    id: 'Posting', hi: 'पोस्ट करें', ur: 'پوسٹ کریں', fr: 'Publier', bn: 'পোস্ট করুন')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}