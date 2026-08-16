'use client';
import { useEffect, useState } from 'react';
import { getSupabaseBrowserClient } from '@/lib/supabase';

export function AuthNav() {
  const [email, setEmail] = useState<string | null>(null);
  useEffect(() => { const client = getSupabaseBrowserClient(); if (!client) return; client.auth.getSession().then(({ data }) => setEmail(data.session?.user.email ?? null)); const { data: listener } = client.auth.onAuthStateChange((_event, session) => setEmail(session?.user.email ?? null)); return () => listener.subscription.unsubscribe(); }, []);
  const signOut = async () => { const client = getSupabaseBrowserClient(); if (client) await client.auth.signOut(); };
  return <span className="auth-nav">{email ? <><a href="/account">Account</a><button className="text-link" onClick={signOut}>Sign Out</button></> : <><a href="/sign-in">Sign In</a><a href="/create-account">Create Account</a></>}</span>;
}
