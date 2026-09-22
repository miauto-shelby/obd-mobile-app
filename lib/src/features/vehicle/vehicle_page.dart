import 'package:flutter/material.dart';

import '../auth/auth_models.dart';
import 'vehicle_models.dart';
import 'vehicle_service.dart';

class VehiclePage extends StatefulWidget {
  const VehiclePage({
    super.key,
    required this.session,
    required this.apiBaseUrl,
  });

  final AuthSession session;
  final String apiBaseUrl;

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  late final VehicleService _service;
  late Future<List<Vehicle>> _vehicles;

  @override
  void initState() {
    super.initState();
    _service = VehicleService(apiBaseUrl: widget.apiBaseUrl);
    _vehicles = _service.list(widget.session);
  }

  void _reload() {
    setState(() {
      _vehicles = _service.list(widget.session);
    });
  }

  Future<void> _openCreateForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _VehicleForm(session: widget.session, service: _service),
    );
    if (created == true) _reload();
  }

  Future<void> _openVehicleDetail(Vehicle vehicle) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _VehicleDetailPage(
          session: widget.session,
          service: _service,
          vehicleId: vehicle.vehicleId,
        ),
      ),
    );
    if (updated == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFD),
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: const Text(
          'Mis vehículos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        backgroundColor: const Color(0xFF0677F9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar vehículo'),
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: _vehicles,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _VehicleError(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final vehicles = snapshot.data ?? const [];
          if (vehicles.isEmpty) {
            return const _EmptyVehicles();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            itemCount: vehicles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _VehicleCard(
              vehicle: vehicles[index],
              onTap: () => _openVehicleDetail(vehicles[index]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyVehicles extends StatelessWidget {
  const _EmptyVehicles();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Color(0xFF0677F9),
            ),
            SizedBox(height: 18),
            Text(
              'Aún no tienes vehículos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega el primero para preparar el kilometraje y las lecturas OBD2.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF687285), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});

  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: Color(0xFF0677F9),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.plate}  ·  ${vehicle.year}  ·  ${vehicle.currentMileage} km',
                      style: const TextStyle(color: Color(0xFF687285)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleDetailPage extends StatefulWidget {
  const _VehicleDetailPage({
    required this.session,
    required this.service,
    required this.vehicleId,
  });

  final AuthSession session;
  final VehicleService service;
  final String vehicleId;

  @override
  State<_VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<_VehicleDetailPage> {
  late Future<Vehicle> _vehicle;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.service.get(
      session: widget.session,
      vehicleId: widget.vehicleId,
    );
  }

  void _reload() {
    setState(() {
      _vehicle = widget.service.get(
        session: widget.session,
        vehicleId: widget.vehicleId,
      );
    });
  }

  Future<void> _editVin(Vehicle vehicle) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VinForm(
        session: widget.session,
        service: widget.service,
        vehicle: vehicle,
      ),
    );
    if (updated == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Detalle del vehículo'),
        backgroundColor: const Color(0xFFF8FAFD),
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
      ),
      body: FutureBuilder<Vehicle>(
        future: _vehicle,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _VehicleError(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final vehicle = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _VehicleInfoCard(vehicle: vehicle),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined),
                  title: const Text('VIN'),
                  subtitle: Text(vehicle.vin ?? 'Pendiente de registrar'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editVin(vehicle),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Por ahora puedes completar el VIN. Las lecturas OBD2 se agregarán cuando el adaptador esté definido.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF687285), height: 1.4),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VehicleInfoCard extends StatelessWidget {
  const _VehicleInfoCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle.nickname ?? '${vehicle.brand} ${vehicle.model}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${vehicle.plate} · ${vehicle.year}'),
            const Divider(height: 28),
            Text('Kilometraje registrado: ${vehicle.currentMileage} km'),
            if (vehicle.engine != null) Text('Motor: ${vehicle.engine}'),
            if (vehicle.fuelType != null)
              Text('Combustible: ${vehicle.fuelType}'),
            if (vehicle.transmission != null)
              Text('Transmisión: ${vehicle.transmission}'),
          ],
        ),
      ),
    );
  }
}

class _VinForm extends StatefulWidget {
  const _VinForm({
    required this.session,
    required this.service,
    required this.vehicle,
  });

  final AuthSession session;
  final VehicleService service;
  final Vehicle vehicle;

  @override
  State<_VinForm> createState() => _VinFormState();
}

class _VinFormState extends State<_VinForm> {
  late final TextEditingController _vin;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _vin = TextEditingController(text: widget.vehicle.vin ?? '');
  }

  @override
  void dispose() {
    _vin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.service.updateVin(
        session: widget.session,
        vehicleId: widget.vehicle.vehicleId,
        vin: _vin.text.trim().isEmpty ? null : _vin.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on VehicleException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registrar VIN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Déjalo vacío si aún no lo tienes.'),
            const SizedBox(height: 16),
            TextField(
              controller: _vin,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'VIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Guardar VIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleError extends StatelessWidget {
  const _VehicleError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Color(0xFF6E7787),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4A5568)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm({required this.session, required this.service});

  final AuthSession session;
  final VehicleService service;

  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _plate = TextEditingController();
  final _vin = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _mileage = TextEditingController();
  final _engine = TextEditingController();
  final _fuelType = TextEditingController();
  final _transmission = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _nickname.dispose();
    _plate.dispose();
    _vin.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _mileage.dispose();
    _engine.dispose();
    _fuelType.dispose();
    _transmission.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.create(
        session: widget.session,
        nickname: _optional(_nickname),
        plate: _plate.text,
        vin: _optional(_vin),
        brand: _brand.text,
        model: _model.text,
        year: int.parse(_year.text),
        currentMileage: int.parse(_mileage.text),
        engine: _optional(_engine),
        fuelType: _optional(_fuelType),
        transmission: _optional(_transmission),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on VehicleException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Agregar vehículo',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _field(
                      _nickname,
                      'Nombre del vehículo (opcional)',
                      requiredField: false,
                    ),
                    _field(
                      _plate,
                      'Placa',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    _field(
                      _vin,
                      'VIN (opcional)',
                      requiredField: false,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    _field(_brand, 'Marca'),
                    _field(_model, 'Modelo'),
                    _field(
                      _year,
                      'Año',
                      keyboardType: TextInputType.number,
                      numeric: true,
                    ),
                    _field(
                      _mileage,
                      'Kilometraje inicial',
                      keyboardType: TextInputType.number,
                      numeric: true,
                    ),
                    _field(_engine, 'Motor (opcional)', requiredField: false),
                    _field(
                      _fuelType,
                      'Combustible (opcional)',
                      requiredField: false,
                    ),
                    _field(
                      _transmission,
                      'Transmisión (opcional)',
                      requiredField: false,
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0677F9),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Guardar vehículo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.words,
    bool requiredField = true,
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: (value) {
          if (requiredField && (value == null || value.trim().isEmpty)) {
            return 'Este campo es obligatorio.';
          }
          if (numeric && value != null && int.tryParse(value.trim()) == null) {
            return 'Ingresa un número válido.';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }
}
