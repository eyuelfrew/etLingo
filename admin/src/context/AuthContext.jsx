import { createContext, useContext, useState } from 'react';
import client from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [admin, setAdmin] = useState(() => {
    try {
      const raw = localStorage.getItem('etlingo_admin');
      return raw ? JSON.parse(raw) : null;
    } catch {
      localStorage.removeItem('etlingo_admin');
      localStorage.removeItem('etlingo_token');
      return null;
    }
  });

  const login = async (email, password) => {
    const { data } = await client.post('/auth/login', { email, password });
    // Backend returns flat: { token, id, name, email, role, created_at }
    const { token, ...adminData } = data;
    localStorage.setItem('etlingo_token', token);
    localStorage.setItem('etlingo_admin', JSON.stringify(adminData));
    setAdmin(adminData);
    return adminData;
  };

  const logout = () => {
    localStorage.removeItem('etlingo_token');
    localStorage.removeItem('etlingo_admin');
    setAdmin(null);
  };

  return (
    <AuthContext.Provider value={{ admin, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
