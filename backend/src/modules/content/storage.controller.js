import { listS3Objects, getS3Status, s3Enabled } from '../../core/storage.js';
import { asyncHandler, badRequest } from '../../core/http.js';

export const getStorageStatus = asyncHandler(async (_req, res) => {
  res.json(getS3Status());
});

/** GET /admin/storage/objects?prefix=etlingo/audio&maxKeys=100 */
export const listObjects = asyncHandler(async (req, res) => {
  if (!s3Enabled) {
    return res.status(503).json({ error: 'S3 storage is not configured on the server.' });
  }
  const prefix = (req.query.prefix || '').toString();
  const maxKeys = Number(req.query.maxKeys) || 200;
  if (maxKeys < 1 || maxKeys > 1000) throw badRequest('maxKeys must be 1–1000');

  const data = await listS3Objects({ prefix, maxKeys });
  const origin = (
    process.env.PUBLIC_API_ORIGIN ||
    `${req.protocol}://${req.get('host')}`
  ).replace(/\/$/, '');
  data.objects = (data.objects || []).map((o) => ({
    ...o,
    url: o.url.startsWith('/api/v1/media/') ? `${origin}${o.url}` : o.url,
  }));
  res.json(data);
});
