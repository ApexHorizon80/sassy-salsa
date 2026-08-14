import { AuthForm } from '@/components/AuthForm';
export const metadata = { title: 'Create account', robots: { index: false, follow: false } };
export default function CreateAccountPage() { return <main className="auth-page"><AuthForm mode="sign-up" /></main>; }
