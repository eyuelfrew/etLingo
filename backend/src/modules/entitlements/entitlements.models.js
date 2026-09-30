import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

/**
 * Course access grants — free trial days, admin comps, later paid purchases.
 * `source`: seed | admin | promo | purchase | trial
 * `sku`: optional product code (for future gateway)
 */
export const Entitlement = sequelize.define('Entitlement', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  /** e.g. course:am | unit:12 | lesson:34 | all */
  scope: { type: DataTypes.STRING(40), allowNull: false, defaultValue: 'all' },
  scope_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: true },
  sku: { type: DataTypes.STRING(60), defaultValue: '' },
  source: {
    type: DataTypes.ENUM('seed', 'admin', 'promo', 'purchase', 'trial'),
    defaultValue: 'admin',
  },
  granted_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  expires_at: { type: DataTypes.DATE, allowNull: true },
  note: { type: DataTypes.STRING(200), defaultValue: '' },
}, {
  tableName: 'entitlements',
  updatedAt: false,
  createdAt: 'granted_at',
  indexes: [
    { fields: ['user_id', 'scope', 'scope_id'] },
    { unique: true, fields: ['user_id', 'sku'] },
  ],
});

/**
 * Checkout intents — stub until a payment gateway is wired.
 * status: pending | paid | failed | cancelled | unpaid
 */
export const CheckoutIntent = sequelize.define('CheckoutIntent', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  sku: { type: DataTypes.STRING(60), allowNull: false },
  amount_cents: { type: DataTypes.INTEGER, defaultValue: 0 },
  currency: { type: DataTypes.STRING(8), defaultValue: 'ETB' },
  status: {
    type: DataTypes.ENUM('pending', 'paid', 'failed', 'cancelled', 'unpaid'),
    defaultValue: 'unpaid',
  },
  provider: { type: DataTypes.STRING(40), defaultValue: 'none' },
  provider_ref: { type: DataTypes.STRING(120), defaultValue: '' },
  payload: { type: DataTypes.JSON, allowNull: true },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
}, {
  tableName: 'checkout_intents',
  updatedAt: false,
  createdAt: 'created_at',
});
