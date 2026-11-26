import 'package:flutter/material.dart';
import '../data/user_profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/salgo_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final UserProfileRepository _profileRepo;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _errorName;
  String? _errorEmail;
  String? _selectedCity;

  static const List<String> _cities = [
    'Bucaramanga',
    'Floridablanca',
    'Piedecuesta',
  ];

  @override
  void initState() {
    super.initState();
    _profileRepo = UserProfileRepository.of(context);
    _nameController.text = _profileRepo.name;
    _emailController.text = _profileRepo.email;
    _selectedCity = _profileRepo.city;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu nombre';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa un correo válido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,3}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  void _saveProfile() {
    setState(() {
      _errorName = _validateName(_nameController.text);
      _errorEmail = _validateEmail(_emailController.text);
    });

    if (_errorName != null || _errorEmail != null) return;

    _profileRepo.update(
      _nameController.text,
      _emailController.text,
      _selectedCity ?? 'Bucaramanga',
    );
    _showSnack('Perfil actualizado');
    Navigator.pop(context);
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
            icon: const Icon(Icons.check),
            tooltip: 'Guardar',
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceL,
          AppDimensions.spaceL,
          AppDimensions.spaceL,
          AppDimensions.spaceXXL + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                    border: Border.all(color: AppColors.teal, width: 3),
                    boxShadow: AppShadows.floating,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXXL),

            _buildTextField(
              controller: _nameController,
              label: 'Nombre',
              hint: 'Tu nombre completo',
              error: _errorName,
              icon: Icons.person_outlined,
            ),

            const SizedBox(height: AppDimensions.spaceL),

            _buildTextField(
              controller: _emailController,
              label: 'Correo',
              hint: 'usuario@ejemplo.com',
              keyboardType: TextInputType.emailAddress,
              error: _errorEmail,
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: AppDimensions.spaceL),

            _buildCityChips(),

            const SizedBox(height: AppDimensions.spaceXXL),

            PrimaryButton(
              label: 'Guardar',
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? error,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body(
              fontSize: 15,
              color: AppColors.textLight.withValues(alpha: 0.85),
            ),
            prefixIcon: Icon(icon, color: AppColors.teal),
            filled: true,
            fillColor: AppColors.orange.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.teal, width: 2),
            ),
            errorText: error,
          ),
        ),
      ],
    );
  }

  Widget _buildCityChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ciudad',
          style: AppTypography.label(
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Wrap(
          spacing: AppDimensions.spaceS,
          runSpacing: AppDimensions.spaceS,
          children: _cities.map((city) {
            final isSelected = _selectedCity == city;
            return FilterChip(
              label: Text(
                city,
                style: AppTypography.label(
                  fontSize: 13,
                  color: isSelected ? AppColors.textLight : AppColors.textDark,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.teal,
              backgroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                side: BorderSide(color: AppColors.teal, width: 1),
              ),
              onSelected: (selected) {
                setState(() => _selectedCity = selected ? city : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}