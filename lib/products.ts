export type Product = { name: string; slug: string; heat: string; price: number; size: string; image: string };
export const products: Product[] = [
  { name: 'Green Salsa', slug: 'green-salsa', heat: 'Mild / Medium', price: 10, size: '16 oz jar', image: 'green' },
  { name: 'Red Salsa', slug: 'red-salsa', heat: 'Medium', price: 10, size: '16 oz jar', image: 'red' },
  { name: 'Verde Salsa', slug: 'verde-salsa', heat: 'Medium / Hot', price: 11, size: '16 oz jar', image: 'verde' },
  { name: 'Habanero Salsa', slug: 'habanero-salsa', heat: 'Hot', price: 12, size: '16 oz jar', image: 'habanero' },
];
