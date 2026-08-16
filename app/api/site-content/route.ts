import { NextResponse } from 'next/server';
import { getSupabaseServerClient } from '@/lib/supabase';
export async function GET() { const client = getSupabaseServerClient(); if (!client) return NextResponse.json([]); const { data, error } = await client.from('site_content').select('key,value').order('key'); if (error) return NextResponse.json({ error: 'Unable to load site content' }, { status: 503 }); return NextResponse.json(data ?? []); }
