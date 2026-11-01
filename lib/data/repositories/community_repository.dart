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
      // الأسماء والصور تُجلب عبر community_author_profiles (صلاحيات profiles
      // لا تسمح للزائر بقراءة ملفات الآخرين، فكان كل كاتب يظهر "Traveler").
      var query = _client.from(_postsTable).select();

      if (destinationCity != null && destinationCity.isNotEmpty) {
        query = query.eq('destination_city', destinationCity);
      }

      // ضوابط المحتوى: لا تظهر منشورات من حظرهم المستخدم، ولا ما أبلغ عنه.
      final myId = _client.auth.currentUser?.id;
      if (myId != null) {
        final blocked = await _blockedUserIds(myId);
        if (blocked.isNotEmpty) {
          query = query.not('user_id', 'in', '(${blocked.join(',')})');
        }
        final reported = await _reportedPostIds(myId);
        if (reported.isNotEmpty) {
          query = query.not('id', 'in', '(${reported.join(',')})');
        }
      }

      final rows = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

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

      final profilesById = await _authorProfiles(
          (rows as List).map((r) => r['user_id'] as String?).whereType<String>().toSet().toList());

      final posts = (rows as List).map((row) {
        final profile = profilesById[row['user_id']];
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
  /// يستقبل البايتات مباشرة (لا dart:io File) حتى يعمل على الويب والموبايل.
  /// كل صورة بتتعالج أولًا عبر [_correctOrientation] قبل الرفع.
  Future<Result<List<String>>> uploadImages(List<Uint8List> images) async {
    try {
      final myId = _client.auth.currentUser?.id;
      if (myId == null) return const Failure('User not authenticated');

      final urls = <String>[];
      for (final bytes in images) {
        final correctedBytes = _correctOrientation(bytes);
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
  Uint8List _correctOrientation(Uint8List bytes) {
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

      // تعليقات المستخدمين المحظورين لا تظهر لمن حظرهم.
      final myId = _client.auth.currentUser?.id;
      final blocked = myId == null ? const <String>[] : await _blockedUserIds(myId);
      final commentRows =
      (rows as List).where((r) => !blocked.contains(r['user_id'] as String?)).toList();

      final profilesById = await _authorProfiles(
          commentRows.map((r) => r['user_id'] as String?).whereType<String>().toSet().toList());

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

  // ═══════════════════ ضوابط المحتوى (Apple Guideline 1.2) ═══════════════════

  static const _termsVersion = '2026-11-01';

  /// الاسم والصورة فقط لكتّاب المجتمع (دالة security definer).
  Future<Map<String, Map<String, dynamic>>> _authorProfiles(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final rows = await _client.rpc('community_author_profiles', params: {'p_ids': ids});
      return {
        for (final r in (rows as List).whereType<Map>())
          '${r['id']}': Map<String, dynamic>.from(r),
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<String>> _blockedUserIds(String myId) async {
    try {
      final rows = await _client.from('user_blocks').select('blocked_id').eq('blocker_id', myId);
      return (rows as List).map((r) => r['blocked_id'] as String).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _reportedPostIds(String myId) async {
    try {
      final rows = await _client
          .from('community_reports')
          .select('post_id')
          .eq('reporter_id', myId)
          .eq('kind', 'post');
      return (rows as List).map((r) => r['post_id']).whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }

  /// إبلاغ عن منشور أو تعليق. reason: spam | harassment | sexual | violence | scam | other
  Future<Result<void>> reportContent({
    String? postId,
    String? commentId,
    required String reason,
    String? details,
  }) async {
    try {
      await _client.rpc('report_community_content', params: {
        'p_post_id': postId,
        'p_comment_id': commentId,
        'p_reason': reason,
        'p_details': details,
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// حظر كاتب منشور أو تعليق: لن تظهر منشوراته وتعليقاته لهذا المستخدم.
  Future<Result<void>> blockAuthor({String? postId, String? commentId}) async {
    try {
      await _client.rpc('community_block', params: {
        'p_post_id': postId,
        'p_comment_id': commentId,
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// هل وافق المستخدم على قواعد المجتمع (الإصدار الحالي)؟
  Future<bool> hasAcceptedCommunityTerms() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return false;
    try {
      final row = await _client
          .from('community_terms_acceptances')
          .select('version')
          .eq('user_id', myId)
          .maybeSingle();
      return row != null && row['version'] == _termsVersion;
    } catch (_) {
      return false;
    }
  }

  Future<Result<void>> acceptCommunityTerms() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return const Failure('User not authenticated');
    try {
      await _client.from('community_terms_acceptances').upsert({
        'user_id': myId,
        'version': _termsVersion,
        'accepted_at': DateTime.now().toUtc().toIso8601String(),
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// هل أوقف الأدمن هذا المستخدم عن النشر؟
  Future<bool> isBannedFromCommunity() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return false;
    try {
      final row = await _client.from('community_bans').select('user_id').eq('user_id', myId).maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }
}