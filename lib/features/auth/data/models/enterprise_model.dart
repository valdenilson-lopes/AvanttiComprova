import 'package:app/features/enterprise/domain/entities/enterprise.dart';

class EnterpriseModel extends Enterprise {
  const EnterpriseModel({
    required super.cnpj,
    required super.nomeFantasia,
  });

  factory EnterpriseModel.fromJson(Map<String, dynamic> json) {
    return EnterpriseModel(
      cnpj: json['cnpj'] as String,
      nomeFantasia: json['nomeFantasia'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cnpj': cnpj,
      'nomeFantasia': nomeFantasia,
    };
  }

  // Converter Model para Entity
  Enterprise toEntity() {
    return Enterprise(cnpj: cnpj, nomeFantasia: nomeFantasia);
  }

  // Criar Model a partir de Entity
  factory EnterpriseModel.fromEntity(Enterprise entity) {
    return EnterpriseModel(
      cnpj: entity.cnpj,
      nomeFantasia: entity.nomeFantasia,
    );
  }
}
