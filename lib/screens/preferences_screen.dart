import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../data/notifications_repository.dart';
import '../data/preferences_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/icon_slider.dart';
import '../widgets/primary_button.dart';
import '../widgets/preference_chip.dart';
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

  late final PreferencesRepository _prefs;
  late final NotificationsRepository _notifications;

  @override
  void initState() {
    super.initState();
    _prefs = context.read<PreferencesRepository>();
    _notifications = context.read<NotificationsRepository>();
    _companion = _prefs.companion;
    _plan = _prefs.plan;
    _place = _prefs.place;
    _budget = _prefs.budget > 0 ? _prefs.budget : 100000;
    _minutes = _prefs.minutes > 0 ? _prefs.minutes : 120;
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

  Future<void> _onReady() async {
    if (_companion == null) {
      _showSnack('Por favor selecciona con quién sales');
      return;
    }
    if (_place == null) {
      _showSnack('Por favor selecciona un lugar');
      return;
    }
    await _prefs.saveAll(
      plan: _plan,
      budget: _budget,
      companion: _companion,
      place: _place,
      minutes: _minutes,
    );
    _notifications.refresh();
    _showSummary();
  }

  void _showSummary() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Listo!',
                    textAlign: TextAlign.center,
                    style: AppTheme.display(fontSize: 26),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 26,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Cuéntanos tus preferencias',
                        textAlign: TextAlign.center,
                        style: AppTheme.display(
                          fontSize: 28,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      label: '¿Con quién sales?',
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
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
                        onChanged: (value) => setState(() => _budget = value),
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
                        onChanged: (value) => setState(() => _minutes = value),
                      ),
                    ),
                    _Section(
                      label: 'Lugar',
                      child: CustomDropdown(
                        value: _place,
                        items: _places,
                        onChanged: (value) => setState(() => _place = value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: 'LISTO',
                icon: Icons.check_circle_outline,
                onPressed: _onReady,
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
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SectionPill(label), const SizedBox(height: 12), child],
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
