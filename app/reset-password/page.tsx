import { ResetPasswordForm } from '@/components/ResetPasswordForm';

export const metadata = { title: 'Reset password', robots: { index: false, follow: false } };

export default function ResetPasswordPage() { return <main className="auth-page"><ResetPasswordForm /></main>; }
