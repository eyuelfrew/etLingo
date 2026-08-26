// ── Rich FCM telemetry ────────────────────────────────────────────────────────
// Every push attempt is logged here with enough detail to diagnose why a
// device did not receive a notification:
//   • when / for whom a send is attempted,
//   • whether the target user(s) actually registered an FCM token,
//   • per-multicast success/failure counts,
//   • per-token Firebase error codes (unregistered, invalid-argument, …).
//
// Tokens are masked so we never leak full registration tokens to logs, but keep
// enough to cross-reference a specific device.

// Show just the head+tail of a registration token.
export function maskToken(t) {
  if (!t) return '(none)';
  if (t.length < 12) return '••••';
  return `${t.slice(0, 6)}•••${t.slice(-6)}`;
}

// Reduce a firebase-admin `sendEachForMulticast` response to counts-by-code
// plus a few sampled failures for debugging.
export function summarizeMulticast(resp) {
  const byCode = {};
  const samples = [];
  const responses = Array.isArray(resp.responses) ? resp.responses : [];
  responses.forEach((r, i) => {
    if (r && r.success) {
      byCode.success = (byCode.success || 0) + 1;
      return;
    }
    const code = r?.error?.code || 'unknown-error';
    byCode[code] = (byCode[code] || 0) + 1;
    if (samples.length < 3) {
      samples.push({ index: i, code, message: r?.error?.message || '' });
    }
  });
  return { counts: byCode, samples };
}

// Simple namespaced log line with a timestamp, greppable as `fcm`.
export function fcmLog(...parts) {
  console.log(`[${new Date().toISOString()}] [fcm]`, ...parts);
}