import { AdminDashboard } from '@/components/AdminDashboard';
import { AdminProductCreate } from '@/components/AdminProductCreate';
import { AdminOperations } from '@/components/AdminOperations';
export default function AdminPage() { return <><AdminOperations /><AdminProductCreate /><AdminDashboard /></>; }
export const metadata = { title: 'Admin dashboard', robots: { index: false, follow: false } };
