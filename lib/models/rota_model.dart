class RotaModel {
  final int? id;
  final String name;
  final String partida;
  final String destino;

  RotaModel({this.id, required this.name, required this.partida, required this.destino});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'partida': partida,
      'destino': destino,
    };
  }

  factory RotaModel.fromMap(Map<String, dynamic> map) {
    return RotaModel(
      id: map['id'],
      name: map['name'],
      partida: map['partida'],
      destino: map['destino'],
    );
  }

  RotaModel copyWith({int? id, String? name, String? partida, String? destino}) {
    return RotaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      partida: partida ?? this.partida,
      destino: destino ?? this.destino,
    );
  }
}
