import { Op } from 'sequelize';
import { getMessagingInstance } from '../../core/firebase.js';

// Cross-module note: reads the users module's AppUser table to resolve fcm
// tokens by plain user id — same accepted pattern as the campaign runner.
// When extracting the service, replace with a lookup/event returning tokens.

const FCM_BATCH = 500; // firebase-admin multicast limit per call

// Best-effort device push to a concrete set of users (by id). Never throws —
// inbox delivery must succeed even when FCM is unconfigured or a token is stale.
export async function pushToUsers(userIds, { title, body = '' }) {
  const messaging = getMessagingInstance();
  if (!messaging || !userIds?.length) return 0;

  const { AppUser } = await import('../users/users.models.js');
  const users = await AppUser.findAll({
    where: { id: { [Op.in]: userIds } },
    attributes: ['id', 'fcm_token'],
  });
  const tokens = users.map(u => u.fcm_token).filter(Boolean);
  if (tokens.length === 0) return 0;

  let sent = 0;
  for (let i = 0; i < tokens.length; i += FCM_BATCH) {
    const batch = tokens.slice(i, i + FCM_BATCH);
    try {
      const resp = await messaging.sendEachForMulticast({
        tokens: batch,
        notification: { title: String(title).slice(0, 160), body: String(body).slice(0, 500) },
        android: { priority: 'high' },
        data: { screen: 'notifications' },
      });
      sent += resp.successCount;
    } catch (err) {
      console.error(`[push] multicast batch failed: ${err.message}`);
    }
  }
  console.log(`[notifications] push delivered to ${sent}/${tokens.length} device(s)`);
  return sent;
}

// Best-effort broadcast to every leaner who has an active FCM token.
export async function pushToAll({ title, body = '' }) {
  const messaging = getMessagingInstance();
  if (!messaging) return 0;

  const { AppUser } = await import('../users/users.models.js');
  const users = await AppUser.findAll({
    where: { fcm_token: { [Op.ne]: null } },
    attributes: ['fcm_token'],
  });
  const tokens = users.map(u => u.fcm_token).filter(Boolean);
  if (tokens.length === 0) return 0;

  let sent = 0;
  for (let i = 0; i < tokens.length; i += FCM_BATCH) {
    const batch = tokens.slice(i, i + FCM_BATCH);
    try {
      const resp = await messaging.sendEachForMulticast({
        tokens: batch,
        notification: { title: String(title).slice(0, 160), body: String(body).slice(0, 500) },
        android: { priority: 'high' },
        data: { screen: 'notifications' },
      });
      sent += resp.successCount;
    } catch (err) {
      console.error(`[push] broadcast batch failed: ${err.message}`);
    }
  }
  console.log(`[notifications] broadcast push delivered to ${sent}/${tokens.length} device(s)`);
  return sent;
}