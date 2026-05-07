class Post {
  const Post({
    required this.id,
    required this.likeCount,
    this.mediaThumbUrl,
    this.mediaMobileUrl,
    this.mediaRawUrl,
    this.createdAt,
  });

  final String id;
  final int likeCount;
  final String? mediaThumbUrl;
  final String? mediaMobileUrl;
  final String? mediaRawUrl;
  final DateTime? createdAt;

  String get displayId => id;
  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  String get displayCreatedAt {
    if (createdAt == null) {
      return 'Unknown time';
    }
    final date = createdAt!.toLocal();
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final likeCountRaw = json['like_count'];
    int likeCount = 0;
    if (likeCountRaw is int) {
      likeCount = likeCountRaw;
    } else if (likeCountRaw is String) {
      likeCount = int.tryParse(likeCountRaw) ?? 0;
    }

    final mediaThumbUrl = json['media_thumb_url']?.toString();
    final mediaMobileUrl = json['media_mobile_url']?.toString();
    final mediaRawUrl = json['media_raw_url']?.toString();

    DateTime? createdAt;
    final createdAtRaw = json['created_at'];
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return Post(
      id: json['id'].toString(),
      likeCount: likeCount,
      mediaThumbUrl: mediaThumbUrl,
      mediaMobileUrl: mediaMobileUrl,
      mediaRawUrl: mediaRawUrl,
      createdAt: createdAt,
    );
  }
}
