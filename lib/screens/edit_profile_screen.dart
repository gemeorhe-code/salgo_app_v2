import 'package:flutter/material.dart';
import '../data/user_profile_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';

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
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar perfil',
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar',
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar with camera badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.orange, AppColors.teal],
                    ),
                    border: Border.all(color: AppColors.teal, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textDark.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name field
            _buildTextField(
              controller: _nameController,
              label: 'Nombre',
              hint: 'Tu nombre completo',
              error: _errorName,
              icon: Icons.person_outlined,
            ),

            const SizedBox(height: 16),

            // Email field
            _buildTextField(
              controller: _emailController,
              label: 'Correo',
              hint: 'usuario@ejemplo.com',
              keyboardType: TextInputType.emailAddress,
              error: _errorEmail,
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 16),

            // City chips
            _buildCityChips(),

            const SizedBox(height: 24),

            // Save button
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
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, color: AppColors.teal),
            filled: true,
            fillColor: AppColors.orange.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cities.map((city) {
            final isSelected = _selectedCity == city;
            return FilterChip(
              label: Text(
                city,
                style: TextStyle(
                  color: isSelected ? AppColors.textLight : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.teal,
              backgroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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