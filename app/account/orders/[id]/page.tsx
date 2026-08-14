import { OrderDetails } from '@/components/OrderDetails';
export default function OrderPage({ params }: { params: { id: string } }) { return <><header className="account-nav"><a href="/">Sassy Salsa</a><a href="/account">My account</a></header><OrderDetails orderId={params.id}/></>; }
