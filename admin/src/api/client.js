import axios from 'axios';

// Default to the Vite proxy (/api/v1 → backend :5050) to avoid CORS in local dev.
const API_URL = import.meta.env.VITE_API_URL || '/api/v1';

export const apiOrigin = API_URL.startsWith('http')
  ? API_URL.replace(/\/api\/v\d+\/?$/, '')
  : window.location.origin;

const client = axios.create({ baseURL: API_URL });

client.interceptors.request.use((config) => {
  const token = localStorage.getItem('etlingo_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

client.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('etlingo_token');
      localStorage.removeItem('etlingo_admin');
      if (!location.pathname.includes('/login')) location.href = '/login';
    }
    return Promise.reject(err);
  },
);

export function apiError(err, fallback = 'Request failed') {
  return (
    err?.response?.data?.error ||
    err?.response?.data?.message ||
    (err?.code === 'ERR_NETWORK'
      ? 'Cannot reach the backend on :5050 — is `npm run dev` running in backend/?'
      : null) ||
    err?.message ||
    fallback
  );
}

export default client;
