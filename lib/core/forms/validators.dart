String? requireText(String? v, {String label = 'Polje'}) {
  if (v == null || v.trim().isEmpty) return '$label je obavezno';
  return null;
}
String? requireEmail(String? v, {String label = 'Email'}) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return '$label je obavezan';
  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
  if (!ok) return 'Neispravan email';
  return null;
}
String? minLength(String? v, int n, {String label = 'Polje'}) {
  if ((v ?? '').trim().length < n) return '$label mora imati najmanje $n znakova';
  return null;
}
