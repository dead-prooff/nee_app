/// Avatares predefinidos: mitos guaraníes en versión tierna, más algunos
/// extras. Los dibujos están en `assets/avatars/<id>.svg`.
class AvatarInfo {
  const AvatarInfo({
    required this.id,
    required this.name,
    required this.description,
    this.isMyth = true,
  });

  final String id;
  final String name;

  /// Mini ficha que se muestra al tocarlo.
  final String description;
  final bool isMyth;

  String get asset => 'assets/avatars/$id.svg';
}

const avatars = [
  AvatarInfo(
    id: 'pombero',
    name: 'Pombéro',
    description:
        'Duende de la noche y dueño de los pájaros. Si le dejás tabaco y '
        'caña, te cuida la casa... o te esconde las cosas.',
  ),
  AvatarInfo(
    id: 'kurupi',
    name: 'Kurupí',
    description:
        'Guardián del monte y de los animales. Pícaro como él solo: mejor '
        'no cruzártelo a la hora de la siesta.',
  ),
  AvatarInfo(
    id: 'luison',
    name: 'Luisõ',
    description:
        'El séptimo hijo varón que en luna llena se vuelve un perrazo. '
        'Esta versión solo quiere mimos.',
  ),
  AvatarInfo(
    id: 'jasy_jatere',
    name: 'Jasy Jateré',
    description:
        'Niño rubio con una varita de oro que aparece a la hora de la '
        'siesta. ¡A dormir, que viene!',
  ),
  AvatarInfo(
    id: 'mboi_tui',
    name: "Mbói Tu'i",
    description:
        'Víbora con cabeza de loro, protectora de los esteros y de los '
        'sapitos.',
  ),
  AvatarInfo(
    id: 'monai',
    name: 'Moñái',
    description:
        'Serpiente con antenas, señora de los campos abiertos. Dicen que '
        'es medio ladrona.',
  ),
  AvatarInfo(
    id: 'teju_jagua',
    name: 'Teju Jagua',
    description:
        'Lagarto con cabezas de perro, guardián de las cuevas y de los '
        'tesoros escondidos.',
  ),
  AvatarInfo(
    id: 'ao_ao',
    name: 'Ao Ao',
    description:
        'Oveja salvaje de los cerros que grita "ao ao". Peluda, pero con '
        'carácter.',
  ),
  AvatarInfo(
    id: 'mate',
    name: 'Mate',
    description: 'El compañero de todas las rondas. Sin él no arranca el día.',
    isMyth: false,
  ),
  AvatarInfo(
    id: 'kavaju',
    name: 'Kavaju',
    description:
        'Caballo en guaraní. Hendy kavaju resa: brilla como el ojo del '
        'caballo ✨',
    isMyth: false,
  ),
  AvatarInfo(
    id: 'tatu',
    name: 'Tatú',
    description: 'Armadillo: chiquito, blindado y siempre a tiempo.',
    isMyth: false,
  ),
];

/// Avatar del usuario si todavía no eligió ninguno.
const defaultAvatarId = 'mate';

AvatarInfo avatarById(String id) => avatars.firstWhere(
  (a) => a.id == id,
  orElse: () => avatars.firstWhere((a) => a.id == defaultAvatarId),
);
