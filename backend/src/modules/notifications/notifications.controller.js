import { Op } from 'sequelize';
import { Notification, Campaign, CampaignRecipient } from './notifications.models.js';
import { asyncHandler, badRequest, notFound } from '../../core/http.js';
import { pushToUsers, pushToAll } from './notifications.push.js';
import { fcmLog } from './notifications.fcm-log.js';

function toJSON(n) {
  return {
    id: n.id,
    title: n.title,
    body: n.body,
    type: n.type,
    // broadcast when recipient_user_id is null
    broadcast: n.recipient_user_id == null,
    userId: n.recipient_user_id ?? null,
    read: n.read_at != null,
    readAt: n.read_at,
    createdAt: n.created_at,
  };
}

// ── Admin ─────────────────────────────────────────────────────────────────────

// Parse an optional recipient spec from the request body:
//   { userId }        → one user
//   { userIds: [...] } → a chosen set of users (bulk)
//   neither           → broadcast to everyone
// Returns [null] for broadcast, or an array of validated user ids.
function parseRecipients({ userId, userIds }) {
  if (Array.isArray(userIds)) {
    const ids = [...new Set(
      userIds.map(Number).filter(n => Number.isInteger(n) && n > 0),
    )];
    if (ids.length === 0) throw badRequest('userIds must be an array of valid user ids');
    return ids;
  }
  if (userId !== undefined && userId !== null && userId !== '') {
    const id = Number(userId);
    if (!Number.isInteger(id) || id <= 0) throw badRequest('userId must be a positive integer');
    return [id];
  }
  return null; // broadcast
}

export const send = asyncHandler(async (req, res) => {
  const { title, body = '', type = 'general', userId, userIds } = req.body || {};
  if (!title || !String(title).trim()) throw badRequest('title is required');

  const recipients = parseRecipients({ userId, userIds });
  const base = {
    title: String(title).slice(0, 160),
    body: String(body).slice(0, 500),
    type: String(type).slice(0, 40),
  };

  // Broadcast → a single row with NULL recipient (every learner sees it).
  if (recipients === null) {
    fcmLog(`[send] BROADCAST "${base.title}" (${base.type}) to all learners`);
    const notification = await Notification.create({ ...base, recipient_user_id: null });
    // Fire-and-forget device push; never blocks/skips inbox delivery.
    pushToAll({ title: base.title, body: base.body, type: base.type, context: 'broadcast' }).catch(err =>
      console.error('[notifications] broadcast push error:', err.message));
    return res.status(201).json(toJSON(notification));
  }

  // One or more concrete recipients → one row each (deduped, validated above).
  const existing = await import('../users/users.models.js').then(m => m.AppUser);
  const found = await existing.findAll({ where: { id: { [Op.in]: recipients } }, attributes: ['id'] });
  const valid = new Set(found.map(u => u.id));
  const missing = recipients.filter(id => !valid.has(id));
  if (missing.length) throw badRequest(`Unknown user id(s): ${missing.join(', ')}`);

  fcmLog(`[send] "${title}" → ${recipients.length} specific user(s): [${recipients.join(', ')}]`);

  const rowsCreated = await Notification.bulkCreate(
    recipients.map(rid => ({ ...base, recipient_user_id: rid })),
  );

  pushToUsers(
    recipients,
    {
      title: base.title, body: base.body, type: base.type,
      context: recipients.length === 1 ? 'single' : 'bulk',
    },
  ).catch(err => console.error('[notifications] push error:', err.message));

  // Legacy contract: a single recipient returns a single notification object
  // (the Learners-page bell modal and older clients read `id`/`broadcast`).
  if (recipients.length === 1) {
    return res.status(201).json(toJSON(rowsCreated[0]));
  }

  res.status(201).json({ sent: rowsCreated.length, notifications: rowsCreated.map(toJSON) });
});

export const adminList = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.userId) where.recipient_user_id = req.query.userId;
  const rows = await Notification.findAll({ where, order: [['created_at', 'DESC'], ['id', 'DESC']] });
  res.json(rows.map(toJSON));
});

export const adminRemove = asyncHandler(async (req, res) => {
  const n = await Notification.findByPk(req.params.id);
  if (!n) throw notFound('Notification not found');
  await n.destroy();
  res.status(204).end();
});

// ── App user ──────────────────────────────────────────────────────────────────

export const listMine = asyncHandler(async (req, res) => {
  const userId = req.auth.sub;
  const rows = await Notification.findAll({
    where: {
      [Op.or]: [
        { recipient_user_id: null },
        { recipient_user_id: userId },
      ],
    },
    order: [['created_at', 'DESC'], ['id', 'DESC']],
  });
  res.json(rows.map(toJSON));
});

export const markRead = asyncHandler(async (req, res) => {
  const n = await Notification.findByPk(req.params.id);
  if (!n) throw notFound('Notification not found');
  if (n.recipient_user_id != null && n.recipient_user_id !== req.auth.sub) {
    throw notFound('Notification not found');
  }
  if (n.read_at == null) {
    await n.update({ read_at: new Date() });
  }
  res.json(toJSON(n));
});

// ── Campaigns (scheduled batch delivery) ──────────────────────────────────────

function campaignToJSON(c) {
  return {
    id: c.id,
    title: c.title,
    body: c.body,
    type: c.type,
    audience: c.audience,
    batchSize: c.batch_size,
    intervalSeconds: c.interval_seconds,
    status: c.status,
    startAt: c.start_at,
    nextRunAt: c.next_run_at,
    totalSent: c.total_sent,
    createdAt: c.created_at,
  };
}

export const createCampaign = asyncHandler(async (req, res) => {
  const { title, body = '', type = 'general', audience = 'active', batchSize = 50, intervalMinutes = 60 } = req.body || {};
  if (!title || !String(title).trim()) throw badRequest('title is required');

  const size = Math.max(1, Math.min(10_000, Number(batchSize) || 50));
  const seconds = Math.max(5, Math.min(2_592_000, Math.round((Number(intervalMinutes) || 60) * 60)));

  const campaign = await Campaign.create({
    title: String(title).slice(0, 160),
    body: String(body).slice(0, 500),
    type: String(type).slice(0, 40),
    audience: audience === 'all' ? 'all' : 'active',
    batch_size: size,
    interval_seconds: seconds,
    start_at: new Date(),
    next_run_at: new Date(),
  });

  console.log(`[campaign] #${campaign.id} created — "${campaign.title}" (${campaign.audience}, ${size}/round every ${seconds}s)`);
  res.status(201).json(campaignToJSON(campaign));
});

export const listCampaigns = asyncHandler(async (_req, res) => {
  const rows = await Campaign.findAll({ order: [['created_at', 'DESC'], ['id', 'DESC']] });
  res.json(rows.map(campaignToJSON));
});

export const cancelCampaign = asyncHandler(async (req, res) => {
  const c = await Campaign.findByPk(req.params.id);
  if (!c) throw notFound('Campaign not found');
  if (c.status === 'completed') throw badRequest('Campaign already completed');
  await c.update({ status: 'cancelled', next_run_at: null });
  res.json(campaignToJSON(c));
});

export const removeCampaign = asyncHandler(async (req, res) => {
  const c = await Campaign.findByPk(req.params.id);
  if (!c) throw notFound('Campaign not found');
  await CampaignRecipient.destroy({ where: { campaign_id: c.id } });
  await c.destroy();
  res.status(204).end();
});