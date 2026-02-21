import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  const CachedImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return Center(
          child: CircularProgressIndicator(
            value: downloadProgress.progress,
          ),
        );
      },
      errorWidget: (context, url, error) {
        developer.log('Failed to load image: $url, error: $error');
        return Container(
          width: width,
          height: height,
          color: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.broken_image, color: colorScheme.outline),
        );
      },
    );
  }
}

/// A wrapper around CachedImage that resolves the image dimensions first.
/// If the image is smaller than [minWidth] x [minHeight], it returns
/// [SizedBox.shrink()]. Uses [AnimatedSize] to collapse smoothly.
class FilteredImage extends StatefulWidget {
  const FilteredImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.minWidth = 200,
    this.minHeight = 400,
    this.wrapperBuilder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double minWidth;
  final double minHeight;
  final Widget Function(BuildContext context, Widget child)? wrapperBuilder;

  @override
  State<FilteredImage> createState() => _FilteredImageState();
}

class _FilteredImageState extends State<FilteredImage> {
  bool _isTooSmall = false;
  bool _hasCheckedSize = false;
  ImageStream? _imageStream;
  ImageStreamListener? _streamListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedSize) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final provider = CachedNetworkImageProvider(widget.imageUrl);
    final config = createLocalImageConfiguration(context);
    _imageStream = provider.resolve(config);
    _streamListener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        final w = info.image.width;
        final h = info.image.height;
        if (w < widget.minWidth || h < widget.minHeight) {
          setState(() {
            _isTooSmall = true;
          });
        }
        setState(() {
          _hasCheckedSize = true;
        });
      },
      onError: (e, s) {
        if (!mounted) return;
        setState(() {
          _hasCheckedSize = true;
          _isTooSmall = true; // hide on error
        });
      },
    );
    _imageStream?.addListener(_streamListener!);
  }

  @override
  void dispose() {
    if (_streamListener != null) {
      _imageStream?.removeListener(_streamListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isTooSmall) {
      child = const SizedBox.shrink();
    } else if (!_hasCheckedSize) {
      child = SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    } else {
      child = CachedImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    if (child is! SizedBox && widget.wrapperBuilder != null && !_isTooSmall) {
      child = widget.wrapperBuilder!(context, child);
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: child,
    );
  }
}
