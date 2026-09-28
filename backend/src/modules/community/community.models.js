import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

/** User-submitted culture snippets. Admin approves before learners see them. */
export const CommunityStory = sequelize.define('CommunityStory', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  language_code: { type: DataTypes.STRING(8), defaultValue: 'am' },
  title: { type: DataTypes.STRING(160), allowNull: false },
  body: { type: DataTypes.TEXT, allowNull: false },
  audio_url: { type: DataTypes.STRING(255), defaultValue: '' },
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'rejected'),
    defaultValue: 'pending',
  },
  moderator_note: { type: DataTypes.STRING(255), defaultValue: '' },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
}, {
  tableName: 'community_stories',
  updatedAt: false,
  createdAt: 'created_at',
});

/** Language-exchange waitlist / partner interest. */
export const ExchangeSignup = sequelize.define('ExchangeSignup', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  speaks: { type: DataTypes.STRING(8), allowNull: false },
  learning: { type: DataTypes.STRING(8), allowNull: false },
  note: { type: DataTypes.STRING(300), defaultValue: '' },
  status: {
    type: DataTypes.ENUM('waiting', 'matched', 'closed'),
    defaultValue: 'waiting',
  },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
}, {
  tableName: 'exchange_signups',
  updatedAt: false,
  createdAt: 'created_at',
  indexes: [{ unique: true, fields: ['user_id'] }],
});
