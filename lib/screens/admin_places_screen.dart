import 'dart:async';

import 'package:flutter/material.dart';

import '../data/place_admin_repository.dart';
import '../data/places_repository.dart';
import '../data/places_scope.dart';
import '../models/place.dart';
import '../models/place_access.dart';
import '../utils/place_form_validator.dart';
import '../widgets/primary_button.dart';

class AdminPlacesScreen extends StatefulWidget {
  const AdminPlacesScreen({super.key, this.repository});

  final PlaceAdminRepository? repository;

  @override
  State<AdminPlacesScreen> createState() => _AdminPlacesScreenState();
}

class _AdminPlacesScreenState extends State<AdminPlacesScreen> {
  late final PlaceAdminRepository _repository;
  PlaceAccess _access = PlaceAccess.empty;
  List<Place> _places = const <Place>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PlaceAdminRepository();
    unawaited(_load());
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    final PlaceAccess access = await _repository.fetchAccess();
    if (!mounted) return;

    final List<Place> places = access.canManage
        ? await _repository.fetchPlaces()
        : const <Place>[];
    if (!mounted) return;

    setState(() {
      _access = access;
      _places = places
          .where((Place place) => access.canEdit(place.id))
          .toList(growable: false);
      _loading = false;
    });
  }

  Future<void> _openEditor(Place? place) async {
    final PlacesRepository placesRepository = PlacesScope.of(context);
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PlaceEditorScreen(
          repository: _repository,
          access: _access,
          place: place,
        ),
      ),
    );
    if (saved != true || !mounted) return;

    await _load(showLoading: false);
    bool refreshed;
    try {
      refreshed = await placesRepository.refreshCatalog();
    } on Object {
      refreshed = false;
    }
    if (!refreshed && mounted) {
      _showMessage(
        'El lugar se guardó, pero no se pudo refrescar el catálogo. '
        'Reabre la app para verlo.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar lugares'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : () => unawaited(_load()),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: !_access.canManage || !_access.isAdmin
          ? null
          : FloatingActionButton(
              onPressed: () => unawaited(_openEditor(null)),
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_access.canManage
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No tienes permisos para administrar lugares.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(showLoading: false),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _places.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final Place place = _places[index];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(place.name),
                        subtitle: Text(
                          '${place.city} · ${place.category} · '
                          '${place.isActive ? 'Activo' : 'Inactivo'}',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => unawaited(_openEditor(place)),
                      );
                    },
                  ),
                ),
    );
  }
}

class PlaceEditorScreen extends StatefulWidget {
  const PlaceEditorScreen({
    super.key,
    required this.repository,
    required this.access,
    this.place,
  });

  final PlaceAdminRepository repository;
  final PlaceAccess access;
  final Place? place;

  @override
  State<PlaceEditorScreen> createState() => _PlaceEditorScreenState();
}

