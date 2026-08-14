import { NextResponse } from 'next/server';
import { getActiveProducts } from '@/lib/products';
export async function GET() { try { return NextResponse.json(await getActiveProducts()); } catch (error) { console.error('Supabase products query failed:', error instanceof Error ? error.message : 'Unknown error'); return NextResponse.json({ error: 'Unable to load products' }, { status: 503 }); } }
