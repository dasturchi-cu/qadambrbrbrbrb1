import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7180097986291909/8025536468'; // Haqiqiy Banner ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7180097986291909/8025536468'; // Haqiqiy Banner ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-6135925976729797/9497923905"; // Haqiqiy Interstitial ID
    } else if (Platform.isIOS) {
      return "ca-app-pub-6135925976729797/9497923905"; // Haqiqiy Interstitial ID
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-6135925976729797/9497923905"; // Haqiqiy Rewarded ID
    } else if (Platform.isIOS) {
      return "ca-app-pub-6135925976729797/9497923905"; // Haqiqiy Rewarded ID
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}
