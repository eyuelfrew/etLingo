import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

// Owned tables: notifications, notification_campaigns, notification_campaign_recipients.
// recipient_user_id references the users module's app_users by plain id only
// (NULL = broadcast to everyone) — no cross-module join, extraction-friendly.

export const Notification = sequelize.define('Notification', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  recipient_user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: true },
  title: { type: DataTypes.STRING(160), allowNull: false },
  body: { type: DataTypes.STRING(500), defaultValue: '' },
  type: { type: DataTypes.STRING(40), defaultValue: 'general' },
  read_at: { type: DataTypes.DATE, allowNull: true },
}, {
  tableName: 'notifications',
  createdAt: 'created_at',
  updatedAt: false,
});

// A campaign delivers one message to many learners in rounds of `batch_size`,
// waiting `interval_seconds` between rounds. The worker lives in
// notifications.runner.js and is driven by server.js on a timer.
export const Campaign = sequelize.define('Campaign', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  title: { type: DataTypes.STRING(160), allowNull: false },
  body: { type: DataTypes.STRING(500), defaultValue: '' },
  type: { type: DataTypes.STRING(40), defaultValue: 'general' },
  // Which learners qualify for delivery.
  audience: { type: DataTypes.ENUM('all', 'active'), defaultValue: 'active' },
  batch_size: { type: DataTypes.INTEGER, defaultValue: 50 },
  interval_seconds: { type: DataTypes.INTEGER, defaultValue: 3600 },
  status: {
    type: DataTypes.ENUM('pending', 'running', 'completed', 'cancelled'),
    defaultValue: 'pending',
  },
  start_at: { type: DataTypes.DATE, allowNull: true },
  next_run_at: { type: DataTypes.DATE, allowNull: true },
  total_sent: { type: DataTypes.INTEGER, defaultValue: 0 },
}, {
  tableName: 'notification_campaigns',
  createdAt: 'created_at',
  updatedAt: false,
});

// Delivery ledger: guarantees each learner receives a campaign exactly once,
// even across restarts and overlapping workers.
export const CampaignRecipient = sequelize.define('CampaignRecipient', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  campaign_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
}, {
  tableName: 'notification_campaign_recipients',
  createdAt: 'sent_at',
  updatedAt: false,
});

// Per-learner notification opt-outs. One row per app user, created lazily with
// sensible defaults on first read — so no backfill migration is needed.
//
// Cross-module note: user_id references the users module's app_users by plain
// id only (same rule as notifications.recipient_user_id).
export const NotificationPreference = sequelize.define('NotificationPreference', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, unique: true },

  // Master switch — when false nothing is pushed to this learner's device.
  push_enabled: { type: DataTypes.BOOLEAN, defaultValue: true, allowNull: false },

  // Learning & progress
  lesson_reminders: { type: DataTypes.BOOLEAN, defaultValue: true, allowNull: false },
  streak_milestones: { type: DataTypes.BOOLEAN, defaultValue: true, allowNull: false },
  achievements: { type: DataTypes.BOOLEAN, defaultValue: true, allowNull: false },

  // Content & product updates
  new_content: { type: DataTypes.BOOLEAN, defaultValue: true, allowNull: false },
  app_updates: { type: DataTypes.BOOLEAN, defaultValue: true, allowNull: false },
  tips: { type: DataTypes.BOOLEAN, defaultValue: true, allowNull: false },

  // Engagement / marketing
  promotions: { type: DataTypes.BOOLEAN, defaultValue: false, allowNull: false },
}, { tableName: 'notification_preferences', timestamps: false });