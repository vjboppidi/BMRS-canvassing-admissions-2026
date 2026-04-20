import { Navigate, useLocation } from 'react-router-dom';
import type { ReactNode } from 'react';
import { useAuth } from './useAuth';

export default function RequireAuth({
  children,
  adminOnly = false,
}: {
  children: ReactNode;
  adminOnly?: boolean;
}) {
  const { session } = useAuth();
  const loc = useLocation();

  if (!session) {
    return <Navigate to="/login" replace state={{ from: loc }} />;
  }
  if (adminOnly && session.teacher.role !== 'ADMIN') {
    return <Navigate to="/" replace />;
  }
  return <>{children}</>;
}
