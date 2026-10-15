# Ñe'ẽ 🧉

**Aprendé guaraní y jopara con frases de la vida real.**

Probala en el navegador (también en iPhone, desde Safari):
**https://dead-prooff.github.io/nee_app/**

## Qué tiene

- **Lecciones** de 5 minutos en 3 unidades (Saludos, Familia, Comida y
  tereré) con 4 tipos de ejercicio: elegir la traducción, armar la frase,
  emparejar y escuchar.
- **Racha, XP y meta diaria** (5, 10 o 15 minutos), con avisos en jopara:
  *"Hendy hína tu racha 🔥"*, *"Hake la nde racha!"*.
- **Duelos** de 5 preguntas contra amigos, con 10 segundos por pregunta.
- **Liga semanal** Bronce / Plata / Oro con zonas de ascenso y descenso.
- **Perfil** con avatares de mitos guaraníes (Pombéro, Kurupí, Luisõ, Jasy
  Jateré y más), foto propia, insignias e invitaciones con código.
- **Accesible**: lector de pantalla (TalkBack / VoiceOver), contraste WCAG
  AA en modo claro y oscuro, áreas táctiles de 48 px y texto hasta "muy
  grande" sin cortes.

## Para presentar la app

En **Perfil → Configuración → Modo demo**:

- **Cargar perfil de ejemplo**: racha de 8 días, Liga Plata, lecciones,
  duelos e insignias, para mostrar la app "en uso".
- **Simular cierre de la liga**: cierra la semana sin esperar al domingo.
- **Reiniciar todo**: vuelve al registro desde cero.

## Editar el contenido

No hace falta saber programar:

| Qué | Archivo |
| --- | --- |
| Lecciones y ejercicios | `assets/data/lecciones.json` |
| Textos de los avisos | `assets/data/mensajes.json` |
| Insignias | `assets/data/insignias.json` |
| Audios de las frases | `assets/audio/` (ver `LEEME.txt`) |

Lo marcado con `"verificar": true` tiene guaraní para revisar con un
hablante nativo. Al subir los cambios a `main`, la versión web se publica
sola en unos minutos.

## Para desarrollar

Hecha con Flutter. Todo se guarda en el dispositivo (todavía no hay
servidor: amigos, duelos e invitaciones son simulados).

```
flutter pub get
flutter run             # emulador o celular
flutter test            # tests (incluye accesibilidad y el flujo completo)
flutter build apk       # APK de Android
```

En Windows, `iniciar_app.bat` abre el emulador y la app, y
`detener_app.bat` los cierra.