class _PlaceEditorScreenState extends State<PlaceEditorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _rating;
  late final TextEditingController _reviewCount;
  late final TextEditingController _address;
  late final TextEditingController _schedule;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _imageUrl;
  late final TextEditingController _ownerEmail;
  late String _category;
  late String _city;
  late bool _isActive;
  final Map<String, String> _errors = <String, String>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final PlaceFormValues values = widget.place == null
        ? const PlaceFormValues(
            name: '',
            category: 'Parques',
            city: 'Bucaramanga',
            rating: 0,
            reviewCount: 0,
            address: '',
            schedule: '',
            price: '',
            description: '',
            lat: 7.118523,
            lng: -73.110751,
            imageUrl: '',
            isActive: true,
          )
        : PlaceFormValues.fromPlace(widget.place!);

    _name = TextEditingController(text: values.name);
    _rating = TextEditingController(text: values.rating.toString());
    _reviewCount = TextEditingController(text: values.reviewCount.toString());
    _address = TextEditingController(text: values.address);
    _schedule = TextEditingController(text: values.schedule);
    _price = TextEditingController(text: values.price);
    _description = TextEditingController(text: values.description);
    _lat = TextEditingController(text: values.lat.toString());
    _lng = TextEditingController(text: values.lng.toString());
    _imageUrl = TextEditingController(text: values.imageUrl);
    _ownerEmail = TextEditingController();
    _category = PlaceFormValidator.categories.contains(values.category)
        ? values.category
        : PlaceFormValidator.categories.first;
    _city = PlaceFormValidator.cities.contains(values.city)
        ? values.city
        : PlaceFormValidator.cities.first;
    _isActive = values.isActive;
  }

  @override
  void dispose() {
    _name.dispose();
    _rating.dispose();
    _reviewCount.dispose();
    _address.dispose();
    _schedule.dispose();
    _price.dispose();
    _description.dispose();
    _lat.dispose();
    _lng.dispose();
    _imageUrl.dispose();
    _ownerEmail.dispose();
    super.dispose();
  }

  PlaceFormValues _collectValues() {
    return PlaceFormValues(
      id: widget.place?.id,
      name: _name.text,
      category: _category,
      city: _city,
      rating: double.tryParse(_rating.text.trim().replaceAll(',', '.')) ??
          double.nan,
      reviewCount: int.tryParse(_reviewCount.text.trim()) ?? -1,
      address: _address.text,
      schedule: _schedule.text,
      price: _price.text,
      description: _description.text,
      lat: double.tryParse(_lat.text.trim().replaceAll(',', '.')) ?? double.nan,
      lng: double.tryParse(_lng.text.trim().replaceAll(',', '.')) ?? double.nan,
      imageUrl: _imageUrl.text,
      isActive: widget.access.isAdmin
          ? _isActive
          : widget.place?.isActive ?? true,
    );
  }

  Future<void> _save() async {
    if (!widget.repository.isAvailable) {
      _showMessage(PlaceAdminRepository.networkMessage);
      return;
    }

    final PlaceFormValues values = _collectValues();
    final Map<String, String> errors = PlaceFormValidator.validate(values);
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    final PlaceSaveResult result = await widget.repository.savePlace(
      values.toRemote(),
      id: widget.place?.id,
    );
    if (!mounted) return;

    if (result.error != null) {
      setState(() => _saving = false);
      _showMessage(result.error!);
      return;
    }

    String? ownerError;
    final int? placeId = result.id ?? widget.place?.id;
    if (widget.access.isAdmin && _ownerEmail.text.trim().isNotEmpty) {
      ownerError = placeId == null
          ? 'falta el id del lugar.'
          : await widget.repository.assignOwner(_ownerEmail.text, placeId);
    }
    if (!mounted) return;

    setState(() => _saving = false);
    if (ownerError != null) {
      _showMessage('Lugar guardado, pero no se pudo asignar el dueño: $ownerError');
    } else {
      _showMessage('Lugar guardado correctamente.');
    }
    Navigator.of(context).pop<bool>(true);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _field(
    String errorKey,
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        errorText: _errors[errorKey],
      ),
    );
  }

  Widget _dropdown(
    String errorKey,
    String label,
    String value,
    Iterable<String> options,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: options
          .map(
            (String option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: _saving
          ? null
          : (String? next) {
              if (next == null) return;
              setState(() {
                if (errorKey == 'category') _category = next;
                if (errorKey == 'city') _city = next;
              });
            },
      decoration: InputDecoration(
        labelText: label,
        errorText: _errors[errorKey],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place == null ? 'Nuevo lugar' : 'Editar lugar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _field('name', 'Nombre', _name),
              const SizedBox(height: 12),
              _dropdown(
                'category',
                'Categoría',
                _category,
                PlaceFormValidator.categories,
              ),
              const SizedBox(height: 12),
              _dropdown('city', 'Ciudad', _city, PlaceFormValidator.cities),
              const SizedBox(height: 12),
              _field(
                'rating',
                'Rating (0 a 5)',
                _rating,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              _field(
                'reviewCount',
                'Número de reseñas',
                _reviewCount,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _field('address', 'Dirección', _address),
              const SizedBox(height: 12),
              _field('schedule', 'Horario', _schedule),
              const SizedBox(height: 12),
              _field('price', 'Precio', _price),
              const SizedBox(height: 12),
              _field(
                'description',
                'Descripción',
                _description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _field(
                'lat',
                'Latitud',
                _lat,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 12),
              _field(
                'lng',
                'Longitud',
                _lng,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 12),
              _field(
                'imageUrl',
                'URL de imagen https (opcional)',
                _imageUrl,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              if (widget.access.isAdmin)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lugar activo'),
                  value: _isActive,
                  onChanged: _saving
                      ? null
                      : (bool value) => setState(() => _isActive = value),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    widget.place?.isActive == true
                        ? 'Lugar activo'
                        : 'Lugar inactivo',
                  ),
                  subtitle: const Text(
                    'Solo el administrador puede activar o desactivar lugares.',
                  ),
                ),
              if (widget.access.isAdmin) ...<Widget>[
                const SizedBox(height: 12),
                _field(
                  'ownerEmail',
                  'Correo del dueño (opcional)',
                  _ownerEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _saving ? 'Guardando...' : 'Guardar lugar',
                icon: Icons.save_outlined,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
