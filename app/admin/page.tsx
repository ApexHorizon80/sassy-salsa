import { AdminDashboard } from '@/components/AdminDashboard';
import { AdminProductCreate } from '@/components/AdminProductCreate';
import { AdminOperations } from '@/components/AdminOperations';
import { AdminCustomerDirectory } from '@/components/AdminCustomerDirectory';
import { AdminHomepageEditor } from '@/components/AdminHomepageEditor';
export default function AdminPage() { return <main className="admin-shell"><header className="admin-topbar"><div><p className="eyebrow">Sassy Salsa operations</p><h1>Admin workspace</h1><p>Manage orders, customers, products, and store availability.</p></div><nav className="admin-nav" aria-label="Admin sections"><a href="#overview">Overview</a><a href="#fulfillment">Fulfillment</a><a href="#catalog">Catalog</a><a href="#homepage">Homepage</a><a href="#customers">Customers</a><a href="/">View storefront →</a></nav></header><div id="overview"><AdminOperations /></div><div id="catalog"><AdminProductCreate /><AdminDashboard /></div><div id="homepage"><AdminHomepageEditor /></div><div id="customers"><AdminCustomerDirectory /></div></main>; }
export const metadata = { title: 'Admin dashboard', robots: { index: false, follow: false } };
