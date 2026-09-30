import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

/** Subscription packages — editable in admin (price, period, perks). */
export const SubscriptionPlan = sequelize.define('SubscriptionPlan', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  sku: { type: DataTypes.STRING(60), allowNull: false, unique: true },
  title: { type: DataTypes.STRING(80), allowNull: false },
  subtitle: { type: DataTypes.STRING(160), defaultValue: '' },
  period: {
    type: DataTypes.ENUM('month', 'year', 'trial'),
    defaultValue: 'month',
  },
  price_cents: { type: DataTypes.INTEGER, defaultValue: 0 },
  currency: { type: DataTypes.STRING(8), defaultValue: 'ETB' },
  features: { type: DataTypes.JSON, allowNull: true },
  badge: { type: DataTypes.STRING(40), defaultValue: '' },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
  is_highlighted: { type: DataTypes.BOOLEAN, defaultValue: false },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'subscription_plans', timestamps: false });
