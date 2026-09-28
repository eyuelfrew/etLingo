import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

/**
 * In-house promotional slots (not AdMob).
 * Admin picks position in the app + what a tap does.
 */
export const Ad = sequelize.define('Ad', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  title: { type: DataTypes.STRING(120), allowNull: false },
  body: { type: DataTypes.STRING(300), defaultValue: '' },
  image_url: { type: DataTypes.STRING(255), defaultValue: '' },
  cta_label: { type: DataTypes.STRING(40), defaultValue: 'Learn more' },
  /** Placement key: home_top | home_mid | culture_top | after_topics | profile */
  position: { type: DataTypes.STRING(40), allowNull: false, defaultValue: 'home_top' },
  /** Action: url | screen | topic | culture | none */
  action_type: {
    type: DataTypes.ENUM('url', 'screen', 'topic', 'culture', 'none'),
    defaultValue: 'url',
  },
  /** Payload: URL, screen route (/topics, /calendar…), topic slug, or culture unit id. */
  action_value: { type: DataTypes.STRING(255), defaultValue: '' },
  language_code: { type: DataTypes.STRING(8), defaultValue: '' }, // empty = all languages
  priority: { type: DataTypes.INTEGER, defaultValue: 0 },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
  starts_at: { type: DataTypes.DATE, allowNull: true },
  ends_at: { type: DataTypes.DATE, allowNull: true },
  impressions: { type: DataTypes.INTEGER, defaultValue: 0 },
  clicks: { type: DataTypes.INTEGER, defaultValue: 0 },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
}, {
  tableName: 'ads',
  updatedAt: false,
  createdAt: 'created_at',
});
