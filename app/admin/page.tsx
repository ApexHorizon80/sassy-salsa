import { AdminDashboard } from '@/components/AdminDashboard';
import { AdminProductCreate } from '@/components/AdminProductCreate';
import { AdminOperations } from '@/components/AdminOperations';
import { AdminCustomerDirectory } from '@/components/AdminCustomerDirectory';
export default function AdminPage() { return <><AdminOperations /><AdminProductCreate /><AdminDashboard /><AdminCustomerDirectory /></>; }
export const metadata = { title: 'Admin dashboard', robots: { index: false, follow: false } };
