import { randomUUID } from 'crypto';
import path from 'path';
import fs from 'fs';
import multer from 'multer';
import { HttpError } from '../../core/http.js';
import {
  uploadBufferToS3,
  s3Enabled,
  mediaKindFromMime,
  ALLOWED_MEDIA_MIMES,
} from '../../core/storage.js';

const LOCAL_DIR = path.resolve(process.cwd(), 'uploads', 'media');
fs.mkdirSync(LOCAL_DIR, { recursive: true });

const EXT_BY_MIME = {
  'audio/mpeg': '.mp3',
  'audio/mp3': '.mp3',
  'audio/wav': '.wav',
  'audio/x-wav': '.wav',
  'audio/wave': '.wav',
  'audio/webm': '.webm',
  'audio/ogg': '.ogg',
  'audio/mp4': '.m4a',
  'audio/x-m4a': '.m4a',
  'audio/aac': '.aac',
  'application/pdf': '.pdf',
  'image/png': '.png',
  'image/jpeg': '.jpg',
  'image/webp': '.webp',
};

const AUDIO_ONLY = new Set([
  'audio/mpeg',
  'audio/mp3',
  'audio/wav',
  'audio/x-wav',
  'audio/wave',
  'audio/webm',
  'audio/ogg',
  'audio/mp4',
  'audio/x-m4a',
  'audio/aac',
]);

function chooseFolder(mime) {
  if (mime.startsWith('audio/')) return 'audio';
  if (mime === 'application/pdf') return 'pdf';
  if (mime.startsWith('image/')) return 'images';
  return 'media';
}

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const mime = (file.mimetype || '').toLowerCase();
    if (ALLOWED_MEDIA_MIMES.includes(mime)) return cb(null, true);
    cb(
      new HttpError(
        400,
        'Only audio (mp3, wav, webm, ogg, m4a, aac), PDF, or image files are allowed.',
      ),
    );
  },
});

async function handleUpload(req, res, { audioOnly = false } = {}) {
  if (!req.file) throw new HttpError(400, 'No file received.');

  const mime = (req.file.mimetype || 'application/octet-stream').toLowerCase();
  if (audioOnly && !AUDIO_ONLY.has(mime)) {
    throw new HttpError(400, 'Only audio files are allowed for this endpoint.');
  }

  // Prefer S3 — store the public URL in the DB.
  if (s3Enabled) {
    try {
      const uploaded = await uploadBufferToS3({
        buffer: req.file.buffer,
        contentType: mime,
        originalName: req.file.originalname,
        folder: chooseFolder(mime),
      });
      return res.status(201).json({
        ...uploaded,
        storage: 's3',
      });
    } catch (err) {
      console.error('[media] S3 upload failed, falling back to local disk:', err.message);
    }
  }

  // Local disk fallback (dev / S3 not configured).
  const ext = EXT_BY_MIME[mime] || path.extname(req.file.originalname || '') || '.bin';
  const filename = `${Date.now()}-${randomUUID().slice(0, 8)}${ext}`;
  const dest = path.join(LOCAL_DIR, filename);
  await fs.promises.writeFile(dest, req.file.buffer);
  const url = `/audio/${filename}`;

  return res.status(201).json({
    url,
    key: filename,
    kind: mediaKindFromMime(mime),
    contentType: mime,
    storage: 'local',
  });
}

/** POST /admin/media — audio, PDF, or image → S3 URL (or local fallback). */
export const uploadMedia = [
  upload.single('file'),
  (req, res, next) => {
    handleUpload(req, res).catch(next);
  },
];

/** POST /admin/audio — kept for existing admin UI; audio only. */
export const uploadAudio = [
  upload.single('file'),
  (req, res, next) => {
    handleUpload(req, res, { audioOnly: true }).catch(next);
  },
];
