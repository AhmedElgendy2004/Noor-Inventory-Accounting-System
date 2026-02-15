import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo(this._connectivity);

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    // ConnectivityResult.none means no connection
    // Note: checkConnectivity returns a List<ConnectivityResult> in newer versions
    return !result.contains(ConnectivityResult.none);
  }
}
