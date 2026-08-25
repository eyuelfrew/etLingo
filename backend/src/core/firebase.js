import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { readFileSync } from 'fs';

const keyPath = process.env.FIREBASE_KEY_PATH;

let firebaseApp = null;
let initError = null;

try {
  if (getApps().length === 0) {
    const serviceAccount = JSON.parse(readFileSync(keyPath, 'utf8'));
    firebaseApp = initializeApp({
      credential: cert(serviceAccount),
    });
    console.log('[Firebase] ✓ Admin SDK initialized');
    console.log(`[Firebase]   project: ${serviceAccount.project_id}`);
    console.log(`[Firebase]   service account: ${serviceAccount.client_email}`);
  } else {
    firebaseApp = getApps()[0];
    console.log('[Firebase] ✓ Admin SDK already initialized (reusing existing app)');
  }
} catch (err) {
  initError = err;
  console.error('[Firebase] ✗ Admin SDK initialization FAILED');
  console.error(`[Firebase]   path: ${keyPath}`);
  console.error(`[Firebase]   error: ${err.message}`);
}

export const firebaseAppInstance = firebaseApp;
export const adminAuth = firebaseApp ? getAuth(firebaseApp) : null;

export function getFirebaseStatus() {
  return {
    initialized: firebaseApp !== null,
    projectId: firebaseApp ? firebaseApp.options.projectId : null,
    error: initError ? initError.message : null,
  };
}