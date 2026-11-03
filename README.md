### Organisation / Scenario: Netiks Store

Netiks Store is a simulated multi-vendor online marketplace where independent vendors list products for sale, customers browse and buy them.


### Nature of the system

The system entails a web-based e-commerce platform built as a set of services (gateway, identity, vendor, catalog, media and admin) backed by PostgreSQL with Redis available for caching and this portfolio focuses on the data layer that supports it. The existing Netiks Store schema covers users and sessions(identity), vendor stores (vendor), product catalogue, product and a basic orders table (catalog).This portfolio extends it with order items, inventory and payment tables, implemented as a simulated workload, to support transaction and concurrency analysis.

### Users of the database:
The below consists of the main users of the database:

1. Customers: to browse for products, order and make payments.
2. Vendors: to manage their products and stock, and fulfil customers' orders
3. Administrators: to manage users, vendors and audit orders

### Major data stored

The following data are stored in the database of Netiks store:

1. User accounts and roles
2. Vendor profiles
3. Products and categories
4. Product images/media metadata
5. Inventory levels
6. Orders and order items
7. Payments and delivery status.

### Key operations supported:
Netiks store carries out and supports the folowing operations:

1. Register and authenticate users
2. Onboard a vendor and list a product
3. Search and filter the catalogue
4. Place an order and deduct stock
5. Process payment and update order status
6. Generate vendor sales reports and admin audit queries

## AI Use Declaration
- **Tool used:** Claude (Anthropic).
- **Used for:** explaining database concepts (normalisation, execution plans, transactions,
  document models, replication), drafting SQL and shell scripts, structuring README files,
  and helping debug Docker and configuration errors.
- **How I verified it:** I ran every script and query myself in my own PostgreSQL, MongoDB
  and Docker environment and took my own screenshots. I compared the execution plans with
  my measurements, corrected the AI where my results differed (for example the baseline
  timings in Portfolio 2), rewrote the explanations in my own words, and can explain each
  design decision.