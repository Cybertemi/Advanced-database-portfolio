// Portfolio 4: the five queries (database: netiks_nosql)
// Run with: docker exec netiks-portfolio-mongo mongosh --quiet --file /tmp/03-queries.js
const ndb = db.getSiblingDB('netiks_nosql');

print('--- Q1: phones filtered on flexible attributes ---');
printjson(ndb.products.find(
  { 'category.slug': 'phones', 'attributes.colour': 'black',
    'attributes.battery_mah': { $gte: 4000 }, price: { $lt: 300 } },
  { name: 1, price: 1, attributes: 1 }
).limit(5).toArray());

print('--- Q2: books by author (different attribute fields) ---');
printjson(ndb.products.find(
  { 'category.slug': 'books', 'attributes.author': 'Author 42' },
  { name: 1, price: 1, attributes: 1 }
).limit(3).toArray());

print('--- Q3: one read returns a whole order ---');
printjson(ndb.orders.findOne({ _id: 'order-100' }));

print('--- Q4: top-selling products (aggregation) ---');
printjson(ndb.orders.aggregate([
  { $unwind: '$items' },
  { $group: { _id: '$items.name',
              unitsSold: { $sum: '$items.quantity' },
              revenue: { $sum: { $multiply: ['$items.quantity', '$items.unitPrice'] } } } },
  { $sort: { revenue: -1 } },
  { $limit: 5 }
]).toArray());

print('--- Q5: average price per category ---');
printjson(ndb.products.aggregate([
  { $group: { _id: '$category.name', avgPrice: { $avg: '$price' }, products: { $sum: 1 } } },
  { $sort: { avgPrice: -1 } }
]).toArray());