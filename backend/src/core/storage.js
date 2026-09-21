import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  HeadBucketCommand,
  ListObjectsV2Command,
  GetObjectCommand,
  PutBucketPolicyCommand,
  GetBucketPolicyCommand,
} from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import path from 'path';

const endpoint = process.env.S3_ENDPOINT || 'https://s3.aletcloud.com';
const region = process.env.S3_REGION || 'et-addis-1';
const bucket = process.env.S3_BUCKET || 't71-etlang';
const accessKeyId = process.env.S3_ACCESS_KEY_ID || '';
const secretAccessKey = process.env.S3_SECRET_ACCESS_KEY || '';
const publicBase =
  process.env.S3_PUBLIC_BASE_URL ||
  `${endpoint.replace(/\/$/, '')}/${bucket}`;
const keyPrefix = (process.env.S3_KEY_PREFIX || 'etlingo').replace(/^\/+|\/+$/g, '');

export const s3Enabled = Boolean(accessKeyId && secretAccessKey && bucket);

let client = null;

function getClient() {
  if (!s3Enabled) return null;
  if (!client) {
    client = new S3Client({
      region,
      endpoint,
      // AletCloud / MinIO-style endpoints usually need path-style.
      forcePathStyle: process.env.S3_FORCE_PATH_STYLE !== 'false',
      credentials: { accessKeyId, secretAccessKey },
    });
  }
  return client;
}

const EXT_BY_MIME = {
  'audio/mpeg': '.mp3',
  'audio/mp3': '.mp3',
  'audio/wav': '.wav',
  'audio/x-wav': '.wav',
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

export const ALLOWED_MEDIA_MIMES = Object.keys(EXT_BY_MIME);

export function mediaKindFromMime(mime) {
  if (!mime) return 'file';
  if (mime.startsWith('audio/')) return 'audio';
  if (mime === 'application/pdf') return 'pdf';
  if (mime.startsWith('image/')) return 'image';
  return 'file';
}

export function publicUrlForKey(key) {
  return `${publicBase.replace(/\/$/, '')}/${key}`;
}

/**
 * URL stored in the DB and used by admin + Flutter.
 *
 * AletCloud often rejects public-read ACL (AccessDenied XML), so default is a
 * **backend proxy** path that streams the object with our S3 credentials.
 * Flutter/admin resolve `/api/v1/...` against the API origin.
 *
 * Set S3_URL_MODE=public if the bucket policy allows anonymous GetObject.
 */
export function mediaUrlForKey(key) {
  const mode = process.env.S3_URL_MODE || 'proxy';
  if (mode === 'public') return publicUrlForKey(key);
  return `/api/v1/media/${key}`;
}

/** Full absolute URL for clients that need http(s) immediately. */
export function absoluteMediaUrl(key, apiOrigin) {
  const rel = mediaUrlForKey(key);
  if (/^https?:\/\//i.test(rel)) return rel;
  const origin = (apiOrigin || process.env.PUBLIC_API_ORIGIN || '').replace(/\/$/, '');
  return origin ? `${origin}${rel}` : rel;
}

export async function getObjectStream(key) {
  const c = getClient();
  if (!c) {
    const err = new Error('S3 is not configured');
    err.status = 503;
    throw err;
  }
  const safe = String(key || '').replace(/^\/+/, '');
  if (!safe.startsWith(`${keyPrefix}/`)) {
    const err = new Error('Invalid media key');
    err.status = 400;
    throw err;
  }
  const res = await c.send(new GetObjectCommand({ Bucket: bucket, Key: safe }));
  return {
    body: res.Body,
    contentType: res.ContentType || 'application/octet-stream',
    contentLength: res.ContentLength,
  };
}

/**
 * Best-effort: allow anonymous read on etlingo/* so raw S3 URLs also work.
 * Many S3-compatible hosts ignore ACL and need a bucket policy instead.
 */
export async function ensurePublicReadPolicy() {
  if (process.env.S3_URL_MODE !== 'public') return { applied: false, reason: 'proxy-mode' };
  const c = getClient();
  if (!c) return { applied: false, reason: 's3-disabled' };

  const policy = {
    Version: '2012-10-17',
    Statement: [
      {
        Sid: 'PublicReadEtLingoMedia',
        Effect: 'Allow',
        Principal: '*',
        Action: ['s3:GetObject'],
        Resource: [`arn:aws:s3:::${bucket}/${keyPrefix}/*`],
      },
    ],
  };

  try {
    await c.send(
      new PutBucketPolicyCommand({
        Bucket: bucket,
        Policy: JSON.stringify(policy),
      }),
    );
    return { applied: true };
  } catch (e) {
    return { applied: false, reason: e.message || e.name };
  }
}

export async function uploadBufferToS3({
  buffer,
  contentType,
  originalName,
  folder = 'media',
}) {
  const c = getClient();
  if (!c) return null;

  const mime = (contentType || 'application/octet-stream').toLowerCase();
  const ext =
    EXT_BY_MIME[mime] ||
    path.extname(originalName || '').toLowerCase() ||
    '';
  const safeFolder = folder.replace(/^\/+|\/+$/g, '') || 'media';
  const key = `${keyPrefix}/${safeFolder}/${Date.now()}-${randomUUID().slice(0, 10)}${ext}`;

  await c.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType: mime,
      // Public read so learners can stream audio / open PDFs without signed URLs.
      ACL: process.env.S3_ACL || 'public-read',
    }),
  );

  return {
    url: mediaUrlForKey(key),
    publicUrl: publicUrlForKey(key),
    key,
    kind: mediaKindFromMime(mime),
    contentType: mime,
    storage: 's3',
  };
}

