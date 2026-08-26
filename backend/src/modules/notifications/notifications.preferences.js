import { Op } from 'sequelize';
import { NotificationPreference } from './notifications.models.js';
import { asyncHandler, badRequest } from '../../core/http.js';

// ── Notification category taxonomy ────────────────────────────────────────────
// The admin composer picks one of these `type`s; each maps onto a preference
// toggle so learners only get what they asked for. Types not listed here are
// treated as operational (security/maintenance) and are always delivered.
export const CATEGORIES = [
  { value: 'general', label: 'General', pref: null },          // always deliver
  { value: 'lesson_reminder', label: 'Lesson reminder', pref: 'lesson_reminders' },
  { value: 'streak_milestone', label: 'Streak milestone', pref: 'streak_milestones' },
  { value: 'achievement', label: 'Achievement', pref: 'achievements' },
  { value: 'new_content', label: 'New content', pref: 'new_content' },
  { value: 'app_update', label: 'App update', pref: 'app_updates' },
  { value: 'tip', label: 'Tip of the day', pref: 'tips' },
  { value: 'special_offer', label: 'Special offer', pref: 'promotions' },
];

const PREF_KEYS = [
  'push_enabled',
  'lesson_reminders', 'streak_milestones', 'achievements',
  'new_content', 'app_updates', 'tips', 'promotions',
];

// Legacy admin types map onto the closest new category so nothing breaks.
const LEGACY_TYPE_MAP = {
  feature: 'new_content',
  update: 'app_update',
  event: 'general',
  warning: 'general',
};

function normalizeType(type) {
  const t = String(type || '').trim();
  return LEGACY_TYPE_MAP[t] || t;
}

// Which preference column (if any) gates this notification type?
export function prefKeyForType(type) {
  return CATEGORIES.find(c => c.value === normalizeType(type))?.pref ?? null;
}

function toJSON(p) {
  return {
    pushEnabled: p.push_enabled,
    lessonReminders: p.lesson_reminders,
    streakMilestones: p.streak_milestones,
    achievements: p.achievements,
    newContent: p.new_content,
    appUpdates: p.app_updates,
    tips: p.tips,
    promotions: p.promotions,
  };
}

// Row for this learner — created with defaults on first access.
export async function prefsFor(userId) {
  const [row] = await NotificationPreference.findOrCreate({
    where: { user_id: userId },
    defaults: { user_id: userId },
  });
  return row;
}

// ── App user endpoints ────────────────────────────────────────────────────────

export const getMyPreferences = asyncHandler(async (req, res) => {
  res.json(toJSON(await prefsFor(req.auth.sub)));
});

const BOOLEAN_FIELDS = PREF_KEYS.filter(k => k !== 'push_enabled');

export const updateMyPreferences = asyncHandler(async (req, res) => {
  const body = req.body || {};
  const patch = {};

  if (body.pushEnabled !== undefined) patch.push_enabled = !!body.pushEnabled;
  for (const key of BOOLEAN_FIELDS) {
    // camelCase → snake_case (lessonReminders → lesson_reminders)
    const camel = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    if (body[camel] !== undefined) patch[key] = !!body[camel];
  }

  if (Object.keys(patch).length === 0) {
    throw badRequest('No recognised preference fields in body');
  }

  const row = await prefsFor(req.auth.sub);
  await row.update(patch);
  res.json(toJSON(row));
});

// ── Push filtering helper (used by notifications.push.js) ────────────────────
// Returns { allowedUserIds, skippedUserIds } given target ids and a type.
export async function filterByPreferences(userIds, type) {
  const prefKey = prefKeyForType(type);
  const rows = await NotificationPreference.findAll({
    where: {
      user_id: { [Op.in]: userIds },
      ...(prefKey
        ? { [Op.or]: [{ push_enabled: false }, { [prefKey]: false }] }
        : { push_enabled: false }),
    },
    attributes: ['user_id'],
  });
  const blocked = new Set(rows.map(r => r.user_id));
  return {
    allowedUserIds: userIds.filter(id => !blocked.has(id)),
    skippedUserIds: userIds.filter(id => blocked.has(id)),
  };
}