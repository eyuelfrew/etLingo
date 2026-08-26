import { Op } from 'sequelize';
import { getMessagingInstance, getFirebaseStatus } from '../../core/firebase.js';
import { maskToken, summarizeMulticast, fcmLog } from './notifications.fcm-log.js';
import { filterByPreferences } from './notifications.preferences.js';

// Cross-module note: reads the users module's AppUser table to resolve fcm
// tokens by plain user id — same accepted pattern as the campaign runner.
// When extracting the service, replace with a lookup/event returning tokens.

const FCM_BATCH = 500; // firebase-admin multicast limit per call

// One banner line per server start so a missing/incorrect service account is
// obvious before anything is sent.
export function logFcmAvailability() {
  const st = getFirebaseStatus();
  if (st.messaging === 'up') {
    fcmLog(`Firebase Messaging AVAILABLE (project "${st.projectId}")`);
  } else {
    fcmLog(`Firebase Messaging UNAVAILABLE — device push disabled. ${st.error || 'Check FIREBASE_KEY_PATH.'}`);
  }
}

// Send one multicast batch and log the per-token outcome.
async function sendBatch(messaging, tokens, { title, body }, context) {
  const batchLabel = `${context} batch of ${tokens.length} token(s)`;
  try {
    const resp = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: String(title).slice(0, 160), body: String(body).slice(0, 500) },
      android: { priority: 'high' },
      data: { screen: 'notifications' },
    });
    const { counts, samples } = summarizeMulticast(resp);
    const failed = Object.keys(counts).filter(k => k !== 'success');
    if (failed.length === 0) {
      fcmLog(`OK   ${batchLabel} → ${counts.success} delivered`);
    } else if (counts.success === 0) {
      fcmLog(`FAIL ${batchLabel} → ${JSON.stringify(counts)}` +
        (samples.length ? ` | ${samples.map(s => `${s.index}:${s.code}:${s.message}`).join(' | ')}` : ''));
    } else {
      fcmLog(`PART ${batchLabel} → success=${counts.success} ${JSON.stringify(counts)}` +
        (samples.length ? ` | ${samples.map(s => `${s.index}:${s.code}:${s.message}`).join(' | ')}` : ''));
    }
    return counts.success || 0;
  } catch (err) {
    fcmLog(`THREW ${batchLabel} → ${err.message}`);
    return 0;
  }
}

// Best-effort device push to a concrete set of users (by id). Never throws —
// inbox delivery must succeed even when FCM is unconfigured or a token is stale.
export async function pushToUsers(userIds, { title, body = '', type = 'general', context = 'send' }) {
  if (!userIds?.length) {
    fcmLog(`[${context}] called with no user ids — nothing to push`);
    return 0;
  }

  const messaging = getMessagingInstance();
  if (!messaging) {
    fcmLog(`[${context}] Firebase Messaging unavailable — no device push (check FIREBASE_KEY_PATH / project)`);
    return 0;
  }

  // Honour each learner's opt-outs before touching FCM.
  let { allowedUserIds, skippedUserIds } = await filterByPreferences(userIds, type);
  if (skippedUserIds.length) {
    fcmLog(`[${context}] ${skippedUserIds.length} learner(s) opted out of "${type}" — skipping: [${skippedUserIds.join(', ')}]`);
  }
  if (allowedUserIds.length === 0) {
    fcmLog(`[${context}] all target learners opted out of "${type}" — nothing pushed`);
    return 0;
  }

  const { AppUser } = await import('../users/users.models.js');
  const users = await AppUser.findAll({
    where: { id: { [Op.in]: allowedUserIds } },
    attributes: ['id', 'fcm_token', 'email'],
  });

  const missing = allowedUserIds.filter(id => !users.some(u => u.id === id));
  if (missing.length) fcmLog(`[${context}] requested user id(s) not found in DB: [${missing.join(', ')}]`);

  const withToken = users.filter(u => u.fcm_token);
  const withoutToken = users.filter(u => !u.fcm_token);
  if (withoutToken.length) {
    fcmLog(`[${context}] ${withoutToken.length} of ${users.length} target user(s) have NO fcm_token (never registered / signed out?) — ` +
      `${withoutToken.map(u => `#${u.id}(${u.email || '?'})`).join(', ')}`);
  }
  if (withToken.length === 0) {
    fcmLog(`[${context}] no target user has a registered FCM token — nothing pushed`);
    return 0;
  }

  const tokens = withToken.map(u => u.fcm_token);
  fcmLog(`[${context}] "${title}" → ${withToken.length} device(s): ${tokens.map(maskToken).join(', ')}`);

  let sent = 0;
  for (let i = 0; i < tokens.length; i += FCM_BATCH) {
    const batch = tokens.slice(i, i + FCM_BATCH);
    sent += await sendBatch(messaging, batch, { title, body }, context);
  }
  fcmLog(`[${context}] DONE "${title}" → ${sent}/${tokens.length} accepted by FCM`);
  return sent;
}

// Best-effort broadcast to every leaner who has an active FCM token AND has
// not opted out of this category.
export async function pushToAll({ title, body = '', type = 'general', context = 'broadcast' }) {
  const messaging = getMessagingInstance();
  if (!messaging) {
    fcmLog(`[${context}] Firebase Messaging unavailable — skipping device push`);
    return 0;
  }

  const { AppUser } = await import('../users/users.models.js');
  const users = await AppUser.findAll({
    where: { fcm_token: { [Op.ne]: null } },
    attributes: ['id', 'fcm_token'],
  });

  const { allowedUserIds, skippedUserIds } =
    await filterByPreferences(users.map(u => u.id), type);
  if (skippedUserIds.length) {
    fcmLog(`[${context}] ${skippedUserIds.length} learner(s) opted out of "${type}" — skipped from broadcast`);
  }
  if (allowedUserIds.length === 0) {
    fcmLog(`[${context}] zero opted-in learners for "${type}" — nothing broadcast`);
    return 0;
  }

  const byId = new Map(users.map(u => [u.id, u]));
  const tokens = allowedUserIds.map(id => byId.get(id)?.fcm_token).filter(Boolean);
  if (tokens.length === 0) {
    fcmLog(`[${context}] zero opted-in learners have an FCM token — nothing broadcast`);
    return 0;
  }

  fcmLog(`[${context}] "${title}" (${type}) → broadcasting to ${tokens.length} token(s)`);
  let sent = 0;
  for (let i = 0; i < tokens.length; i += FCM_BATCH) {
    const batch = tokens.slice(i, i + FCM_BATCH);
    sent += await sendBatch(messaging, batch, { title, body }, context);
  }
  fcmLog(`[${context}] DONE broadcast → ${sent}/${tokens.length} accepted by FCM`);
  return sent;
}