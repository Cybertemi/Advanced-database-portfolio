// Portfolio 4: load sample data into MongoDB (database: netiks_nosql)
const ndb = db.getSiblingDB('netiks_nosql');
ndb.products.drop();
ndb.orders.drop();

const categories = [
  { name: 'Phones',    slug: 'phones' },
  { name: 'Clothing',  slug: 'clothing' },
  { name: 'Books',     slug: 'books' },
  { name: 'Furniture', slug: 'furniture' }
];
const stores = Array.from({ length: 20 }, (_, i) => ({
  id: 'store-' + (i + 1), name: 'Store ' + (i + 1), slug: 'store-' + (i + 1)
}));

// Each category has different attributes: this is the flexible part
function attributesFor(slug, n) {
  switch (slug) {
    case 'phones':
      return { ram_gb: [4, 6, 8, 12][n % 4], storage_gb: [64, 128, 256, 512][n % 4],
               battery_mah: 3000 + (n % 5) * 500, colour: ['black', 'white', 'blue'][n % 3] };
    case 'clothing':
      return { size: ['S', 'M', 'L', 'XL'][n % 4], colour: ['red', 'black', 'green', 'white'][n % 4],
               fabric: ['cotton', 'linen', 'polyester'][n % 3] };
    case 'books':
      return { author: 'Author ' + (n % 100), pages: 100 + (n % 40) * 10,
               isbn: '978-' + String(1000000000 + n), language: 'English' };
    default:
      return { material: ['wood', 'steel', 'plastic'][n % 3], width_cm: 40 + (n % 10) * 10,
               height_cm: 50 + (n % 8) * 10, assembly_required: n % 2 === 0 };
  }
}

// Products
const products = [];
for (let i = 1; i <= 5000; i++) {
  const cat = categories[i % 4];
  const store = stores[i % 20];
  products.push({
    _id: 'prod-' + i,
    name: 'Product ' + i,
    slug: 'product-' + i,
    sku: 'SKU-' + i,
    price: Math.round((Math.random() * 500 + 1) * 100) / 100,
    currency: 'USD',
    category: cat,
    store: store,
    attributes: attributesFor(cat.slug, i),
    tags: [cat.slug, 'tag-' + (i % 10)],
    status: 'active',
    createdAt: new Date()
  });
}
ndb.products.insertMany(products);

// Orders: each holds its customer, items and payment together
const orders = [];
for (let i = 1; i <= 2000; i++) {
  const itemCount = 1 + (i % 3);
  const items = [];
  let total = 0;
  for (let k = 0; k < itemCount; k++) {
    const p = products[(i * 7 + k * 13) % products.length];
    const qty = 1 + ((i + k) % 3);
    items.push({ productId: p._id, name: p.name, quantity: qty, unitPrice: p.price });
    total += qty * p.price;
  }
  total = Math.round(total * 100) / 100;
  const c = (i % 500) + 1;
  orders.push({
    _id: 'order-' + i,
    customer: { id: 'cust-' + c, name: 'Customer ' + c, email: 'customer' + c + '@example.com' },
    shippingAddress: 'Address ' + i,
    status: ['pending', 'paid', 'shipped', 'delivered'][i % 4],
    items: items,
    payment: { method: 'demo-card', reference: 'PAY-' + i, amount: total, status: 'successful' },
    total: total,
    createdAt: new Date(Date.now() - (i % 365) * 86400000)
  });
}
ndb.orders.insertMany(orders);

print('products: ' + ndb.products.countDocuments());
print('orders:   ' + ndb.orders.countDocuments());