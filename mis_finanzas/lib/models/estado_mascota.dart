enum EstadoMascota {
  hucha, bolsa, celebra, // positivos
  ahorro, escritorio, meta, // neutros / ahorro
  preocupado, sudando, panico; // alerta

  String get asset => 'assets/mascota/$name.png';
}