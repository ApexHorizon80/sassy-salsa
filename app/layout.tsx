import './globals.css';
export const metadata = { title: { default: 'Sassy Salsa — Small batch. Big flavor.', template: '%s | Sassy Salsa' }, description: 'Small-batch salsa with big personality. Bold flavor, made with love.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
