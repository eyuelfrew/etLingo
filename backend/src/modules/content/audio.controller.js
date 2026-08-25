import { randomUUID } from 'crypto';
import path from 'path';
import fs from 'fs';
import multer from 'multer';
import { HttpError } from '../../core/http.js';

const AUDIO_DIR = path.resolve(process.cwd(), 'uploads', 'audio');
fs.mkdirSync(AUDIO_DIR, { recursive: true });

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
};

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, AUDIO_DIR),
    filename: (_req, file, cb) => {
      const ext = EXT_BY_MIME[file.mimetype] || path.extname(file.originalname || '').toLowerCase() || '.mp3';
      cb(null, `${Date.now()}-${randomUUID().slice(0, 8)}${ext}`);
    },
  }),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (EXT_BY_MIME[file.mimetype]) return cb(null, true);
    cb(new HttpError(400, 'Only audio files are allowed (mp3, wav, webm, ogg, m4a, aac).'));
  },
});

export const uploadAudio = [
  upload.single('file'),
  (req, res) => {
    if (!req.file) throw new HttpError(400, 'No audio file received.');
    res.status(201).json({ url: `/audio/${req.file.filename}` });
  },
];
