import { getSupabaseServerClient } from './supabase';
export type Product = { id: string; name: string; slug: string; description: string; price: number; jar_size: string; heat_level: string; image_url: string; is_active: boolean; preorder_enabled: boolean; preorder_available_date: string | null; quantity: number; image: string; heat: string; size: string };
export type Availability = 'AVAILABLE NOW' | 'PRE-ORDER' | 'SOLD OUT';

export function getProductAvailability(product: Pick<Product, 'quantity' | 'preorder_enabled'>): Availability {
  if (product.quantity > 0) return 'AVAILABLE NOW';
  return product.preorder_enabled ? 'PRE-ORDER' : 'SOLD OUT';
}

function normalize(row: Record<string, unknown>): Product {
  const name = String(row.name); const slug = String(row.slug);
  const inventory = Array.isArray(row.inventory) ? row.inventory[0] as Record<string, unknown> | undefined : row.inventory as Record<string, unknown> | undefined;
  return { ...row, id: String(row.id), name, slug, description: String(row.description ?? ''), price: Number(row.price), jar_size: String(row.jar_size), heat_level: String(row.heat_level), image_url: String(row.image_url ?? ''), is_active: Boolean(row.is_active), preorder_enabled: Boolean(row.preorder_enabled), preorder_available_date: row.preorder_available_date ? String(row.preorder_available_date) : null, quantity: Number(inventory?.quantity ?? row.quantity ?? 0), image: slug.replace('-salsa', ''), heat: String(row.heat_level), size: String(row.jar_size) };
}

export async function getProducts(): Promise<Product[]> {
  const client = getSupabaseServerClient();
  if (!client) return [];
  const { data, error } = await client.from('products').select('*, inventory(quantity)').order('created_at');
  if (error) throw new Error(`Unable to load products: ${error.message}`);
  return (data ?? []).map(normalize);
}
export async function getActiveProducts() { return (await getProducts()).filter((p) => p.is_active); }
export async function getProductBySlug(slug: string) { return (await getActiveProducts()).find((p) => p.slug === slug) ?? null; }
