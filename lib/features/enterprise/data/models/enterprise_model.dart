import 'package:app/features/enterprise/domain/entities/enterprise.dart';

class EnterpriseModel extends Enterprise {
  const EnterpriseModel({
    required super.cnpj,
    required super.nomeFantasia,
    super.motorista,
    super.motoristaNome,
    super.status = true,
    super.comprovaAtiva = true,
    super.comprovaExpiraEm,
    super.limiteUsuarios = 1,
  });

  factory EnterpriseModel.fromJson(Map<String, dynamic> json) {
    return EnterpriseModel(
      cnpj: json['cnpj'] as String,
      nomeFantasia:
          json['nome_fantasia'] as String? ?? json['nomeFantasia'] as String,
      motorista: json['motorista'] as String?,
      motoristaNome: json['motorista_nome'] as String?,
      status: json['status'] as bool? ?? true,
      comprovaAtiva: json['comprova_ativa'] as bool? ?? true,
      comprovaExpiraEm: json['comprova_expira_em'] != null
          ? DateTime.parse(json['comprova_expira_em'] as String)
          : null,
      limiteUsuarios: json['limite_usuarios'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cnpj': cnpj,
      'nome_fantasia': nomeFantasia,
      'motorista': motorista,
      'motorista_nome': motoristaNome,
      'status': status,
      'comprova_ativa': comprovaAtiva,
      'comprova_expira_em': comprovaExpiraEm?.toIso8601String(),
      'limite_usuarios': limiteUsuarios,
    };
  }

  Enterprise toEntity() {
    return Enterprise(
      cnpj: cnpj,
      nomeFantasia: nomeFantasia,
      motorista: motorista,
      motoristaNome: motoristaNome,
      status: status,
      comprovaAtiva: comprovaAtiva,
      comprovaExpiraEm: comprovaExpiraEm,
      limiteUsuarios: limiteUsuarios,
    );
  }

  factory EnterpriseModel.fromEntity(Enterprise entity) {
    return EnterpriseModel(
      cnpj: entity.cnpj,
      nomeFantasia: entity.nomeFantasia,
      motorista: entity.motorista,
      motoristaNome: entity.motoristaNome,
      status: entity.status,
      comprovaAtiva: entity.comprovaAtiva,
      comprovaExpiraEm: entity.comprovaExpiraEm,
      limiteUsuarios: entity.limiteUsuarios,
    );
  }
}
