import { AuthForm } from '@/components/AuthForm';
export const metadata = { title: 'Sign in' };
export default function SignInPage() { return <main className="auth-page"><AuthForm mode="sign-in" /></main>; }