export async function deleteFromS3(key) {
  const c = getClient();
  if (!c || !key) return false;
  try {
    await c.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
    return true;
  } catch {
    return false;
  }
}

export async function pingS3() {
  const c = getClient();
  if (!c) return 'disabled';
  try {
    await c.send(new HeadBucketCommand({ Bucket: bucket }));
    return 'up';
  } catch (e) {
    return `down (${e.name || e.message})`;
  }
}

/**
 * List objects in the bucket for the admin storage browser.
 * prefix: folder inside the bucket, e.g. "etlingo/audio/"
 */
export async function listS3Objects({ prefix = '', maxKeys = 200 } = {}) {
  const c = getClient();
  if (!c) {
    const err = new Error('S3 is not configured');
    err.status = 503;
    throw err;
  }
  const fullPrefix = prefix
    ? `${keyPrefix}/${String(prefix).replace(/^\/+/, '')}`
    : `${keyPrefix}/`;

  const res = await c.send(
    new ListObjectsV2Command({
      Bucket: bucket,
      Prefix: fullPrefix,
      MaxKeys: Math.min(Number(maxKeys) || 200, 1000),
    }),
  );

  const objects = (res.Contents || [])
    .filter((o) => o.Key && !o.Key.endsWith('/'))
    .map((o) => {
      const key = o.Key;
      const rel = key.startsWith(`${keyPrefix}/`)
        ? key.slice(keyPrefix.length + 1)
        : key;
      return {
        key,
        name: path.posix.basename(key),
        path: rel,
        folder: path.posix.dirname(rel),
        size: o.Size ?? 0,
        lastModified: o.LastModified,
        url: mediaUrlForKey(key),
        publicUrl: publicUrlForKey(key),
        kind: kindFromKey(key),
      };
    });

  return {
    bucket,
    prefix: fullPrefix,
    objects,
    count: objects.length,
    truncated: res.IsTruncated === true,
  };
}

function kindFromKey(key) {
  const k = key.toLowerCase();
  if (/\.(mp3|m4a|wav|ogg|webm|aac)$/.test(k)) return 'audio';
  if (/\.pdf$/.test(k)) return 'pdf';
  if (/\.(png|jpe?g|webp|gif)$/.test(k)) return 'image';
  return 'file';
}

export function getS3Status() {
  return {
    enabled: s3Enabled,
    endpoint,
    bucket,
    region,
    publicBase,
  };
}
