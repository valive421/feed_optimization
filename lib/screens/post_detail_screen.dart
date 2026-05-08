import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = post.mediaMobileUrl ?? post.mediaThumbUrl;
    final highResUrl = post.mediaRawUrl ?? post.mediaMobileUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl != null)
            Hero(
              tag: 'post-media-${post.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: highResUrl == null
                        ? null
                        : () => _openFullscreen(context, highResUrl),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 220,
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (context, error, stackTrace) => Container(
                        height: 220,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                      fadeInDuration: const Duration(milliseconds: 220),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.image_outlined),
            ),
          const SizedBox(height: 16),
          Text(
            'Post ${post.shortId}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Likes: ${post.likeCount}',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Created: ${post.displayCreatedAt}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _launchHighRes(context),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download High-Res'),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => FullscreenImageScreen(
          tag: 'post-media-${post.id}',
          imageUrl: url,
        ),
      ),
    );
  }

  Future<void> _launchHighRes(BuildContext context) async {
    final url = post.mediaRawUrl ?? post.mediaMobileUrl ?? post.mediaThumbUrl;
    if (url == null || url.isEmpty) {
      _showSnack(context, 'No high-res URL available for this post.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack(context, 'Invalid high-res URL.');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      _showSnack(context, 'Unable to open download link.');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class FullscreenImageScreen extends StatelessWidget {
  const FullscreenImageScreen({
    super.key,
    required this.tag,
    required this.imageUrl,
  });

  final String tag;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: tag,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    height: 240,
                    width: 240,
                  ),
                  errorWidget: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    height: 240,
                    width: 240,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                  fadeInDuration: const Duration(milliseconds: 220),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}
