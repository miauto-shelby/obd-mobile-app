import 'package:flutter/material.dart';

enum ObdConnectionPhase {
  needsAdapter,
  readyToSearch,
  searching,
  connected,
  reading,
  error,
}

extension ObdConnectionPhaseText on ObdConnectionPhase {
  String get title => switch (this) {
    ObdConnectionPhase.needsAdapter => 'Adaptador pendiente',
    ObdConnectionPhase.readyToSearch => 'Listo para conectar',
    ObdConnectionPhase.searching => 'Buscando adaptador',
    ObdConnectionPhase.connected => 'Adaptador conectado',
    ObdConnectionPhase.reading => 'Leyendo el vehículo',
    ObdConnectionPhase.error => 'No fue posible conectar',
  };

  String get description => switch (this) {
    ObdConnectionPhase.needsAdapter =>
      'Aún necesitamos confirmar el adaptador OBD2 compatible con Android y iPhone.',
    ObdConnectionPhase.readyToSearch =>
      'El vehículo está listo para iniciar la búsqueda del adaptador.',
    ObdConnectionPhase.searching =>
      'La aplicación está buscando adaptadores cercanos por Bluetooth.',
    ObdConnectionPhase.connected =>
      'El adaptador fue reconocido y se puede iniciar la lectura.',
    ObdConnectionPhase.reading =>
      'La aplicación está obteniendo datos del vehículo.',
    ObdConnectionPhase.error =>
      'Revisa Bluetooth, el adaptador y que el vehículo esté encendido.',
  };

  IconData get icon => switch (this) {
    ObdConnectionPhase.needsAdapter => Icons.bluetooth_disabled_rounded,
    ObdConnectionPhase.readyToSearch => Icons.bluetooth_rounded,
    ObdConnectionPhase.searching => Icons.bluetooth_searching_rounded,
    ObdConnectionPhase.connected => Icons.bluetooth_connected_rounded,
    ObdConnectionPhase.reading => Icons.monitor_heart_outlined,
    ObdConnectionPhase.error => Icons.bluetooth_disabled_rounded,
  };
}

class ObdConnectionPage extends StatelessWidget {
  const ObdConnectionPage({
    super.key,
    this.phase = ObdConnectionPhase.needsAdapter,
  });

  final ObdConnectionPhase phase;

  static const _blue = Color(0xFF0677F9);
  static const _ink = Color(0xFF172033);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Diagnóstico OBD2'),
        backgroundColor: const Color(0xFFF8FAFD),
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(phase.icon, color: _blue, size: 62),
                const SizedBox(height: 16),
                Text(
                  phase.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phase.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF687285), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Así funcionará el proceso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          const _ObdStep(
            number: '1',
            title: 'Registrar el vehículo',
            detail: 'Ya puedes completar sus datos y VIN en Mi vehículo.',
          ),
          const _ObdStep(
            number: '2',
            title: 'Conectar el adaptador',
            detail: 'La app buscará el adaptador por Bluetooth.',
          ),
          const _ObdStep(
            number: '3',
            title: 'Leer y validar datos',
            detail: 'Solo se guardarán lecturas que el backend valide.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Diagnóstico en preparación: esta pantalla no intenta conectarse todavía ni inventa datos de kilometraje.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF687285), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ObdStep extends StatelessWidget {
  const _ObdStep({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFEAF3FF),
            child: Text(
              number,
              style: const TextStyle(
                color: ObdConnectionPage._blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ObdConnectionPage._ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(color: Color(0xFF687285), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
