class P2PException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  P2PException(this.message, {this.stackTrace});

  @override
  String toString() => 'P2PException: $message${stackTrace != null ? '\n$stackTrace' : ''}';
}

class P2PServerException extends P2PException {
  P2PServerException(super.message, {super.stackTrace});
}

class P2PConnectionException extends P2PException {
  P2PConnectionException(super.message, {super.stackTrace});
}

class P2PDiscoveryException extends P2PException {
  P2PDiscoveryException(super.message, {super.stackTrace});
}

class P2PMessageException extends P2PException {
  P2PMessageException(super.message, {super.stackTrace});
}

class P2PFileTransferException extends P2PException {
  P2PFileTransferException(super.message, {super.stackTrace});
}

class P2PNetworkException extends P2PException {
  P2PNetworkException(super.message, {super.stackTrace});
}