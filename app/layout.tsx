import './globals.css';
export const metadata = { title: 'Sassy Salsa — Small batch. Big flavor.', description: 'Bold Flavor. Made with Love.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
