/** Security helpers */
export function sanitizeText(input, maxLen = 500) {
  if (input == null) return '';
  let s = String(input);
  s = s.replace(/<script[\s\S]*?<\/script>/gi, '');
  s = s.replace(/<style[\s\S]*?<\/style>/gi, '');
  s = s.replace(/<[^>]*>/g, '');
  s = s.replace(/javascript:/gi, '');
  s = Array.from(s).filter((ch) => {
    const c = ch.codePointAt(0);
    return c === 9 || c === 10 || c >= 32;
  }).join('');
  s = s.trim();
  if (maxLen > 0) s = s.slice(0, maxLen);
  return s;
}
export function isEmailLike(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email || '').trim());
}
export function passwordProblem(password) {
  const pw = String(password || '');
  const prod = (process.env.NODE_ENV || 'development') === 'production';
  if (pw.length < (prod ? 10 : 8)) {
    return prod ? 'password must be at least 10 characters in production' : 'password must be at least 8 characters';
  }
  if (pw.length > 128) return 'password is too long';
  if (prod) {
    const strong = /[a-z]/.test(pw) && /[A-Z]/.test(pw) && /\d/.test(pw);
    if (!strong) return 'password must include upper, lower, and a number';
    if (/^(password|admin123|12345678|changeme)/i.test(pw)) return 'password is too common';
  }
  return null;
}
export function maskEmail(email) {
  const s = String(email || '');
  const at = s.indexOf('@');
  if (at < 1) return '***';
  return s[0] + '***@' + s.slice(at + 1, at + 3) + '***';
}
export function isProduction() {
  return (process.env.NODE_ENV || 'development') === 'production';
}
