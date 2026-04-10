class SessionValidationResult {
  final bool isValid;
  final SessionInvalidReason reason;
  final String? detalhes;

  const SessionValidationResult({
    required this.isValid,
    required this.reason,
    this.detalhes,
  });

  factory SessionValidationResult.valid() {
    return const SessionValidationResult(
      isValid: true,
      reason: SessionInvalidReason.none,
    );
  }

  factory SessionValidationResult.invalid(SessionInvalidReason reason,
      {String? detalhes}) {
    return SessionValidationResult(
      isValid: false,
      reason: reason,
      detalhes: detalhes,
    );
  }

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'reason': reason.index,
        'detalhes': detalhes,
      };

  factory SessionValidationResult.fromJson(Map<String, dynamic> json) {
    return SessionValidationResult(
      isValid: json['isValid'] as bool,
      reason: SessionInvalidReason.values[json['reason'] as int],
      detalhes: json['detalhes'] as String?,
    );
  }

  // 🔥 Helper para mensagens amigáveis ao usuário
  String get mensagemAmigavel {
    switch (reason) {
      case SessionInvalidReason.none:
        return '';
      case SessionInvalidReason.expired:
        return 'Sessão expirada. Faça login novamente.';
      case SessionInvalidReason.replacedByAnotherDevice:
        return 'Sua conta foi acessada em outro dispositivo. Faça login novamente.';
      case SessionInvalidReason.licenseLimit:
        return 'Limite de usuários simultâneos atingido.';
      case SessionInvalidReason.revoked:
        return 'Sessão encerrada pelo sistema. Faça login novamente.';
      case SessionInvalidReason.timeout:
        return 'Sessão expirada por inatividade. Faça login novamente.';
      case SessionInvalidReason.logoutManual:
        return 'Você foi desconectado. Faça login novamente.';
      case SessionInvalidReason.notFound:
        return 'Sessão não encontrada. Faça login novamente.';
    }
  }
}

enum SessionInvalidReason {
  none, // Sessão válida
  expired, // Token expirado (genérico)
  replacedByAnotherDevice, // Substituído por outro dispositivo
  licenseLimit, // Limite de licença atingido
  revoked, // Revogada manualmente
  timeout, // Timeout por inatividade
  logoutManual, // Logout manual explícito
  notFound, // Sessão não encontrada
}
