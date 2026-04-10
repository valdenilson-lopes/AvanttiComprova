import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';

class InternetChecker {
  static final InternetChecker _instance = InternetChecker._internal();
  factory InternetChecker() => _instance;
  InternetChecker._internal();

  final Connectivity _connectivity = Connectivity();

  // Cache do último estado para evitar verificações repetidas
  bool? _lastKnownOnline;
  DateTime? _lastCheckTime;
  static const Duration _cacheDuration = Duration(seconds: 5);

  // Hosts para ping de fallback (mais confiáveis que IP fixo)
  static const List<String> _fallbackHosts = [
    'google.com',
    'cloudflare.com',
    'microsoft.com',
  ];

  /// 🔥 VERIFICAÇÃO ROBUSTA DE CONECTIVIDADE
  /// 1. Primeiro verifica connectivity_plus (rápido)
  /// 2. Se houver conexão, faz ping de confirmação (fallback)
  Future<bool> isOnline() async {
    // Usa cache se ainda estiver válido
    if (_lastKnownOnline != null &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < _cacheDuration) {
      return _lastKnownOnline!;
    }

    try {
      // Passo 1: Verifica conectividade via connectivity_plus
      final connectivityResult = await _connectivity.checkConnectivity();

      // Se não tem conexão alguma, retorna false imediatamente
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _updateCache(false);
        return false;
      }

      // Passo 2: Tem conexão de rede, mas pode ser apenas rede local sem internet
      // Faz ping de confirmação (fallback)
      final hasInternet = await _verifyWithPing();

      _updateCache(hasInternet);
      return hasInternet;
    } catch (e) {
      print('❌ [InternetChecker] Erro ao verificar conectividade: $e');
      _updateCache(false);
      return false;
    }
  }

  /// 🔥 VERIFICAÇÃO COM PING (FALLBACK)
  Future<bool> _verifyWithPing() async {
    // Tenta cada host até um responder
    for (final host in _fallbackHosts) {
      try {
        final result = await InternetAddress.lookup(host).timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Timeout ao resolver $host'),
        );

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('✅ [InternetChecker] Ping bem-sucedido para $host');
          return true;
        }
      } on SocketException catch (_) {
        print('⚠️ [InternetChecker] Falha no ping para $host');
        continue;
      } on TimeoutException catch (_) {
        print('⚠️ [InternetChecker] Timeout no ping para $host');
        continue;
      } catch (e) {
        print('⚠️ [InternetChecker] Erro no ping para $host: $e');
        continue;
      }
    }

    print('❌ [InternetChecker] Todos os hosts de fallback falharam');
    return false;
  }

  void _updateCache(bool value) {
    _lastKnownOnline = value;
    _lastCheckTime = DateTime.now();
  }

  /// 🔥 STREAM DE MUDANÇAS DE CONECTIVIDADE (JÁ CORRETO)
  Stream<ConnectivityResult> get onConnectivityChange =>
      _connectivity.onConnectivityChanged
          .map((List<ConnectivityResult> results) {
        if (results.isEmpty) return ConnectivityResult.none;
        return results.first;
      });

  /// 🔥 STREAM QUE EMITE MUDANÇAS DE ESTADO ONLINE/OFFLINE
  Stream<bool> get onOnlineStatusChange =>
      onConnectivityChange.asyncMap((_) async => await isOnline());

  /// 🔥 FORÇA INVALIDAÇÃO DO CACHE
  void invalidateCache() {
    _lastKnownOnline = null;
    _lastCheckTime = null;
  }
}
