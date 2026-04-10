import 'package:equatable/equatable.dart';

class Enterprise extends Equatable {
  final String cnpj;
  final String nomeFantasia;
  final String? razaoSocialCliente;
  final String? motorista;
  final String? motoristaNome;
  final bool status;
  final bool comprovaAtiva;
  final DateTime? comprovaExpiraEm;
  final int limiteUsuarios;

  const Enterprise({
    required this.cnpj,
    required this.nomeFantasia,
    this.razaoSocialCliente,
    this.motorista,
    this.motoristaNome,
    this.status = true,
    this.comprovaAtiva = true,
    this.comprovaExpiraEm,
    this.limiteUsuarios = 1,
  });

  @override
  List<Object?> get props => [
        cnpj,
        nomeFantasia,
        razaoSocialCliente,
        motorista,
        motoristaNome,
        status,
        comprovaAtiva,
        comprovaExpiraEm,
        limiteUsuarios
      ];

  // getter para exibir no dropdown
  String get displayName => razaoSocialCliente ?? nomeFantasia;

  // getter para o texto do motorista formatado
  String get motoristaFormatado {
    if (motorista == null || motorista!.isEmpty) return '';
    return '$motorista - $nomeFantasia';
  }

  // Verifica se a licença está válida
  bool get licencaValida {
    if (!comprovaAtiva) return false;
    if (comprovaExpiraEm == null) return true;
    return DateTime.now().isBefore(comprovaExpiraEm!);
  }

  // Método utilitário para cópia
  Enterprise copyWith({
    String? cnpj,
    String? nomeFantasia,
    String? motorista,
    String? motoristaName,
    bool? status,
    bool? comprovaAtiva,
    DateTime? comprovaExpiraEm,
    int? limiteUsuarios,
  }) {
    return Enterprise(
      cnpj: cnpj ?? this.cnpj,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      motorista: motorista ?? this.motorista,
      motoristaNome: motoristaName ?? motoristaName,
      status: status ?? this.status,
      comprovaAtiva: comprovaAtiva ?? this.comprovaAtiva,
      comprovaExpiraEm: comprovaExpiraEm ?? this.comprovaExpiraEm,
      limiteUsuarios: limiteUsuarios ?? this.limiteUsuarios,
    );
  }
}
