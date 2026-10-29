# Portfolio 4: NoSQL and Advanced Data Models

**Case study:** Netiks Store (see the root README).

## 1. Overview
Some Netiks Store data fits a relational database poorly. Product details vary by product
type, and a product page or order history needs several related pieces of data at once.
This portfolio models that data in **MongoDB**, a document database, shows queries and an
index on it, and explains which data belongs in PostgreSQL and which in MongoDB.

## 2. What moves to NoSQL and what stays
| Data | Database | Why |
|---|---|---|
| Orders, payments, stock | PostgreSQL | Needs transactions, constraints and locking (Portfolio 3) |
| Users and stores | PostgreSQL | Structured, with clear relationships |
| Product catalogue details | **MongoDB** | Attributes differ between product types |
| Order history view | **MongoDB** | An order, its items and its payment are read together |

## 3. Setup
MongoDB 7 runs in its own container, `portfolio-mongo`, defined in the portfolio
`docker-compose.yml` and mapped to host port 27018, with a named volume for its data.
No authentication is enabled, which is acceptable for a local demonstration database only.
Full steps are in [01-mongo-setup.md](01-mongo-setup.md).

Evidence: `screenshots/01-mongo-running.png` 

## 4. Document model
| PostgreSQL | MongoDB |
|---|---|
| products + categories + stores | One `products` collection, with category and store embedded |
| orders + order_items + payments | One `orders` collection, with items and payment embedded |
| customers, users, stock, inventory_movements | Not moved |

**Product document** (attributes differ by category):
```js
{
  _id: "prod-1", name: "Product 1", slug: "product-1", price: 199.99,
  category: { name: "Phones", slug: "phones" },
  store: { id: "store-2", name: "Store 2" },
  attributes: { ram_gb: 8, storage_gb: 128, battery_mah: 4000, colour: "black" },
  tags: ["phones", "tag-1"]
}
```
**Order document:**
```js
{
  _id: "order-1",
  customer: { id: "cust-1", name: "Customer 1", email: "customer1@example.com" },
  status: "paid",
  items: [{ productId: "prod-7", name: "Product 7", quantity: 2, unitPrice: 50.00 }],
  payment: { method: "demo-card", reference: "PAY-1", amount: 100.00, status: "successful" },
  total: 100.00
}
```
**Design decisions:**
- Category and store details are **embedded**, so a product page needs one read and no join.
- Items and payment are embedded in the order, because they are always read with it.
  Item names and prices are copied at purchase time, so history does not change if the
  product later does (the same reasoning as `unit_price` in PostgreSQL).
- Stock is **not** stored in MongoDB: it changes constantly and needs locking which is why it stays
  in PostgreSQL.

Embedding suits data that is read together. In a case where product page always needs the product, its category and its store, so storing them in one document means one read and no join.
The cost is duplication: the same store or category details are copied into many product
documents, so if a store is renamed, every product that embeds it must be updated.

## 5. Data and queries
`02-load-data.js` generated 5,000 products (four categories with different attributes) and
2,000 orders. The data is synthetic, and some attributes are uniform as a side effect of
the generator (for example every phone has the same `ram_gb`).

| # | Query | What it shows | Evidence |
|---|---|---|---|
| Q1 | Black phones with battery of at least 4000 mAh under 300 | Filtering on fields that exist only on phones | `04-query-attributes.png` |
| Q2 | Books by a given author | Same collection, different fields | `05-query-books.png` |
| Q3 | One order by id | Customer, items and payment in one read | `06-order-lookup.png` |
| Q4 | Top-selling products | Aggregation with `$unwind`, `$group`, `$sort` | `07-top-products.png` |
| Q5 | Average price per category | Aggregation | `08-category-prices.png` |

Scripts: `02-load-data.js`, `03-queries.js`. Document examples:
`screenshots/02-flexible-documents.png`, `screenshots/03-order-document.png`


## 6. Index experiment
Q1 was measured with `explain('executionStats')`, run twice with the second run recorded,
then an index was added: `{ 'category.slug': 1, 'attributes.colour': 1, price: 1 }`.

| | Before | After |
|---|---|---|
| Plan | COLLSCAN (full scan) | IXSCAN (index) |
| Documents examined | 5,000 | 256 |
| Documents returned | 154 | 154 |
| Time (second run) | 15 ms | 1 ms |

The index puts the exact-match fields (category, colour) first and the range field (price)
last, so MongoDB jumps to black phones and reads only prices under 300. The battery
condition is not in the index, so it is checked on the 256 documents fetched, leaving 154.

Without the index, MongoDB read every product to answer Q1 (5,000 documents examined) but with the index, it jumped straight to the matching entries and examined only 256 documents,
and the result was the same 154 documents. It also made the query quicker, but the
timings were noisy at this size, so documents examined is the reliable measure.

Indexes have a cost and each one is an extra sorted copy of the data, so it uses more storage,
and every insert, update or delete must also update the index, which makes writes slower.
For that reason I only index fields that queries actually use.

Evidence: `screenshots/09-explain-before-index.png`, `10-create-index.png`,
`11-explain-after-index.png`. Script: `04-index.js`

## 7. Suitability: relational against document
| Question | PostgreSQL | MongoDB |
|---|---|---|
| Attributes that differ by product type | Many empty columns or an extra table | Each product holds only its own fields |
| Showing a product page | Join products, categories, stores | One read |
| Reading a whole order | Join orders, items, payments | One read |
| Stock and payments | Constraints, row locks, ACID | Weaker guarantees across documents |
| Changing a store's name | Update one row | Update every product that embeds it |
| Preventing invalid references | Foreign keys | None; the application must check |

The product catalogue suits a document database because each product type has different
attributes, a product page needs the product, category and store together, and the data is
mostly read and it uses flexible data structure. Also, Embedding gives a one-read lookup with no empty columns.

Orders, payments and stock stay in PostgreSQL because correctness matters most for them.
Portfolio 3 showed what protects them: transactions that roll back on failure, row locks
that prevent two buyers taking the last item, and constraints such as stock never going
negative. Stock also changes constantly, so copying it into other documents would risk
copies that disagree and incorrectness. Meanwhile, MongoDB does support multi-document transactions, but a relational database makes strict consistency the default.

## 8. Trade-offs and reflection
- **Duplication.** Embedded data is copied, so updates must reach every copy.
- **No foreign keys.** Nothing stops a document referring to something that does not exist.
- **Two databases.** Each is used for what it does best, but data must be kept consistent
  between them by the application.
- **Lesson.** NoSQL is flexible, but it is not suitable for all data, especially data where
  correctness is critical, such as payments and stock. An index makes searches much faster
  because the database no longer has to scan every document, but it costs storage and slows
  writes, so it should be used where queries need it.

## 9. How to run
1. Start MongoDB: `docker compose up -d portfolio-mongo` (see `01-mongo-setup.md`)
2. `docker compose up -d portfolio-mongo`
3. Copy the scripts in: `docker cp portfolio-4-nosql/02-load-data.js netiks-portfolio-mongo:/tmp/` (repeat for 03 and 04)
4. Run each: `docker exec netiks-portfolio-mongo mongosh --quiet --file /tmp/02-load-data.js`
5. Explore interactively: `docker exec -it netiks-portfolio-mongo mongosh netiks_nosql`

## 10. Files
| File | Contents |
|---|---|
| 01-mongo-setup.md | How the MongoDB container is defined, started and checked |
| 02-load-data.js | Generates products and orders |
| 03-queries.js | The five queries |
| 04-index.js | The index experiment |
| screenshots/ | Evidence (01 to 11) |