import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String nome;
  final String? motorista;
  final String? cnpj;
  final String? nomeEmpresa;

  const User({
    required this.id,
    required this.nome,
    this.motorista,
    this.cnpj,
    this.nomeEmpresa,
  });

  @override
  List<Object?> get props => [id, nome, motorista, cnpj, nomeEmpresa];
}
