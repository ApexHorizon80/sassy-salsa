'use client';

import { FormEvent, useEffect, useState } from 'react';
import { getSupabaseBrowserClient } from '@/lib/supabase';

export function ResetPasswordForm() {
  const [ready, setReady] = useState(false);
  const [newPassword, setNewPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const supabase = getSupabaseBrowserClient();
    if (!supabase) {
      setError('Authentication is not configured.');
      return;
    }
    let active = true;
    supabase.auth.getSession().then(({ data }) => {
      if (active) setReady(Boolean(data.session));
    });
    const { data: listener } = supabase.auth.onAuthStateChange((event, session) => {
      if (active && (event === 'PASSWORD_RECOVERY' || session)) setReady(true);
    });
    return () => { active = false; listener.subscription.unsubscribe(); };
  }, []);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setMessage('');
    if (!ready) return setError('This reset link is invalid or has expired. Request a new one.');
    if (newPassword.length < 6) return setError('Password must be at least 6 characters.');
    if (newPassword !== confirmation) return setError('Passwords do not match.');
    const supabase = getSupabaseBrowserClient();
    if (!supabase) return setError('Authentication is not configured.');
    setLoading(true);
    const { error: updateError } = await supabase.auth.updateUser({ password: newPassword });
    setLoading(false);
    if (updateError) return setError('We could not update your password. Please request a new reset link.');
    setMessage('Your password has been changed successfully.');
    setNewPassword('');
    setConfirmation('');
  }

  if (message) return <section className="auth-form"><h1>Password updated</h1><p role="status">{message}</p><a className="btn btn-primary" href="/sign-in">Back to sign in</a></section>;
  return <form className="auth-form" onSubmit={submit}><h1>Choose a new password</h1><p>{ready ? 'Enter and confirm your new password below.' : 'Checking your secure reset link…'}</p><label>New password<input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} autoComplete="new-password" disabled={!ready} /></label><label>Confirm new password<input type="password" value={confirmation} onChange={(e) => setConfirmation(e.target.value)} autoComplete="new-password" disabled={!ready} /></label>{error && <p role="alert">{error}</p>}<button className="btn btn-primary" disabled={loading || !ready}>{loading ? 'Please wait…' : 'Update password'}</button><p><a href="/sign-in">Back to sign in</a></p></form>;
}
