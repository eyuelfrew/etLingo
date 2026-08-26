import { Notification } from './notifications.models.js';
import { pushToAll } from './notifications.push.js';
import { fcmLog } from './notifications.fcm-log.js';

// ── Content publication events ────────────────────────────────────────────────
// Called by the content module when admin-published material goes live. This is
// an explicit, documented cross-module handover (same pattern as auth → users):
// the content module calls this service function instead of touching
// notification tables directly, so a future split turns it into an event.

// Broadcast a "new content" announcement: one inbox row for everyone plus a
// device push to learners who opted into the `new_content` category.
export async function announceNewContent({ title, body }) {
  const row = await Notification.create({
    recipient_user_id: null,
    title: String(title).slice(0, 160),
    body: String(body).slice(0, 500),
    type: 'new_content',
  });
  fcmLog(`[content] "${title}" published — broadcast notification #${row.id} created`);
  // Fire-and-forget device push; inbox delivery already succeeded above.
  pushToAll({ title, body, type: 'new_content', context: 'content' }).catch(
    (err) => console.error(`[content] push error: ${err.message}`),
  );
  return row;
}

// Guard so draft/inactive material never announces itself.
export function isPublished(row) {
  return row.is_active === undefined || row.is_active === null || row.is_active === true;
}