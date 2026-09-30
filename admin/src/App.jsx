import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Languages from './pages/Languages';
import BaseLanguages from './pages/BaseLanguages';
import Lessons from './pages/Lessons';
import Phrases from './pages/Phrases';
import Users from './pages/Users';
import Notifications from './pages/Notifications';
import Storage from './pages/Storage';
import Culture from './pages/Culture';
import Community from './pages/Community';
import Scripts from './pages/Scripts';
import Topics from './pages/Topics';
import Ads from './pages/Ads';
import Plans from './pages/Plans';

function Protected({ children }) {
  const { admin } = useAuth();
  if (!admin) return <Navigate to="/login" replace />;
  return children;
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/"
            element={
              <Protected>
                <Layout />
              </Protected>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="languages" element={<Languages />} />
            <Route path="base-languages" element={<BaseLanguages />} />
            <Route path="lessons" element={<Lessons />} />
            <Route path="culture" element={<Culture />} />
            <Route path="community" element={<Community />} />
            <Route path="scripts" element={<Scripts />} />
            <Route path="topics" element={<Topics />} />
            <Route path="ads" element={<Ads />} />
            <Route path="plans" element={<Plans />} />
            <Route path="phrases" element={<Phrases />} />
            <Route path="users" element={<Users />} />
            <Route path="notifications" element={<Notifications />} />
            <Route path="storage" element={<Storage />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
