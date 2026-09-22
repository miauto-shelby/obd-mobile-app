import 'package:flutter/material.dart';

import 'auth_models.dart';
import '../vehicle/vehicle_models.dart';
import '../vehicle/vehicle_page.dart';
import '../vehicle/vehicle_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.apiBaseUrl,
  });

  final AuthSession session;
  final Future<void> Function() onLogout;
  final String apiBaseUrl;

  static const _blue = Color(0xFF0677F9);
  static const _ink = Color(0xFF172033);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - progress)),
              child: child,
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AppHeader(session: session, onLogout: onLogout),
                          const SizedBox(height: 28),
                          _VehicleWelcomeCard(
                            onConnect: () => _openDiagnostics(context),
                          ),
                          const SizedBox(height: 28),
                          const _SectionTitle(
                            title: 'Acciones rápidas',
                            subtitle: 'Todo lo necesario para comenzar.',
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 520;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _ActionCard(
                                    width: compact
                                        ? constraints.maxWidth
                                        : (constraints.maxWidth - 24) / 3,
                                    icon: Icons.bluetooth_connected_rounded,
                                    iconColor: _blue,
                                    tint: const Color(0xFFEAF3FF),
                                    title: 'Conectar OBD2',
                                    description:
                                        'Vincula el adaptador del vehículo.',
                                    onTap: () => _openDiagnostics(context),
                                  ),
                                  _ActionCard(
                                    width: compact
                                        ? constraints.maxWidth
                                        : (constraints.maxWidth - 24) / 3,
                                    icon: Icons.directions_car_outlined,
                                    iconColor: const Color(0xFFF09A31),
                                    tint: const Color(0xFFFFF4E7),
                                    title: 'Mi vehículo',
                                    description:
                                        'Agrega los datos de tu vehículo.',
                                    onTap: () => _openVehicles(context),
                                  ),
                                  _ActionCard(
                                    width: compact
                                        ? constraints.maxWidth
                                        : (constraints.maxWidth - 24) / 3,
                                    icon: Icons.document_scanner_outlined,
                                    iconColor: const Color(0xFF6B7280),
                                    tint: const Color(0xFFF1F3F6),
                                    title: 'Escanear errores',
                                    description:
                                        'Lee alertas cuando conectes el OBD2.',
                                    onTap: () => _openDiagnostics(context),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          const _SectionTitle(
                            title: 'Estado del vehículo',
                            subtitle:
                                'Se actualizará al conectar el adaptador.',
                          ),
                          const SizedBox(height: 14),
                          const _VehicleStatusCard(),
                          const SizedBox(height: 28),
                          _SessionCard(session: session),
                          const SizedBox(height: 28),
                          _BottomNavigation(
                            onHome: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                            onVehicle: () => _openVehicles(context),
                            onMileage: () => _openMileage(context),
                            onProfile: () => _openProfile(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVehicles(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehiclePage(session: session, apiBaseUrl: apiBaseUrl),
      ),
    );
  }

  void _openMileage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MileagePage(session: session, apiBaseUrl: apiBaseUrl),
      ),
    );
  }

  void _openDiagnostics(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _DiagnosticsPage()));
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfilePage(session: session, onLogout: onLogout),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.session, required this.onLogout});

  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final name = session.user.fullName.trim();
    final displayName = name.isEmpty ? 'Usuario' : name;

    return Row(
      children: [
        _UserAvatar(user: session.user),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $displayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HomePage._ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Tu espacio My Auto está listo.',
                style: TextStyle(color: Color(0xFF687285), fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            try {
              await onLogout();
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error.toString())));
            }
          },
          icon: const Icon(Icons.logout_rounded),
          color: const Color(0xFF536076),
        ),
      ],
    );
  }
}

