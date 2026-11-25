import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/place.dart';

abstract final class MockData {
  static const List<Category> categories = [
    Category(id: 1, name: 'Deportes', icon: Icons.sports_soccer),
    Category(id: 2, name: 'Cine', icon: Icons.theaters),
    Category(id: 3, name: 'Parques', icon: Icons.park),
    Category(id: 4, name: 'Juegos', icon: Icons.sports_esports),
    Category(id: 5, name: 'Músicas', icon: Icons.music_note),
    Category(id: 6, name: 'Furniture', icon: Icons.chair),
    Category(id: 7, name: 'Restaurante', icon: Icons.restaurant),
    Category(id: 8, name: 'Otro', icon: Icons.more_horiz),
  ];

  static const List<String> cities = [
    'Bucaramanga',
    'Floridablanca',
    'Piedecuesta',
  ];

  // COORDENADAS REALES AJUSTABLES - FASE 3 MAPA
  static const double parqueSanPioLat = 7.118523;
  static const double parqueSanPioLng = -73.110751;
  static const double cineCaciqueLat = 7.099503;
  static const double cineCaciqueLng = -73.107536;
  static const double parqueDelAguaLat = 7.130713;
  static const double parqueDelAguaLng = -73.109329;
  static const double estadioAmericoMontaniniLat = 7.136673;
  static const double estadioAmericoMontaniniLng = -73.117073;
  static const double elRinconSocorranoLat = 7.12957645226852;
  static const double elRinconSocorranoLng = -73.12196267399375;
  static const double auditorioLuisCalvoLat = 7.13973265805138;
  static const double auditorioLuisCalvoLng = -73.11995087834049;

  static const List<Place> places = [
    Place(
      id: 1,
      name: 'Parque San Pío',
      category: 'Parques',
      city: 'Bucaramanga',
      rating: 4.5,
      reviewCount: 128,
      address: 'Carrera 33 # 45.',
      schedule: '6:00 a.m. - 10:00 p.m.',
      price: 'Entrada gratis',
      description:
          'Un pulmón verde en el corazón de Bucaramanga. Ideal para caminar, '
          'hacer picnic y disfrutar de la brisa santandereana con familia o '
          'amigos.',
      lat: parqueSanPioLat,
      lng: parqueSanPioLng,
    ),
    Place(
      id: 2,
      name: 'Cine Cacique',
      category: 'Cine',
      city: 'Bucaramanga',
      rating: 4.4,
      reviewCount: 342,
      address: 'Transversal 93 # 34-99.',
      schedule: '10:00 a.m. - 11:00 p.m.',
      price: 'Desde \$12.000',
      description:
          'Salas modernas con sonido envolvente y cartelera para todos los '
          'gustos. La parada obligada para una tarde de cine en Bucaramanga.',
      lat: cineCaciqueLat,
      lng: cineCaciqueLng,
    ),
    Place(
      id: 3,
      name: 'Parque del Agua',
      category: 'Parques',
      city: 'Bucaramanga',
      rating: 4.3,
      reviewCount: 210,
      address: 'Diagonal 32 #30A-51.',
      schedule: '8:00 a.m. - 9:00 p.m.',
      price: 'Entrada gratis',
      description:
          'Fuentes y zonas verdes para desconectarse. Un espacio perfecto para '
          'caminar al atardecer y tomar fotografías.',
      lat: parqueDelAguaLat,
      lng: parqueDelAguaLng,
    ),
    Place(
      id: 4,
      name: 'Estadio Américo Montanini',
      category: 'Deportes',
      city: 'Bucaramanga',
      rating: 4.2,
      reviewCount: 96,
      address: 'Cra. 30 #14.',
      schedule: '8:00 a.m. - 10:00 p.m.',
      price: 'Desde \$20.000',
      description:
          'Vive la pasión del fútbol en un escenario con historia. Consulta la '
          'programación de partidos y acompaña a tu equipo.',
      lat: estadioAmericoMontaniniLat,
      lng: estadioAmericoMontaniniLng,
    ),
    Place(
      id: 5,
      name: 'Restaurante El Rincón Socorrano',
      category: 'Restaurante',
      city: 'Bucaramanga',
      rating: 4.6,
      reviewCount: 275,
      address: 'Cra. 24 #19-45.',
      schedule: '12:00 p.m. - 10:00 p.m.',
      price: '\$\$ · \$25.000 promedio',
      description:
          'Cocina típica santandereana con recetas de la casa. Ambiente '
          'acogedor y porciones generosas para compartir en familia.',
      lat: elRinconSocorranoLat,
      lng: elRinconSocorranoLng,
    ),
    Place(
      id: 6,
      name: 'Auditorio Luis A. Calvo',
      category: 'Músicas',
      city: 'Bucaramanga',
      rating: 4.3,
      reviewCount: 84,
      address: 'Carrera 27 con Calle 9 (Universidad Industrial de Santander).',
      schedule: 'Según evento',
      price: 'Desde \$15.000',
      description:
          'Escenario para conciertos, obras y eventos culturales. Revisa la '
          'agenda y disfruta de la música en vivo.',
      lat: auditorioLuisCalvoLat,
      lng: auditorioLuisCalvoLng,
    ),
  ];

  static IconData iconForCategory(String categoryName) {
    for (final Category category in categories) {
      if (category.name == categoryName) {
        return category.icon;
      }
    }
    return Icons.place;
  }
}
