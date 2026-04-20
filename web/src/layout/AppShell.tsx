import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/useAuth';

export default function AppShell() {
  const { session, logout } = useAuth();
  const navigate = useNavigate();

  const onLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  const isAdmin = session?.teacher.role === 'ADMIN';

  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">BMRS Admissions</div>
        <nav className="nav">
          <NavLink to="/" end>
            Leads
          </NavLink>
          {isAdmin && <NavLink to="/analytics">Analytics</NavLink>}
          <NavLink to="/highlights">Highlights</NavLink>
        </nav>
        <div className="user">
          <span>{session?.teacher.name}</span>
          <span className="muted small">{session?.teacher.role.toLowerCase()}</span>
          <button className="ghost" onClick={onLogout}>
            Sign out
          </button>
        </div>
      </header>
      <main>
        <Outlet />
      </main>
    </div>
  );
}
