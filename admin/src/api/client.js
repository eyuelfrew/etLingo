import axios from 'axios';

// Backend base URL — set in `admin/.env` via VITE_API_URL.
// Fallback keeps the old relative path working if the var is missing.
const API_URL = import.meta.env.VITE_API_URL || '/api/v1';

export const apiOrigin = API_URL.replace(/\/api\/v\d+\/?$/, '');

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

export default client;
