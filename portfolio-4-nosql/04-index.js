// Portfolio 4: index experiment on Q1 (before and after)
// Run with: docker exec netiks-portfolio-mongo mongosh --quiet --file /tmp/04-index.js
const ndb = db.getSiblingDB('netiks_nosql');
const indexName = 'category.slug_1_attributes.colour_1_price_1';

const q = { 'category.slug': 'phones', 'attributes.colour': 'black',
            'attributes.battery_mah': { $gte: 4000 }, price: { $lt: 300 } };

function summary(query) {
  const e = ndb.products.find(query).explain('executionStats');
  return {
    plan: JSON.stringify(e.queryPlanner.winningPlan).includes('IXSCAN') ? 'IXSCAN (index)' : 'COLLSCAN (full scan)',
    docsExamined: e.executionStats.totalDocsExamined,
    keysExamined: e.executionStats.totalKeysExamined,
    returned: e.executionStats.nReturned,
    ms: e.executionStats.executionTimeMillis
  };
}

// Start from a known state: remove the index if it exists
try { ndb.products.dropIndex(indexName); } catch (e) {}

print('--- BEFORE the index (run twice, keep the second) ---');
printjson(summary(q));
printjson(summary(q));

ndb.products.createIndex({ 'category.slug': 1, 'attributes.colour': 1, price: 1 });
print('--- Indexes ---');
printjson(ndb.products.getIndexes());

print('--- AFTER the index (run twice, keep the second) ---');
printjson(summary(q));
printjson(summary(q));