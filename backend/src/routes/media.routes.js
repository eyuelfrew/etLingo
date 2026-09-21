import { Router } from 'express';
import { getObjectStream } from '../core/storage.js';

const router = Router();

/**
 * Public media proxy — streams S3 objects so learners can play audio / open PDFs
 * even when the bucket blocks anonymous GET (AletCloud AccessDenied).
 *
 * Path: /api/v1/media/<s3-key>   e.g. /api/v1/media/etlingo/audio/xxx.webm
 */
router.get(/^\/media\/(.+)$/, async (req, res, next) => {
  try {
    const key = decodeURIComponent(req.params[0] || '');
    const { body, contentType, contentLength } = await getObjectStream(key);

    res.setHeader('Content-Type', contentType);
    if (contentLength) res.setHeader('Content-Length', String(contentLength));
    // Allow HTML5 audio / iframe from admin (different origin in dev).
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    // Range helps <audio> seeking on some browsers.
    res.setHeader('Accept-Ranges', 'bytes');

    if (body && typeof body.pipe === 'function') {
      body.pipe(res);
      return;
    }
    // SDK v3 may return a web stream / async iterable
    if (body && typeof body.transformToByteArray === 'function') {
      const buf = Buffer.from(await body.transformToByteArray());
      res.send(buf);
      return;
    }
    res.status(500).json({ error: 'Unsupported S3 body stream' });
  } catch (e) {
    if (e.status) return res.status(e.status).json({ error: e.message });
    console.error('[media-proxy]', e.message);
    res.status(404).json({ error: 'Media not found' });
  }
});

export default router;
