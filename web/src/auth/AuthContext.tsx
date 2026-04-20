import { useCallback, useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { api, tokenStorage } from '../api/client';
import type { Session, Teacher } from '../types';
import { AuthContext } from './authContext';

const PROFILE_KEY = 'bmrs.auth.teacher';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(() => {
    const token = tokenStorage.get();
    const raw = localStorage.getItem(PROFILE_KEY);
    if (!token || !raw) return null;
    try {
      const teacher = JSON.parse(raw) as Teacher;
      return { token, teacher };
    } catch {
      return null;
    }
  });
  const [loading, setLoading] = useState(false);

  // Validate a restored session against /auth/me. If the token is dead, log out.
  useEffect(() => {
    if (!session) return;
    let cancelled = false;
    api
      .get<{ teacher: Teacher }>('/auth/me')
      .then(({ data }) => {
        if (cancelled) return;
        setSession((prev) => (prev ? { ...prev, teacher: data.teacher } : prev));
        localStorage.setItem(PROFILE_KEY, JSON.stringify(data.teacher));
      })
      .catch(() => {
        if (cancelled) return;
        tokenStorage.clear();
        localStorage.removeItem(PROFILE_KEY);
        setSession(null);
      });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    setLoading(true);
    try {
      const { data } = await api.post<Session>('/auth/login', { email, password });
      tokenStorage.set(data.token);
      localStorage.setItem(PROFILE_KEY, JSON.stringify(data.teacher));
      setSession(data);
    } finally {
      setLoading(false);
    }
  }, []);

  const logout = useCallback(() => {
    tokenStorage.clear();
    localStorage.removeItem(PROFILE_KEY);
    setSession(null);
  }, []);

  const value = useMemo(
    () => ({ session, loading, login, logout }),
    [session, loading, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
