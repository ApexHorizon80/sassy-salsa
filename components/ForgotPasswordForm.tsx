'use client';

import { FormEvent, useState } from 'react';
import { getSupabaseBrowserClient } from '@/lib/supabase';

export function ForgotPasswordForm() {
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setMessage('');
    if (!email.trim() || !/^\S+@\S+\.\S+$/.test(email)) return setError('Enter a valid email address.');
    const supabase = getSupabaseBrowserClient();
    if (!supabase) return setError('Authentication is not configured.');
    setLoading(true);
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: `${window.location.origin}/reset-password`,
    });
    setLoading(false);
    if (resetError) return setError('We could not send a reset email. Please try again.');
    setMessage('Check your email for a link to reset your password.');
  }

  return <form className="auth-form" onSubmit={submit}><h1>Reset your password</h1><p>Enter your email and we’ll send you a secure reset link.</p><label>Email<input type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" /></label>{error && <p role="alert">{error}</p>}{message && <p role="status">{message}</p>}<button className="btn btn-primary" disabled={loading}>{loading ? 'Please wait…' : 'Send reset link'}</button><p><a href="/sign-in">Back to sign in</a></p></form>;
}
