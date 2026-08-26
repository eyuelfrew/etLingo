import { Op } from 'sequelize';
import { Campaign, CampaignRecipient, Notification } from './notifications.models.js';
import { pushToUsers } from './notifications.push.js';

// Delivers due campaign rounds. Cross-module note: reads the users module's
// AppUser table to resolve the audience — when extracting this service,
// replace with a call/event that returns eligible user ids.

export async function processDueCampaigns() {
  const now = new Date();
  const due = await Campaign.findAll({
    where: {
      status: { [Op.in]: ['pending', 'running'] },
      [Op.or]: [
        { start_at: { [Op.lte]: now } },
        { next_run_at: { [Op.lte]: now } },
      ],
    },
    order: [['id', 'ASC']],
  });

  let delivered = 0;

  for (const campaign of due) {
    // Pending → arm the first round.
    if (campaign.status === 'pending') {
      await campaign.update({
        status: 'running',
        next_run_at: campaign.start_at && campaign.start_at > now ? campaign.start_at : now,
      });
      continue;
    }

    // Learners who already received this campaign are excluded permanently.
    const received = await CampaignRecipient.findAll({
      where: { campaign_id: campaign.id },
      attributes: ['user_id'],
    });
    const excludeIds = received.map(r => r.user_id);

    const where = excludeIds.length
      ? { id: { [Op.notIn]: excludeIds } }
      : {};
    if (campaign.audience === 'active') where.status = 'active';

    const batch = await import('../users/users.models.js').then(m => m.AppUser);
    const recipients = await batch.findAll({
      where,
      order: [['created_at', 'ASC'], ['id', 'ASC']],
      limit: Math.max(1, Number(campaign.batch_size) || 1),
    });

    if (recipients.length === 0) {
      await campaign.update({ status: 'completed', next_run_at: null });
      console.log(`[campaign] #${campaign.id} "${campaign.title}" completed (${campaign.total_sent} sent)`);
      continue;
    }

    for (const user of recipients) {
      await Notification.create({
        recipient_user_id: user.id,
        title: campaign.title,
        body: campaign.body,
        type: campaign.type,
      });
      await CampaignRecipient.create({
        campaign_id: campaign.id,
        user_id: user.id,
      });
    }

    // Best-effort device push for this round's learners.
    pushToUsers(
      recipients.map(u => u.id),
      {
        title: campaign.title, body: campaign.body, type: campaign.type,
        context: `campaign#${campaign.id}`,
      },
    ).catch(err => console.error(`[campaign] push error: ${err.message}`));

    await campaign.increment('total_sent', { by: recipients.length });
    await campaign.update({
      next_run_at: new Date(Date.now() + (Math.max(0, Number(campaign.interval_seconds) || 0) * 1000)),
    });

    delivered += recipients.length;
    console.log(`[campaign] #${campaign.id} round delivered to ${recipients.length} learner(s)`);
  }

  return delivered;
}

// Background worker. Returns a stop function so tests/servers can cancel it.
export function startCampaignWorker(intervalMs = 15_000) {
  const tick = () => processDueCampaigns().catch(err =>
    console.error('[campaign] worker error:', err.message));
  const timer = setInterval(tick, intervalMs);
  return () => clearInterval(timer);
}