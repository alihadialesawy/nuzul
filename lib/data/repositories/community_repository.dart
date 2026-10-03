import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/result.dart'; // عدّل المسار لو الـ Result type عندك في مكان مختلف
import '../models/community_post_model.dart';
import '../models/community_comment_model.dart';

class CommunityRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static const _postsTable = 'community_posts';
  static const _likesTable = 'community_post_likes';
  static const _commentsTable = 'community_post_comments';
  static const _storageBucket = 'community-images';

  /// يجيب فييد المنشورات، الأحدث أولاً. لو [destinationCity] مبعوت،
  /// بيفلتر على وجهة معينة (لصفحة الوجهة نفسها مثلاً).
  Future<Result<List<CommunityPostModel>>> fetchFeed({
    String? destinationCity,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from(_postsTable)
          .select('*, profiles!community_posts_user_id_fkey(display_name, avatar_url)');

      if (destinationCity != null && destinationCity.isNotEmpty) {
        query = query.eq('destination_city', destinationCity);
      }

      final rows = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final myId = _client.auth.currentUser?.id;
      List<String> likedPostIds = [];
      if (myId != null && (rows as List).isNotEmpty) {
        final ids = rows.map((r) => r['id']).toList();
        final likedRows = await _client
            .from(_likesTable)
            .select('post_id')
            .eq('user_id', myId)
            .filter('post_id', 'in', '(${ids.join(',')})');
        likedPostIds = (likedRows as List).map((r) => r['post_id'] as String).toList();
      }

      final posts = (rows as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        return CommunityPostModel.fromJson({
          ...row as Map<String, dynamic>,
          'author_display_name': profile?['display_name'],
          'author_avatar_url': profile?['avatar_url'],
          'liked_by_me': likedPostIds.contains(row['id']),
        });
      }).toList();

      return Success(posts);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// يرفع صور المنشور إلى Storage ويرجّع الروابط العامة (بنفس الترتيب).
  /// كل صورة بتتعالج أولًا عبر [_correctOrientation] قبل الرفع.
  Future<Result<List<String>>> uploadImages(List<File> files) async {
    try {
      final myId = _client.auth.currentUser?.id;
      if (myId == null) return const Failure('User not authenticated');

      final urls = <String>[];
      for (final file in files) {
        final correctedBytes = await _correctOrientation(file);
        final path =
            '$myId/${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg';
        await _client.storage.from(_storageBucket).uploadBinary(
          path,
          correctedBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        urls.add(_client.storage.from(_storageBucket).getPublicUrl(path));
      }
      return Success(urls);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// يقرا بيانات EXIF الخاصة بدوران الصورة (موجودة عادةً في الصور اللي
  /// بتيجي من كاميرا الموبايل مباشرة) ويطبّق الدوران فعليًا على البكسلات
  /// نفسها قبل الرفع، بدل ما نعتمد على قراءة EXIF وقت العرض. ده مهم لأن
  /// بعض المنصات (زي ويندوز) بتتجاهل بيانات EXIF تمامًا وبتعرض الصورة
  /// بوضعها الخام، فتظهر مقلوبة/أفقية غلط حتى لو الموبايل نفسه عرضها صح.
  /// النتيجة دايمًا بترجع JPEG موحّد (بغض النظر عن صيغة الملف الأصلية)
  /// عشان تبسيط الترميز والرفع.
  Future<Uint8List> _correctOrientation(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // فشل فك تشفير الصورة (نادر) -- ارفع البايتات الخام بدل ما نفشل
      // العملية كلها بسبب صورة واحدة معطوبة.
      return bytes;
    }

    final oriented = img.bakeOrientation(decoded);
    return Uint8List.fromList(img.encodeJpg(oriented, quality: 85));
  }

  Future<Result<CommunityPostModel>> createPost(CommunityPostModel post) async {
    try {
      final myId = _client.auth.currentUser?.id;
      if (myId == null) return const Failure('User not authenticated');

      final inserted = await _client
          .from(_postsTable)
          .insert({...post.toInsertJson(), 'user_id': myId})
          .select()
          .single();

      return Success(CommunityPostModel.fromJson(inserted));
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<void>> deletePost(String postId) async {
    try {
      await _client.from(_postsTable).delete().eq('id', postId);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<void>> toggleLike(String postId, bool currentlyLiked) async {
    try {
      final myId = _client.auth.currentUser?.id;
      if (myId == null) return const Failure('User not authenticated');

      if (currentlyLiked) {
        await _client
            .from(_likesTable)
            .delete()
            .eq('post_id', postId)
            .eq('user_id', myId);
      } else {
        await _client.from(_likesTable).insert({
          'post_id': postId,
          'user_id': myId,
        });
      }
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// يجيب كل تعليقات منشور معيّن، الأقدم أولاً (ترتيب محادثة طبيعي).
  /// ملحوظة: بنجيب التعليقات والبروفايلات في استعلامين منفصلين (بدل
  /// join تلقائي عبر !user_id أو اسم constraint)، لأن
  /// community_post_comments.user_id مربوط بـ auth.users مش profiles
  /// مباشرة -- فمفيش أي foreign key يقدر PostgREST يستخدمه لعمل embed
  /// تلقائي لجدول profiles. نفس أسلوب الإعجابات في fetchFeed بالضبط.
  Future<Result<List<CommunityCommentModel>>> fetchComments(String postId) async {
    try {
      final rows = await _client
          .from(_commentsTable)
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final commentRows = rows as List;

      Map<String, Map<String, dynamic>> profilesById = {};
      if (commentRows.isNotEmpty) {
        final userIds = commentRows.map((r) => r['user_id'] as String).toSet().toList();
        final profileRows = await _client
            .from('profiles')
            .select('id, display_name, avatar_url')
            .filter('id', 'in', '(${userIds.join(',')})');
        for (final p in (profileRows as List)) {
          profilesById[p['id'] as String] = p as Map<String, dynamic>;
        }
      }

      final comments = commentRows.map((row) {
        final profile = profilesById[row['user_id']];
        return CommunityCommentModel.fromJson({
          ...row as Map<String, dynamic>,
          'author_display_name': profile?['display_name'],
          'author_avatar_url': profile?['avatar_url'],
        });
      }).toList();

      return Success(comments);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// يضيف تعليق جديد على منشور. comments_count بيتحدّث تلقائيًا عبر
  /// trigger في قاعدة البيانات (نفس أسلوب likes_count).
  Future<Result<CommunityCommentModel>> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final myId = _client.auth.currentUser?.id;
      if (myId == null) return const Failure('User not authenticated');

      final inserted = await _client
          .from(_commentsTable)
          .insert({
        'post_id': postId,
        'user_id': myId,
        'content': content,
      })
          .select()
          .single();

      return Success(CommunityCommentModel.fromJson(inserted));
    } catch (e) {
      return Failure(e.toString());
    }
  }
}