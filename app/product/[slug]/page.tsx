import { getProductBySlug, getProductAvailability } from '@/lib/products';
import { notFound } from 'next/navigation';
import { ProductDetail } from '@/components/ProductDetail';
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) { const product = await getProductBySlug((await params).slug); return product ? { title: product.name, description: product.description } : { title: 'Product not found' }; }
export default async function ProductPage({ params }: { params: Promise<{ slug: string }> }) { const { slug } = await params; const product = await getProductBySlug(slug); if (!product) notFound(); return <ProductDetail product={product} />; }
