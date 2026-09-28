/**
 * Ethiopian holiday windows (Gregorian approximate anchors) for XP events
 * and the app calendar chip. Movable feasts use recent-year anchors.
 */

/** @typedef {{ key: string, name: string, nameAm: string, month: number, day: number, days?: number, xpMultiplier?: number }} Holiday */

/** Fixed-date holidays (Gregorian month/day of the feast day). */
const FIXED = [
  { key: 'genna', name: 'Genna (Christmas)', nameAm: 'ገና', month: 1, day: 7, days: 2, xpMultiplier: 2 },
  { key: 'timkat', name: 'Timkat', nameAm: 'ጥምቀት', month: 1, day: 19, days: 3, xpMultiplier: 2 },
  { key: 'adwa', name: 'Adwa Victory Day', nameAm: 'አድዋ', month: 3, day: 2, days: 2, xpMultiplier: 2 },
  { key: 'meskel', name: 'Meskel', nameAm: 'መስቀል', month: 9, day: 27, days: 3, xpMultiplier: 2 },
  { key: 'enkutatash', name: 'Enkutatash (New Year)', nameAm: 'እንቁጣጣሽ', month: 9, day: 11, days: 3, xpMultiplier: 2 },
  { key: 'irreecha', name: 'Irreecha', nameAm: 'ኢሬቻ', month: 10, day: 5, days: 2, xpMultiplier: 2 },
];

/**
 * Movable-feast approximate anchors (Gregorian). Extend yearly as needed.
 * Keys are `YYYY-MM-DD` of the primary feast day.
 */
const MOVABLE = {
  '2025-04-20': { key: 'fasika', name: 'Fasika (Easter)', nameAm: 'ፋሲካ', days: 3, xpMultiplier: 2 },
  '2025-04-18': { key: 'siklet', name: 'Siklet (Good Friday)', nameAm: 'ስቅለት', days: 1, xpMultiplier: 2 },
  '2026-04-12': { key: 'fasika', name: 'Fasika (Easter)', nameAm: 'ፋሲካ', days: 3, xpMultiplier: 2 },
  '2026-04-10': { key: 'siklet', name: 'Siklet (Good Friday)', nameAm: 'ስቅለት', days: 1, xpMultiplier: 2 },
  '2027-05-02': { key: 'fasika', name: 'Fasika (Easter)', nameAm: 'ፋሲካ', days: 3, xpMultiplier: 2 },
};

function dayKey(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function addDays(d, n) {
  const x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  x.setDate(x.getDate() + n);
  return x;
}

function inWindow(today, start, spanDays) {
  const t = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime();
  const s = new Date(start.getFullYear(), start.getMonth(), start.getDate()).getTime();
  const e = s + (spanDays - 1) * 86400000;
  return t >= s && t <= e;
}

/**
 * Holiday active today (or within its XP window).
 * @param {Date} [now]
 * @returns {{ key: string, name: string, nameAm: string, xpMultiplier: number, date: string } | null}
 */
export function activeHoliday(now = new Date()) {
  for (const h of FIXED) {
    const start = new Date(now.getFullYear(), h.month - 1, h.day);
    // Also check previous year window near Jan 1.
    const candidates = [
      start,
      new Date(now.getFullYear() - 1, h.month - 1, h.day),
    ];
    for (const startDay of candidates) {
      if (inWindow(now, startDay, h.days || 1)) {
        return {
          key: h.key,
          name: h.name,
          nameAm: h.nameAm,
          xpMultiplier: h.xpMultiplier || 2,
          date: dayKey(startDay),
        };
      }
    }
  }
  for (const [date, h] of Object.entries(MOVABLE)) {
    const [y, m, d] = date.split('-').map(Number);
    const start = new Date(y, m - 1, d);
    if (inWindow(now, start, h.days || 1)) {
      return {
        key: h.key,
        name: h.name,
        nameAm: h.nameAm,
        xpMultiplier: h.xpMultiplier || 2,
        date,
      };
    }
  }
  return null;
}

/**
 * XP multiplier for culture / holiday challenges today.
 * @param {Date} [now]
 */
export function holidayXpMultiplier(now = new Date()) {
  const h = activeHoliday(now);
  return h ? h.xpMultiplier : 1;
}

/** Next holiday within [days] days (for the home challenge banner). */
export function upcomingHoliday(withinDays = 45, now = new Date()) {
  const cands = [];
  for (const h of FIXED) {
    for (const y of [now.getFullYear() - 1, now.getFullYear(), now.getFullYear() + 1]) {
      const start = new Date(y, h.month - 1, h.day);
      const delta = Math.round(
        (new Date(start.getFullYear(), start.getMonth(), start.getDate()) -
          new Date(now.getFullYear(), now.getMonth(), now.getDate())) /
          86400000,
      );
      if (delta >= -1 && delta <= withinDays) {
        cands.push({ ...h, start, delta, date: dayKey(start) });
      }
    }
  }
  for (const [date, h] of Object.entries(MOVABLE)) {
    const [y, m, d] = date.split('-').map(Number);
    const start = new Date(y, m - 1, d);
    const delta = Math.round(
      (new Date(y, m - 1, d) -
        new Date(now.getFullYear(), now.getMonth(), now.getDate())) /
        86400000,
    );
    if (delta >= -1 && delta <= withinDays) {
      cands.push({ ...h, start, delta, date });
    }
  }
  cands.sort((a, b) => a.delta - b.delta);
  const next = cands[0];
  if (!next) return null;
  return {
    key: next.key,
    name: next.name,
    nameAm: next.nameAm,
    xpMultiplier: next.xpMultiplier || 2,
    date: next.date,
    inDays: next.delta,
  };
}
