import { AccountPortal } from '@/components/AccountPortal';
import { AuthNav } from '@/components/AuthNav';
export const metadata = { title: 'Your account', robots: { index: false, follow: false } };
export default function AccountPage() { return <><header className="account-nav"><a href="/">Sassy Salsa</a><AuthNav /></header><AccountPortal /></>; }
