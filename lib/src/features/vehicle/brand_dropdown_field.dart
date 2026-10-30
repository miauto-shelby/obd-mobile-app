import 'package:flutter/material.dart';

import '../auth/auth_models.dart';
import 'vehicle_service.dart';

class BrandDropdownField extends StatefulWidget {
  const BrandDropdownField({
    super.key,
    required this.session,
    required this.service,
    required this.controller,
  });

  final AuthSession session;
  final VehicleService service;
  final TextEditingController controller;

  @override
  State<BrandDropdownField> createState() => _BrandDropdownFieldState();
}

class _BrandDropdownFieldState extends State<BrandDropdownField> {
  late Future<List<String>> _brands;

  @override
  void initState() {
    super.initState();
    _brands = widget.service.listBrands(widget.session);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _brands,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return _errorField();
        }
        final brands = snapshot.data ?? const <String>[];
        final selected = brands.contains(widget.controller.text)
            ? widget.controller.text
            : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            iconEnabledColor: const Color(0xFF536076),
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: _decoration('Marca'),
            hint: const Text(
              'Selecciona una marca',
              style: TextStyle(
                color: Color(0xFF687285),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            items: brands
                .map(
                  (brand) => DropdownMenuItem(value: brand, child: Text(brand)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => widget.controller.text = value ?? ''),
            validator: (value) =>
                value == null ? 'Selecciona una marca.' : null,
          ),
        );
      },
    );
  }

  Widget _errorField() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton.icon(
      onPressed: () =>
          setState(() => _brands = widget.service.listBrands(widget.session)),
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('No fue posible cargar las marcas. Reintentar'),
    ),
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF5E6A7D)),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFF0677F9),
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF9AA5B5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF0677F9), width: 2),
    ),
  );
}
