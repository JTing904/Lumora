import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/utils/platform/storage_space_helper.dart';

void main() {
  test('measures free space on Windows without wmic', () async {
    final info = await StorageSpaceHelper.getAvailableSpace(
      Directory.systemTemp.path,
    );

    expect(info, isNotNull);
    expect(info!.totalBytes, greaterThan(0));
    expect(info.freeBytes, inInclusiveRange(1, info.totalBytes));
  }, skip: Platform.isWindows ? false : 'Windows-only API');
}
