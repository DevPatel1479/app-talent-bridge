import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_message_handler.dart';

// The background task callback function.
// This must be a top-level function.
Future<void> backgroundTaskCallback() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult != ConnectivityResult.none) {
    await OfflineMessageHandler.sendOfflineMessages();
  }
}
