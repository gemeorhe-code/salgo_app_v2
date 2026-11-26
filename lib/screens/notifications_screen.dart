import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../data/notifications_repository.dart';
import '../data/places_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/salgo_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsRepository _notifRepo;
  late final BuildContext _context;
  bool _isMarking = false;

  @override
  void initState() {
    super.initState();
    _notifRepo = context.read<NotificationsRepository>();
    _context = context;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SalgoAppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        extraActions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: _isMarking ? null : () => unawaited(_markAllRead()),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _notifRepo,
        builder: (context, _) => Column(
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: _notifRepo.syncError,
              builder: (context, error, _) {
                if (error == null) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceL,
                    AppDimensions.spaceM,
                    AppDimensions.spaceL,
                    0,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.orangeDark,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusS,
                    ),
                  ),
                  child: Text(
                    error,
                    style: AppTypography.body(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
            if (_notifRepo.isLoadingStates || _isMarking)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.teal,
                backgroundColor: AppColors.orange,
              ),
            SwitchListTile(
              value: _notifRepo.notificationsEnabled,
              onChanged: _notifRepo.isLoadingStates || _isMarking
                  ? null
                  : _setGlobalEnabled,
              title: Text(
                'Activar sugerencias',
                style: AppTypography.label(color: AppColors.textDark),
              ),
              subtitle: Text(
                'Recibe planes según tus preferencias',
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.textDark.withValues(alpha: 0.7),
                ),
              ),
              activeThumbColor: AppColors.teal,
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final dismissedIds = _notifRepo.dismissedIds;
    final visible = _notifRepo.notifications
        .where(
          (AppNotification notification) =>
              !dismissedIds.contains(notification.placeId),
        )
        .toList();

    if (visible.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceL,
        AppDimensions.spaceL,
        AppDimensions.spaceL,
        AppDimensions.spaceXXL + 16,
      ),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final notif = visible[index];
        return _NotificationCard(
          notification: notif,
          onTap: () => unawaited(_onNotificationTap(notif)),
          onDismiss: () => unawaited(_onDismiss(notif)),
        );
      },
      addAutomaticKeepAlives: true,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 80, color: AppColors.teal),
          const SizedBox(height: AppDimensions.spaceL),
          Text(
            'Aún no tienes sugerencias.',
            style: AppTypography.title(fontSize: 18),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            !_notifRepo.notificationsEnabled
                ? 'Activa las sugerencias para volver a recibirlas.'
                : _notifRepo.hasPreferences
                ? 'No hay lugares que coincidan con tus preferencias.'
                : 'Llena el formulario de preferencias para recibirlas.',
            style: AppTypography.label(
              color: AppColors.textDark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXXL),
          PrimaryButton(
            label: 'Ir al formulario',
            onPressed: () {
              Navigator.pushNamed(_context, AppRoutes.preferences);
            },
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _setGlobalEnabled(bool enabled) async {
    setState(() => _isMarking = true);
    try {
      await _notifRepo.setGlobalEnabled(enabled);
    } on Object {
      _showError(
        'No se pudo actualizar la preferencia. Se guardó en este dispositivo.',
      );
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _isMarking = true);
    try {
      await _notifRepo.markAllRead();
    } on Object {
      _showError('No se pudo marcar todo como leído. Se guardó en este dispositivo.');
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  Future<void> _onNotificationTap(AppNotification notif) async {
    try {
      await _notifRepo.markRead(notif.placeId);
    } on Object {
      _showError('No se pudo marcar la notificación como leída.');
    }
    if (!mounted) return;
    final place = PlacesScope.of(_context).placeById(notif.placeId);
    if (place != null) {
      Navigator.pushNamed(_context, AppRoutes.placeDetail, arguments: place.id);
    }
    setState(() {});
  }

  Future<void> _onDismiss(AppNotification notif) async {
    setState(() => _isMarking = true);
    bool failed = false;
    try {
      await _notifRepo.markDismissed(notif.placeId);
    } on Object {
      failed = true;
      _showError('No se pudo eliminar la notificación. Se guardó en este dispositivo.');
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
    if (!mounted || failed) return;
    ScaffoldMessenger.of(_context).clearSnackBars();
    ScaffoldMessenger.of(_context)
        .showSnackBar(const SnackBar(content: Text('Notificación eliminada')));
  }
}

class _NotificationCard extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final isRead = notif.isRead;

    return Card(
      key: ValueKey('notif_${notif.placeId}'),
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceL),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        side: BorderSide(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          child: Stack(
            children: [
              Row(
                children: [
                  // Ícono/círculo izquierda
                  Container(
                    width: AppDimensions.cityChipHeight - 2,
                    height: AppDimensions.cityChipHeight - 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange,
                      border: Border.all(color: AppColors.teal, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        _iconForCategory(notif.message),
                        color: AppColors.textLight,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceL),
                  // Información derecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: AppTypography.label(
                            fontSize: 15,
                            color: AppColors.textDark,
                          ).copyWith(
                            decoration: isRead
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXS),
                        Text(
                          notif.message,
                          style: AppTypography.body(
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceS),
                        Wrap(
                          spacing: AppDimensions.spaceS - 2,
                          children: [
                            for (final tag in notif.tags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spaceS - 2,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusS - 2,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: AppTypography.caption(
                                    fontSize: 10,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Punto de no leído
              if (!isRead)
                Positioned(
                  right: AppDimensions.spaceS,
                  top: AppDimensions.spaceS,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String message) {
    if (message.toLowerCase().contains('cine')) return Icons.theaters;
    if (message.toLowerCase().contains('parque')) return Icons.park;
    if (message.toLowerCase().contains('restaurante')) return Icons.restaurant;
    if (message.toLowerCase().contains('deporte')) return Icons.sports_soccer;
    if (message.toLowerCase().contains('música')) return Icons.music_note;
    return Icons.place;
  }
}
