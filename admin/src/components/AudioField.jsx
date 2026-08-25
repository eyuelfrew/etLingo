import { useEffect, useRef, useState } from 'react';
import client, { apiOrigin } from '../api/client';

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
    recorderRef.current?.state === 'recording' && recorderRef.current.stop();
    setRecording(false);
  };

  return (
    <div>
      <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">{label}</span>
      <div className="flex flex-wrap items-center gap-2">
        {!recording ? (
          <button
            type="button"
            onClick={startRecording}
            disabled={busy}
            className="rounded-xl border border-stone-200 px-3 py-2 text-xs font-black uppercase tracking-wide text-stone-600 hover:bg-stone-50 disabled:opacity-50"
          >
            🎤 Record
          </button>
        ) : (
          <button
            type="button"
            onClick={stopRecording}
            className="flex items-center gap-2 rounded-xl bg-red-600 px-3 py-2 text-xs font-black uppercase tracking-wide text-white hover:bg-red-500"
          >
            <span className="h-2 w-2 animate-pulse rounded-full bg-white" />
            Stop · {Math.floor(seconds / 60)}:{String(seconds % 60).padStart(2, '0')}
          </button>
        )}

        <button
          type="button"
          onClick={() => fileRef.current?.click()}
          disabled={busy || recording}
          className="rounded-xl border border-stone-200 px-3 py-2 text-xs font-black uppercase tracking-wide text-stone-600 hover:bg-stone-50 disabled:opacity-50"
        >
          ⬆ Upload
        </button>
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
            <audio controls src={resolveAudioUrl(value)} className="h-9 max-w-[220px]" />
            <button
              type="button"
              onClick={() => onChange('')}
              title="Remove audio"
              className="px-1 font-bold text-red-500 hover:text-red-700"
            >
              ✕
            </button>
          </>
        )}
        {busy && <span className="text-xs font-bold text-stone-400">Uploading…</span>}
      </div>
      {error && <p className="mt-1 text-xs font-semibold text-red-600">⚠ {error}</p>}
    </div>
  );
}
