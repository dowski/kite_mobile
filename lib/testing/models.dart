import 'package:flutter/widgets.dart';
import 'package:kite_mobile/models.dart';

final class FakeImagePreloader implements ImagePreloader {
  static const delay = Duration(milliseconds: 500);

  const FakeImagePreloader();

  @override
  Future<void> precacheImage(
    BuildContext context,
    ImageProvider<Object> image,
  ) {
    return Future.delayed(delay);
  }
}
