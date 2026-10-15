/// Hash estable entre plataformas (String.hashCode puede cambiar entre la
/// app y la web), para que lo simulado dé siempre igual.
///
/// Los productos quedan por debajo de 2^53, así en la web (que usa números
/// de JavaScript) da exactamente lo mismo que en el celular.
int stableHash(String text) {
  var hash = 17;
  for (final unit in text.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}
