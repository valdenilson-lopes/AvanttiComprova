import 'package:app/features/auth/domain/entities/user.dart';
import 'package:app/features/auth/data/models/license_model.dart';

class UserModel extends User {
  final String? token;
  final LicenseModel? license;
  final String? cnpj;
  final String? nomeEmpresa;
  final String? deviceId;

  const UserModel({
    required super.id,
    required super.nome,
    super.motorista,
    this.token,
    this.license,
    this.cnpj,
    this.nomeEmpresa,
    this.deviceId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String? ?? '',
      motorista: json['motorista'] as String?,
      token: json['token'] as String?,
      cnpj: json['cnpj'] as String?,
      nomeEmpresa: json['nome_empresa'] as String?,
      deviceId: json['deviceId'] as String?,
      license: json['license'] != null
          ? LicenseModel.fromJson(json['license'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 🔥 toJson NÃO inclui token nem deviceId (deviceId pode ir se quiser, mas token NUNCA)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      if (motorista != null) 'motorista': motorista,
      if (cnpj != null) 'cnpj': cnpj,
      if (deviceId != null) 'deviceId': deviceId,
      if (license != null) 'license': license!.toJson(),
    };
  }

  /// Versão com token para uso interno
  Map<String, dynamic> toJsonWithToken() {
    return {
      ...toJson(),
      if (token != null) 'token': token,
    };
  }

  @override
  User toEntity() {
    return User(
      id: id,
      nome: nome,
      motorista: motorista,
      cnpj: cnpj,
      nomeEmpresa: nomeEmpresa,
    );
  }

  factory UserModel.fromEntity(User entity,
      {String? token, LicenseModel? license, String? deviceId}) {
    return UserModel(
      id: entity.id,
      nome: entity.nome,
      motorista: entity.motorista,
      cnpj: entity.cnpj,
      nomeEmpresa: entity.nomeEmpresa,
      token: token,
      license: license,
      deviceId: deviceId,
    );
  }

  UserModel copyWith({
    String? id,
    String? nome,
    String? motorista,
    String? token,
    String? cnpj,
    String? nomeEmpresa,
    String? deviceId,
    LicenseModel? license,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      motorista: motorista ?? this.motorista,
      token: token ?? this.token,
      cnpj: cnpj ?? this.cnpj,
      nomeEmpresa: nomeEmpresa ?? this.nomeEmpresa,
      deviceId: deviceId ?? this.deviceId,
      license: license ?? this.license,
    );
  }
}
