import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class CustomCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final Widget Function(BuildContext, ImageProvider)? imageBuilder;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const CustomCachedNetworkImage(
      {super.key,
      required this.imageUrl,
      this.imageBuilder,
      this.placeholder,
      this.errorWidget,
      this.fit,
      this.width,
      this.height});

  @override
  State<CustomCachedNetworkImage> createState() =>
      _CustomCachedNetworkImageState();
}

class _CustomCachedNetworkImageState extends State<CustomCachedNetworkImage> {
  Future<File?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _getCachedImage(widget.imageUrl);
  }

  @override
  void didUpdateWidget(CustomCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _getCachedImage(widget.imageUrl);
    }
  }

  String _generateFilename(String url) {
    String safeUrl = url.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    if (safeUrl.length > 100) {
      safeUrl =
          '${safeUrl.substring(0, 50)}_${safeUrl.substring(safeUrl.length - 49)}';
    }
    return 'img_${safeUrl.hashCode.abs()}';
  }

  Future<File?> _getCachedImage(String imageUrl) async {
    try {
      final String filename = _generateFilename(imageUrl);
      final Directory cacheDir = await getTemporaryDirectory();
      final String cachePath = cacheDir.path;
      final File imageFile = File(path.join(cachePath, filename));

      if (await imageFile.exists()) {
        final DateTime fileLastModified = await imageFile.lastModified();
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(fileLastModified);

        if (difference.inDays < 7) {
          return imageFile;
        }
      }

      final http.Response response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        await imageFile.writeAsBytes(response.bodyBytes);
        return imageFile;
      } else {
        return null;
      }
    } catch (e) {
      print('Error caching image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder != null
              ? widget.placeholder!(context, widget.imageUrl)
              : Center(child: CircularProgressIndicator(color: Colors.teal));
        } else if (snapshot.hasError || snapshot.data == null) {
          return widget.errorWidget != null
              ? widget.errorWidget!(context, widget.imageUrl, snapshot.error)
              : Center(child: Icon(Icons.error, color: Colors.red));
        } else {
          final FileImage imageProvider = FileImage(snapshot.data!);
        
          if (widget.imageBuilder != null) {
            return widget.imageBuilder!(context, imageProvider);
          } else {
            return Image(
                image: imageProvider,
                fit: widget.fit ?? BoxFit.cover,
                width: widget.width,
                height: widget.height,
                errorBuilder: (context, error, stackTrace) =>
                    widget.errorWidget != null
                        ? widget.errorWidget!(context, widget.imageUrl, error)
                        : Center(child: Icon(Icons.error, color: Colors.red)));
          }
        }
      });
}

class CustomDateFormat {
  static String format(DateTime dateTime, String pattern) {
    String result = pattern;
    if (result.contains('yyyy')) {
      result =
          result.replaceAll('yyyy', dateTime.year.toString().padLeft(4, '0'));
    }
    if (result.contains('MM')) {
      result =
          result.replaceAll('MM', dateTime.month.toString().padLeft(2, '0'));
    } else if (result.contains('M')) {
      result = result.replaceAll('M', dateTime.month.toString());
    }
    if (result.contains('dd')) {
      result = result.replaceAll('dd', dateTime.day.toString().padLeft(2, '0'));
    } else if (result.contains('d')) {
      result = result.replaceAll('d', dateTime.day.toString());
    }
    if (result.contains('hh')) {
      int hour12 = dateTime.hour % 12;
      if (hour12 == 0) hour12 = 12;
      result = result.replaceAll('hh', hour12.toString().padLeft(2, '0'));
    } else if (result.contains('h')) {
      int hour12 = dateTime.hour % 12;
      if (hour12 == 0) hour12 = 12;
      result = result.replaceAll('h', hour12.toString());
    }
    if (result.contains('HH')) {
      result =
          result.replaceAll('HH', dateTime.hour.toString().padLeft(2, '0'));
    } else if (result.contains('H')) {
      result = result.replaceAll('H', dateTime.hour.toString());
    }
    if (result.contains('mm')) {
      result =
          result.replaceAll('mm', dateTime.minute.toString().padLeft(2, '0'));
    } else if (result.contains('m')) {
      result = result.replaceAll('m', dateTime.minute.toString());
    }
    if (result.contains('ss')) {
      result =
          result.replaceAll('ss', dateTime.second.toString().padLeft(2, '0'));
    } else if (result.contains('s')) {
      result = result.replaceAll('s', dateTime.second.toString());
    }
    if (result.contains('a')) {
      result = result.replaceAll('a', dateTime.hour < 12 ? 'AM' : 'PM');
    }
    return result;
  }

  static String formatDateTime(DateTime dateTime) {
    return format(dateTime, 'yyyy-MM-dd hh:mm a');
  }
}
