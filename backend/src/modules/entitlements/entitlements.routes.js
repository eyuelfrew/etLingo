import { Router } from 'express';
import { requireAuth, requireAppAuth } from '../../core/auth.js';
import { writeLimiter } from '../../middlewares/rateLimiter.js';
import {
  myEntitlements, grantEntitlement, revokeEntitlement, adminListEntitlements,
} from './entitlements.controller.js';
import {
  adminListPlans, adminCreatePlan, adminUpdatePlan, adminDeletePlan,
  listOffers, createCheckoutIntent, completeCheckout, verifyCheckout,
} from './plans.controller.js';

const router = Router();

// App — offers + checkout stub (plans from admin)
router.get('/app/offers', listOffers);
router.get('/app/entitlements', requireAppAuth, myEntitlements);
router.post('/app/checkout/intent', writeLimiter, requireAppAuth, createCheckoutIntent);
router.post('/app/checkout/unit', writeLimiter, requireAppAuth, createCheckoutIntent);
router.get('/app/checkout/:ref/status', requireAppAuth, verifyCheckout);
router.post('/app/checkout/:ref/verify', requireAppAuth, verifyCheckout);
router.post('/app/checkout/:id/complete', writeLimiter, requireAppAuth, completeCheckout);

// Admin — packages
router.get('/admin/plans', requireAuth, adminListPlans);
router.post('/admin/plans', requireAuth, adminCreatePlan);
router.put('/admin/plans/:id', requireAuth, adminUpdatePlan);
router.delete('/admin/plans/:id', requireAuth, adminDeletePlan);

// Admin — user entitlements
router.get('/admin/entitlements', requireAuth, adminListEntitlements);
router.post('/admin/entitlements', requireAuth, grantEntitlement);
router.delete('/admin/entitlements/:id', requireAuth, revokeEntitlement);

export default router;
