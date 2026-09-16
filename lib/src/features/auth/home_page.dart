import 'package:flutter/material.dart';

import 'auth_models.dart';
import '../vehicle/vehicle_page.dart';

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
                            onConnect: () => _showPendingAction(
                              context,
                              'La conexión OBD2 estará disponible en el siguiente módulo.',
                            ),
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
                                    onTap: () => _showPendingAction(
                                      context,
                                      'La conexión OBD2 estará disponible en el siguiente módulo.',
                                    ),
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
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => VehiclePage(
                                          session: session,
                                          apiBaseUrl: apiBaseUrl,
                                        ),
                                      ),
                                    ),
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
                                    onTap: () => _showPendingAction(
                                      context,
                                      'El escaneo estará disponible después de integrar OBD2.',
                                    ),
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
                          const _BottomNavigation(),
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

  void _showPendingAction(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E2EE)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.home_outlined,
              label: 'Inicio',
              active: true,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.directions_car_outlined,
              label: 'Vehículo',
            ),
          ),
          Expanded(
            child: _NavigationItem(icon: Icons.person_outline, label: 'Perfil'),
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
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? HomePage._blue : const Color(0xFF6E7787);
    return Padding(
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