class _VehicleWelcomeCard extends StatelessWidget {
  const _VehicleWelcomeCard({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A7AFF), Color(0xFF0B63D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330677F9),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const _CarIllustration(),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aún no hay un vehículo conectado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conecta tu adaptador OBD2 para ver información y alertas del vehículo.',
                  style: TextStyle(color: Color(0xD9FFFFFF), height: 1.35),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onConnect,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: HomePage._blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                  ),
                  icon: const Icon(Icons.bluetooth_rounded, size: 18),
                  label: const Text('Conectar OBD2'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarIllustration extends StatelessWidget {
  const _CarIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color: Colors.white,
        size: 38,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: HomePage._ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF7C8493), fontSize: 13),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 184),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5EAF1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(height: 30),
                Text(
                  title,
                  style: const TextStyle(
                    color: HomePage._ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF778195),
                    height: 1.3,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  const _VehicleStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _PendingMetric(
              icon: Icons.speed_rounded,
              title: 'Kilometraje',
              value: '—',
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: _PendingMetric(
              icon: Icons.local_gas_station_outlined,
              title: 'Consumo',
              value: '—',
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: _PendingMetric(
              icon: Icons.error_outline_rounded,
              title: 'Alertas',
              value: '—',
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingMetric extends StatelessWidget {
  const _PendingMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7E8797), size: 21),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: HomePage._ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7C8493), fontSize: 12),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 58, color: const Color(0xFFE7EBF1));
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final email = session.user.email.trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: HomePage._blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesión protegida',
                  style: TextStyle(
                    color: HomePage._ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.isEmpty
                      ? 'Cuenta validada con Google'
                      : 'Cuenta validada: $email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF66748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF718096)),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.onHome,
    required this.onVehicle,
    required this.onMileage,
    required this.onProfile,
  });

  final VoidCallback onHome;
  final VoidCallback onVehicle;
  final VoidCallback onMileage;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E2EE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.home_outlined,
              label: 'Inicio',
              active: true,
              onTap: onHome,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.directions_car_outlined,
              label: 'Vehículo',
              onTap: onVehicle,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.speed_outlined,
              label: 'Kilometraje',
              onTap: onMileage,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.person_outline,
              label: 'Perfil',
              onTap: onProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? HomePage._blue : const Color(0xFF6E7787);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MileagePage extends StatefulWidget {
  const _MileagePage({required this.session, required this.apiBaseUrl});

  final AuthSession session;
  final String apiBaseUrl;

  @override
  State<_MileagePage> createState() => _MileagePageState();
}

class _MileagePageState extends State<_MileagePage> {
  late final VehicleService _service;
  late Future<List<Vehicle>> _vehicles;

  @override
  void initState() {
    super.initState();
    _service = VehicleService(apiBaseUrl: widget.apiBaseUrl);
    _vehicles = _service.list(widget.session);
  }

  void _reload() {
    setState(() => _vehicles = _service.list(widget.session));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Kilometraje'),
        backgroundColor: const Color(0xFFF8FAFD),
        foregroundColor: HomePage._ink,
        elevation: 0,
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: _vehicles,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _SimpleError(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final vehicles = snapshot.data ?? const [];
          if (vehicles.isEmpty) {
            return const _EmptyMileage();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: vehicles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _MileageCard(vehicle: vehicles[index]),
          );
        },
      ),
    );
  }
}

class _MileageCard extends StatelessWidget {
  const _MileageCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.speed_rounded, color: HomePage._blue, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plate,
                    style: const TextStyle(color: Color(0xFF687285)),
                  ),
                ],
              ),
            ),
            Text(
              '${vehicle.currentMileage} km',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMileage extends StatelessWidget {
  const _EmptyMileage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Cuando agregues un vehículo, aquí verás el kilometraje que registraste. Las lecturas automáticas se habilitarán con el adaptador OBD2.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF687285), height: 1.4),
        ),
      ),
    );
  }
}

class _DiagnosticsPage extends StatelessWidget {
  const _DiagnosticsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Diagnóstico OBD2'),
        backgroundColor: const Color(0xFFF8FAFD),
        foregroundColor: HomePage._ink,
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bluetooth_searching_rounded,
                color: HomePage._blue,
                size: 64,
              ),
              SizedBox(height: 18),
              Text(
                'Diagnóstico en preparación',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Esta pantalla quedará lista para conectar el adaptador, leer errores y mostrar alertas cuando se confirme el modelo de OBD2 compatible.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF687285), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.session, required this.onLogout});

  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: const Color(0xFFF8FAFD),
        foregroundColor: HomePage._ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileIdentity(user: user),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.verified_user_outlined,
                color: HomePage._blue,
              ),
              title: Text('Cuenta protegida'),
              subtitle: Text('Tu inicio de sesión está validado con Google.'),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await onLogout();
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _UserAvatar(user: user),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isEmpty ? 'Usuario My Auto' : user.fullName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email.isEmpty ? 'Cuenta Google' : user.email,
                    style: const TextStyle(color: Color(0xFF687285)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleError extends StatelessWidget {
  const _SimpleError({required this.message, required this.onRetry});

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final fullName = user.fullName.trim();
    final initials = fullName.isEmpty
        ? '?'
        : fullName
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();
    final photoUrl = user.photoUrl.trim();

    return CircleAvatar(
      radius: 25,
      backgroundColor: const Color(0xFFEAF3FF),
      backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
      child: photoUrl.isEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: HomePage._blue,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}
