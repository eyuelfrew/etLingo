import { useEffect, useRef, useState } from 'react';
import client, { apiOrigin } from '../api/client';
import { Button } from './ui';

export function resolveAudioUrl(path) {
  if (!path) return '';
  if (/^https?:\/\//i.test(path)) return path;
  return `${apiOrigin}${path}`;
}

export default function AudioField({ label = 'Audio', value, onChange }) {
  const [recording, setRecording] = useState(false);
  const [seconds, setSeconds] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const recorderRef = useRef(null);
  const streamRef = useRef(null);
  const chunksRef = useRef([]);
  const timerRef = useRef(null);
  const fileRef = useRef(null);

  useEffect(() => () => stopTracks(), []);

  const stopTracks = () => {
    clearInterval(timerRef.current);
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    setSeconds(0);
  };

  const uploadBlob = async (blob, filename) => {
    setBusy(true);
    setError('');
    try {
      const fd = new FormData();
      fd.append('file', blob, filename);
      const { data } = await client.post('/admin/audio', fd);
      onChange(data.url);
    } catch (err) {
      setError(err.response?.data?.error || 'Upload failed.');
    } finally {
      setBusy(false);
    }
  };

  const startRecording = async () => {
    setError('');
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;
      chunksRef.current = [];
      const rec = new MediaRecorder(stream);
      rec.ondataavailable = (e) => e.data.size && chunksRef.current.push(e.data);
      rec.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: rec.mimeType || 'audio/webm' });
        if (blob.size > 0) uploadBlob(blob, 'recording.webm');
        stopTracks();
      };
      recorderRef.current = rec;
      rec.start();
      setRecording(true);
      timerRef.current = setInterval(() => setSeconds((s) => s + 1), 1000);
    } catch {
      setError('Microphone access denied.');
    }
  };

  const stopRecording = () => {
    if (recorderRef.current?.state === 'recording') recorderRef.current.stop();
    setRecording(false);
  };

  return (
    <div>
      <span className="block text-[13px] font-semibold text-ink">{label}</span>
      <div className="mt-1.5 flex flex-wrap items-center gap-2">
        {!recording ? (
          <Button type="button" variant="secondary" onClick={startRecording} disabled={busy}>
            Record
          </Button>
        ) : (
          <Button type="button" variant="danger" onClick={stopRecording}>
            <span className="h-2 w-2 animate-pulse rounded-full bg-et-red" />
            Stop · {Math.floor(seconds / 60)}:{String(seconds % 60).padStart(2, '0')}
          </Button>
        )}

        <Button type="button" variant="secondary" onClick={() => fileRef.current?.click()} disabled={busy || recording}>
          Upload file
        </Button>
        <input
          ref={fileRef}
          type="file"
          accept="audio/*"
          className="hidden"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) uploadBlob(f, f.name);
            e.target.value = '';
          }}
        />

        {value && (
          <>
            <audio controls src={resolveAudioUrl(value)} className="h-10 max-w-[240px]" />
            <Button type="button" variant="ghost" onClick={() => onChange('')}>
              Remove
            </Button>
          </>
        )}
        {busy && <span className="text-[12px] font-medium text-muted">Uploading…</span>}
      </div>
      {error && <p className="mt-1.5 text-[12px] font-medium text-et-red">{error}</p>}
    </div>
  );
}
