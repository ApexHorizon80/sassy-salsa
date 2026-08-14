import { AuthForm } from '@/components/AuthForm';
export const metadata = { title: 'Sign in', robots: { index: false, follow: false } };
export default function SignInPage() { return <main className="auth-page"><AuthForm mode="sign-in" /></main>; }
