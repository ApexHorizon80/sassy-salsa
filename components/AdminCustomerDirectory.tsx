'use client';

import { useEffect, useMemo, useState } from 'react';
import { getSupabaseBrowserClient } from '@/lib/supabase';

type Profile = { user_id: string; full_name: string; email: string; phone: string | null; address: string | null; city: string | null; state: string | null; postal_code: string | null; created_at: string };
type Order = { id: string; user_id: string | null; order_number: string; order_type: string; status: string; total_amount: number | null; requested_date: string | null; created_at: string; order_items: { product_name: string; quantity: number }[] };

export function AdminCustomerDirectory() {
  const client = getSupabaseBrowserClient();
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!client) return;
    (async () => {
      const [{ data: profileRows, error: profileError }, { data: orderRows, error: orderError }] = await Promise.all([
        client.from('customer_profiles').select('user_id,full_name,email,phone,address,city,state,postal_code,created_at').order('created_at', { ascending: false }),
        client.from('orders').select('id,user_id,order_number,order_type,status,total_amount,requested_date,created_at,order_items(product_name,quantity)').order('created_at', { ascending: false }),
      ]);
      if (profileError || orderError) setError(profileError?.message || orderError?.message || 'Unable to load customer operations.');
      setProfiles((profileRows ?? []) as Profile[]);
      setOrders((orderRows ?? []) as Order[]);
    })();
  }, [client]);

  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase();
    return profiles.filter((profile) => !query || [profile.full_name, profile.email, profile.phone, profile.city, profile.state].some((value) => value?.toLowerCase().includes(query)));
  }, [profiles, search]);

  const ordersFor = (userId: string) => orders.filter((order) => order.user_id === userId);
  const selected = selectedId ? profiles.find((profile) => profile.user_id === selectedId) : null;
  const selectedOrders = selected ? ordersFor(selected.user_id) : [];

  return <section className="admin-card customer-directory"><div className="admin-section-heading"><div><p className="eyebrow">Customer operations</p><h2>Customers & delivery details</h2></div><input aria-label="Search customers" placeholder="Search name, email, phone, or city" value={search} onChange={(event) => setSearch(event.target.value)} /></div>{error && <p role="alert">{error}</p>}<div className="customer-directory-grid"><div className="customer-list">{filtered.map((profile) => { const customerOrders = ordersFor(profile.user_id); return <button className={selectedId === profile.user_id ? 'customer-row selected' : 'customer-row'} key={profile.user_id} onClick={() => setSelectedId(profile.user_id)}><span><strong>{profile.full_name || 'Unnamed customer'}</strong><small>{profile.email}</small></span><span><strong>{customerOrders.length}</strong><small>{customerOrders.length === 1 ? 'order' : 'orders'}</small></span></button>; })}{!filtered.length && <p>No matching customers.</p>}</div>{selected ? <div className="customer-detail"><div className="customer-detail-heading"><div><p className="eyebrow">Customer profile</p><h3>{selected.full_name || 'Unnamed customer'}</h3></div><button className="btn btn-outline" onClick={() => setSelectedId(null)}>Close</button></div><p><strong>Email:</strong> {selected.email}</p><p><strong>Phone:</strong> {selected.phone || 'Not provided'}</p><p><strong>Delivery address:</strong> {[selected.address, selected.city, selected.state, selected.postal_code].filter(Boolean).join(', ') || 'Not provided'}</p><h4>Order history</h4>{selectedOrders.length ? selectedOrders.map((order) => <article className="customer-order-summary" key={order.id}><div><strong>{order.order_number}</strong><span>{order.order_type} · {order.status}</span></div><span>{order.order_items.map((item) => `${item.product_name} × ${item.quantity}`).join(', ')}</span><strong>${Number(order.total_amount ?? 0).toFixed(2)}</strong></article>) : <p>No orders yet.</p>}</div> : <div className="customer-empty"><h3>Select a customer</h3><p>Review contact information, delivery details, and order history here.</p></div>}</div></section>;
}
