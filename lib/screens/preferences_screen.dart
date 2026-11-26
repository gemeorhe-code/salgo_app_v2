import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../data/notifications_repository.dart';
import '../data/preferences_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/icon_slider.dart';
import '../widgets/primary_button.dart';
import '../widgets/preference_chip.dart';
import '../widgets/salgo_app_bar.dart';
import '../widgets/section_pill.dart';

class _CompanionOption {
  const _CompanionOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  static const List<String> _places = [
    'Bucaramanga',
    'Floridablanca',
    'Girón',
    'Piedecuesta',
  ];

  static const List<_CompanionOption> _companions = [
    _CompanionOption('Pareja', Icons.favorite),
    _CompanionOption('Familia', Icons.family_restroom),
    _CompanionOption('Amigos', Icons.groups),
    _CompanionOption('Solo', Icons.person),
  ];

  String? _companion;
  String? _plan;
  String? _place;
  double _budget = 100000;
  double _minutes = 120;
  bool _isLoading = false;
  bool _isSaving = false;

  late final PreferencesRepository _prefs;
  late final NotificationsRepository _notifications;

  @override
  void initState() {
    super.initState();
    _prefs = context.read<PreferencesRepository>();
    _notifications = context.read<NotificationsRepository>();
    _isLoading = _prefs.isSyncing;
    _syncFields();
    _prefs.addListener(_onPreferencesChanged);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _syncFields() {
    _companion = _prefs.companion;
    _plan = _prefs.plan;
    _place = _prefs.place;
    _budget = _prefs.budget > 0 ? _prefs.budget : 100000;
    _minutes = _prefs.minutes > 0 ? _prefs.minutes : 120;
  }

  void _onPreferencesChanged() {
    if (!mounted) return;
    if (_prefs.isSyncing) {
      if (!_isLoading) setState(() => _isLoading = true);
      return;
    }
    if (_isLoading) {
      setState(() {
        _isLoading = false;
        _syncFields();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (!_prefs.hasData &&
        args is String &&
        MockData.categories.any((category) => category.name == args)) {
      _plan = args;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _isBusy => _isLoading || _isSaving;

  Future<void> _onReady() async {
    if (_isBusy) return;
    if (_companion == null) {
      _showSnack('Por favor selecciona con quién sales');
      return;
    }
    if (_place == null) {
      _showSnack('Por favor selecciona un lugar');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _prefs.saveAll(
        plan: _plan,
        budget: _budget,
        companion: _companion,
        place: _place,
        minutes: _minutes,
      );
      _notifications.refresh();
      if (!mounted) return;
      _showSummary();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSummary() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusPill),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceXXL,
                AppDimensions.spaceXXL,
                AppDimensions.spaceXXL,
                AppDimensions.spaceXL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Listo!',
                    textAlign: TextAlign.center,
                    style: AppTypography.display(fontSize: 26),
                  ),
                  const SizedBox(height: AppDimensions.spaceL),
                  _SummaryRow(label: '¿Con quién sales?', value: _companion!),
                  _SummaryRow(
                    label: 'Tipo de plan',
                    value: _plan ?? 'No seleccionado',
                  ),
                  _SummaryRow(
                    label: 'Presupuesto',
                    value: formatCOP(_budget.toInt()),
                  ),
                  _SummaryRow(
                    label: '¿Cuánto tiempo?',
                    value: formatMinutes(_minutes.toInt()),
                  ),
                  _SummaryRow(label: 'Lugar', value: _place!),
                  const SizedBox(height: AppDimensions.spaceM),
                  PrimaryButton(
                    label: 'Entendido',
                    icon: Icons.check,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SalgoAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AbsorbPointer(
                absorbing: _isBusy,
                child: Opacity(
                  opacity: _isBusy ? 0.6 : 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.spaceL,
                      AppDimensions.spaceM,
                      AppDimensions.spaceL,
                      AppDimensions.spaceXL,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceXL,
                            vertical: AppDimensions.spaceXXL + 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusPill,
                            ),
                          ),
                          child: Text(
                            'Cuéntanos tus preferencias',
                            textAlign: TextAlign.center,
                             style: AppTypography.display(
                               fontSize: 28,
                               color: AppColors.textLight,
                             ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ValueListenableBuilder<String?>(
                          valueListenable: _prefs.syncError,
                          builder: (context, error, _) {
                            if (error == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: AppDimensions.spaceM,
                              ),
                              padding: const EdgeInsets.all(
                                AppDimensions.spaceM,
                              ),
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
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(
                              bottom: AppDimensions.spaceM,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        _Section(
                          label: '¿Con quién sales?',
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppDimensions.spaceS + 2,
                            runSpacing: AppDimensions.spaceS + 2,
                            children: [
                              for (final option in _companions)
                                PreferenceChip(
                                  icon: option.icon,
                                  label: option.label,
                                  selected: _companion == option.label,
                                  onTap: () =>
                                      setState(() => _companion = option.label),
                                ),
                            ],
                          ),
                        ),
                        _Section(
                          label: 'Tipo de plan',
                          child: CustomDropdown(
                            value: _plan,
                            items: [
                              for (final category in MockData.categories)
                                category.name,
                            ],
                            onChanged: (value) => setState(() => _plan = value),
                          ),
                        ),
                        _Section(
                          label: 'Presupuesto',
                          child: IconSlider(
                            icon: Icons.attach_money,
                            value: _budget,
                            min: 0,
                            max: 500000,
                            divisions: 50,
                            valueLabel: formatCOP(_budget.toInt()),
                            onChanged: (value) =>
                                setState(() => _budget = value),
                          ),
                        ),
                        _Section(
                          label: '¿Cuánto tiempo?',
                          child: IconSlider(
                            icon: Icons.schedule,
                            value: _minutes,
                            min: 30,
                            max: 480,
                            divisions: 15,
                            valueLabel: formatMinutes(_minutes.toInt()),
                            onChanged: (value) =>
                                setState(() => _minutes = value),
                          ),
                        ),
                        _Section(
                          label: 'Lugar',
                          child: CustomDropdown(
                            value: _place,
                            items: _places,
                            onChanged: (value) =>
                                setState(() => _place = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceL,
                AppDimensions.spaceS,
                AppDimensions.spaceL,
                AppDimensions.spaceL,
              ),
              child: PrimaryButton(
                label: _isLoading
                    ? 'Cargando...'
                    : _isSaving
                    ? 'Guardando...'
                    : 'LISTO',
                icon: Icons.check_circle_outline,
                onPressed: _isBusy ? null : _onReady,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionPill(label),
          const SizedBox(height: AppDimensions.spaceM),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceS + 2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceM + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.label(
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Text(
            value,
            style: AppTypography.label(color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}
