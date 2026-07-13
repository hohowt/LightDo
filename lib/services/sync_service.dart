import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crdt/crdt.dart';

import '../models/todo_item.dart';

typedef SyncServerInfo = ({String ip, int port, String token});

class SyncService {
  SyncService({required this.nodeId}) {
    _crdt = MapCrdt<String, Map<String, dynamic>>(nodeId);
  }

  final String nodeId;
  late MapCrdt<String, Map<String, dynamic>> _crdt;

  // Server state (desktop)
  HttpServer? _server;
  String? _token;
  final List<WebSocket> _clients = [];
  SyncServerInfo? _serverInfo;

  // Client state (Android)
  WebSocket? _clientSocket;
  StreamSubscription<dynamic>? _clientSub;
  String? _lastWsUrl;
  String? _lastToken;
  bool _intentionalDisconnect = false;

  final _todosController = StreamController<List<TodoItem>>.broadcast();
  Stream<List<TodoItem>> get todosStream => _todosController.stream;

  SyncServerInfo? get serverInfo => _serverInfo;
  bool get isServerRunning => _server != null;
  bool get isClientConnected => _clientSocket != null;
  int get connectedClientCount => _clients.length;

  // ── Init ──────────────────────────────────────────────────────────

  void initFromRecords(Map<String, dynamic> raw) {
    if (raw.isEmpty) {
      _crdt = MapCrdt<String, Map<String, dynamic>>(nodeId);
      return;
    }
    // Decode directly into seed records to avoid "Duplicate node" error
    // that occurs when merging records with the same nodeId.
    final canonicalTime = Hlc.now(nodeId);
    final records = CrdtJson.decode<String, Map<String, dynamic>>(
      jsonEncode(raw),
      canonicalTime,
      valueDecoder: (_, v) => (v as Map<String, dynamic>),
    );
    _crdt = MapCrdt<String, Map<String, dynamic>>(nodeId, records);
  }

  void initEmpty() {
    _crdt = MapCrdt<String, Map<String, dynamic>>(nodeId);
  }

  // ── Local mutations ───────────────────────────────────────────────

  void recordMutation(TodoItem todo) {
    _crdt.put(todo.id, todo.toJson());
  }

  void recordDeletion(String id) {
    _crdt.delete(id);
  }

  List<TodoItem> get currentTodos {
    return _crdt.map.entries
        .map((e) => TodoItem.fromJson(e.value!))
        .where((t) => !t.isDeleted)
        .toList();
  }

  Map<String, dynamic> exportRecords() {
    return jsonDecode(_crdt.toJson()) as Map<String, dynamic>;
  }

  // ── Desktop: HTTP/WebSocket server ────────────────────────────────

  Future<SyncServerInfo> startServer() async {
    _token = _generateToken();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final port = _server!.port;
    final ip = await _getLocalIp();
    _serverInfo = (ip: ip, port: port, token: _token!);
    _server!.listen(_handleHttpRequest);
    return _serverInfo!;
  }

  Future<void> stopServer() async {
    for (final ws in List<WebSocket>.from(_clients)) {
      await ws.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _token = null;
    _serverInfo = null;
  }

  Future<void> _handleHttpRequest(HttpRequest req) async {
    final queryToken = req.uri.queryParameters['token'];
    if (queryToken != _token) {
      req.response.statusCode = 401;
      await req.response.close();
      return;
    }

    if (!WebSocketTransformer.isUpgradeRequest(req)) {
      req.response.statusCode = 400;
      await req.response.close();
      return;
    }

    final ws = await WebSocketTransformer.upgrade(req);
    _clients.add(ws);
    // Send current full state to newly connected client
    ws.add(_buildStateMessage());

    ws.listen(
      (data) => _handleServerMessage(ws, data as String),
      onDone: () => _clients.remove(ws),
      onError: (_) => _clients.remove(ws),
      cancelOnError: true,
    );
  }

  void _handleServerMessage(WebSocket sender, String data) {
    final msg = jsonDecode(data) as Map<String, dynamic>;
    if (msg['type'] != 'push') return;
    _mergePayload(msg);
    final stateMsg = _buildStateMessage();
    for (final ws in _clients) {
      ws.add(stateMsg);
    }
    _todosController.add(currentTodos);
  }

  // ── Android: WebSocket client ─────────────────────────────────────

  Future<void> connectToServer(String wsUrl, String token) async {
    _intentionalDisconnect = false;
    _lastWsUrl = wsUrl;
    _lastToken = token;
    await _doConnect(wsUrl, token);
  }

  Future<void> _doConnect(String wsUrl, String token) async {
    await disconnect();
    final uri = Uri.parse(wsUrl).replace(
      queryParameters: {'token': token},
    );
    _clientSocket = await WebSocket.connect(uri.toString());
    _clientSub = _clientSocket!.listen(
      _handleClientMessage,
      onDone: _onClientDisconnected,
      onError: (_) => _onClientDisconnected(),
      cancelOnError: true,
    );
    _clientSocket!.add(_buildPushMessage());
  }

  /// Call when app returns to foreground to restore dropped connection.
  Future<void> reconnectIfNeeded() async {
    if (_intentionalDisconnect) return;
    if (_clientSocket != null) return;
    final url = _lastWsUrl;
    final token = _lastToken;
    if (url == null || token == null) return;
    try {
      await _doConnect(url, token);
    } catch (_) {
      // Server may be unreachable; silently ignore, user can re-scan.
    }
  }

  void _handleClientMessage(dynamic data) {
    final msg = jsonDecode(data as String) as Map<String, dynamic>;
    if (msg['type'] != 'state') return;
    _mergePayload(msg);
    _todosController.add(currentTodos);
  }

  void _onClientDisconnected() {
    _clientSocket = null;
    _clientSub?.cancel();
    _clientSub = null;
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _lastWsUrl = null;
    _lastToken = null;
    await _clientSocket?.close();
    _onClientDisconnected();
  }

  /// Call after any local mutation to push changes to peers.
  /// On Android: sends to server. On desktop: broadcasts to all clients.
  void notifyPeers() {
    if (_clientSocket != null) {
      _clientSocket!.add(_buildPushMessage());
    }
    if (_clients.isNotEmpty) {
      final msg = _buildStateMessage();
      for (final ws in _clients) {
        ws.add(msg);
      }
    }
  }

  /// Call after recordMutation on Android to push change to server.
  void pushMutation() {
    _clientSocket?.add(_buildPushMessage());
  }

  // ── CRDT helpers ──────────────────────────────────────────────────

  void _mergePayload(Map<String, dynamic> payload) {
    final remoteJson = jsonEncode(payload['records']);
    // Decode first, then filter out records with our own nodeId to avoid
    // "Duplicate node" HLC error when the remote echoes back our own records.
    final records = CrdtJson.decode<String, Map<String, dynamic>>(
      remoteJson,
      _crdt.canonicalTime,
      valueDecoder: (_, v) => v as Map<String, dynamic>,
    );
    records.removeWhere((_, record) => record.hlc.nodeId == nodeId);
    if (records.isNotEmpty) {
      _crdt.merge(records);
    }
  }

  String _buildStateMessage() => jsonEncode({
        'type': 'state',
        'nodeId': nodeId,
        'records': exportRecords(),
      });

  String _buildPushMessage() => jsonEncode({
        'type': 'push',
        'nodeId': nodeId,
        'records': exportRecords(),
      });

  // ── Helpers ───────────────────────────────────────────────────────

  String _generateToken() {
    final rng = Random.secure();
    return List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return '127.0.0.1';
  }

  void dispose() {
    _todosController.close();
    stopServer();
    disconnect();
  }
}
