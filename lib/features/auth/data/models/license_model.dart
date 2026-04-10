import 'package:equatable/equatable.dart';

class LicenseModel extends Equatable {
  final int limite;
  final int emUso;
  final DateTime expiraEm;
  final bool valida;

  const LicenseModel({
    required this.limite,
    required this.emUso,
    required this.expiraEm,
    required this.valida,
  });

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      limite: json['limite'] as int,
      emUso: json['emUso'] as int,
      expiraEm: DateTime.parse(json['expiraEm'] as String),
      valida: json['valida'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limite': limite,
      'emUso': emUso,
      'expiraEm': expiraEm.toIso8601String(),
      'valida': valida,
    };
  }

  @override
  List<Object?> get props => [limite, emUso, expiraEm, valida];
}
