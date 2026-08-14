import { AdminDashboard } from '@/components/AdminDashboard';
import { AdminProductCreate } from '@/components/AdminProductCreate';
export default function AdminPage() { return <><AdminProductCreate /><AdminDashboard /></>; }
export const metadata = { title: 'Admin dashboard' };
