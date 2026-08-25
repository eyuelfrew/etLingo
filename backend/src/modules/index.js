import { Router } from 'express';
import { sequelize } from '../core/db.js';

// ── Module registry ───────────────────────────────────────────────────────────
// Each folder under src/modules is a self-contained vertical slice:
//   <name>.models.js       — tables this module owns
//   <name>.controller.js   — business logic
//   <name>.routes.js       — its HTTP surface
//
// Rules that keep microservice extraction cheap:
//  1. A module may only touch tables it owns. Cross-module references are plain
//     id columns (e.g. notifications.recipient_user_id), never Sequelize joins.
//  2. Modules never import each other's models except where a handover is
//     explicit and documented (auth → users provisioning).
//  3. All HTTP paths stay stable here, so clients never notice a split.
//
// To extract a module into its own service later:
//   - copy its folder + core/ into a new repo,
//   - point its model imports at that service's DB connection,
//   - replace the cross-module id reference with an API call / event consumer,
//   - mount its routes.js at the same URL prefix behind the gateway.

import '../modules/auth/auth.models.js';
import '../modules/users/users.models.js';
import '../modules/content/content.models.js';
import '../modules/notifications/notifications.models.js';

import authRoutes from './auth/auth.routes.js';
import contentRoutes from './content/content.routes.js';
import usersRoutes from './users/users.routes.js';
import notificationRoutes from './notifications/notifications.routes.js';

export function initModels() {
  // Ensures every module's tables exist (idempotent). Structural changes to
  // existing tables go through scripts/db-migrate.js instead.
  return sequelize.sync({ force: false });
}

export function buildModuleRouters() {
  const root = Router();

  root.use(authRoutes);           // /auth/*, /app/auth/*
  root.use(contentRoutes);        // /app/languages, /app/bootstrap/:code, /admin/{languages,units,...}
  root.use(usersRoutes);          // /admin/app-users
  root.use(notificationRoutes);   // /app/notifications, /admin/notifications

  return root;
}