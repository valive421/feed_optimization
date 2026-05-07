class Post {
  const Post({
    required this.id,
    required this.likeCount,
    required this.isLiked,
    this.mediaThumbUrl,
    this.mediaMobileUrl,
    this.mediaRawUrl,
    this.createdAt,
  });

  final String id;
  final int likeCount;
  final bool isLiked;
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

  Post copyWith({
    int? likeCount,
    bool? isLiked,
    String? mediaThumbUrl,
    String? mediaMobileUrl,
    String? mediaRawUrl,
    DateTime? createdAt,
  }) {
    return Post(
      id: id,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      mediaThumbUrl: mediaThumbUrl ?? this.mediaThumbUrl,
      mediaMobileUrl: mediaMobileUrl ?? this.mediaMobileUrl,
      mediaRawUrl: mediaRawUrl ?? this.mediaRawUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json, {bool isLiked = false}) {
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
      isLiked: isLiked,
      mediaThumbUrl: mediaThumbUrl,
      mediaMobileUrl: mediaMobileUrl,
      mediaRawUrl: mediaRawUrl,
      createdAt: createdAt,
    );
  }
}
