import '../models/place.dart';

const Map<int, String> _accentReplacements = <int, String>{
  0x00e1: 'a',
  0x00e0: 'a',
  0x00e9: 'e',
  0x00e8: 'e',
  0x00ed: 'i',
  0x00ec: 'i',
  0x00f3: 'o',
  0x00f2: 'o',
  0x00fa: 'u',
  0x00f9: 'u',
  0x00fc: 'u',
  0x00f1: 'n',
};

final RegExp _whitespace = RegExp(r'\s+');

String normalizeSearchText(String value) {
  final StringBuffer normalized = StringBuffer();
  for (final int rune in value.toLowerCase().runes) {
    final String? replacement = _accentReplacements[rune];
    if (replacement != null) {
      normalized.write(replacement);
    } else if (!_isCombiningMark(rune)) {
      normalized.writeCharCode(rune);
    }
  }
  return normalized.toString().trim().replaceAll(_whitespace, ' ');
}

bool _isCombiningMark(int rune) {
  return (rune >= 0x0300 && rune <= 0x036f) ||
      (rune >= 0x1ab0 && rune <= 0x1aff) ||
      (rune >= 0x1dc0 && rune <= 0x1dff) ||
      (rune >= 0x20d0 && rune <= 0x20ff) ||
      (rune >= 0xfe20 && rune <= 0xfe2f);
}

List<Place> searchPlaces(List<Place> places, String query) {
  final String normalizedQuery = normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    return List<Place>.unmodifiable(places);
  }

  final List<_ScoredPlace> matches = <_ScoredPlace>[];
  for (int index = 0; index < places.length; index++) {
    final Place place = places[index];
    final String name = normalizeSearchText(place.name);
    final String city = normalizeSearchText(place.city);
    final String category = normalizeSearchText(place.category);
    final String address = normalizeSearchText(place.address);

    if (!name.contains(normalizedQuery) &&
        !city.contains(normalizedQuery) &&
        !category.contains(normalizedQuery) &&
        !address.contains(normalizedQuery)) {
      continue;
    }

    final int score;
    if (name.startsWith(normalizedQuery)) {
      score = 0;
    } else if (city.startsWith(normalizedQuery) ||
        category.startsWith(normalizedQuery) ||
        address.startsWith(normalizedQuery)) {
      score = 1;
    } else {
      score = 2;
    }
    matches.add(_ScoredPlace(score: score, index: index, place: place));
  }

  matches.sort((_ScoredPlace a, _ScoredPlace b) {
    final int scoreComparison = a.score.compareTo(b.score);
    return scoreComparison != 0
        ? scoreComparison
        : a.index.compareTo(b.index);
  });

  return List<Place>.unmodifiable(
    matches.map((_ScoredPlace match) => match.place),
  );
}

class _ScoredPlace {
  const _ScoredPlace({
    required this.score,
    required this.index,
    required this.place,
  });

  final int score;
  final int index;
  final Place place;
}
