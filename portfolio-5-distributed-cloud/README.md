# Portfolio 5: Distributed and Cloud Database Exercise

**Case study:** Netiks Store (see the root README).

## 1. Overview
A single database server is a single point of failure and a capacity limit. This portfolio
builds a PostgreSQL primary with an asynchronous streaming read replica, demonstrates
replication, replication lag and failover, and discusses sharding, the
consistency/availability trade-off and cloud deployment for Netiks Store.

## 2. Setup
- The replica (`portfolio-replica`, host port 5434) is defined in the repository's
  `docker-compose.yml`. On first start it copies the primary with `pg_basebackup -R` and then
  runs as a standby that streams changes from the primary.
- The primary has a `replicator` role with the REPLICATION privilege and a `pg_hba.conf`
  entry allowing it to connect.
- Credentials come from a `.env` file that is not committed. `.env.example` lists the
  variables (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `REPLICATION_PASSWORD`).

Full steps: [01-replica-setup.md](01-replica-setup.md).
Evidence: `screenshots/00-replica-setup.png` (the log ends with "started streaming WAL from primary").

## 3. Replication works
`pg_stat_replication` on the primary shows the replica as `streaming` and `async`, and
`pg_is_in_recovery()` on the replica returns `t`. A change made on the primary
(`Product 1 (replicated)`) was then read from the replica.

Evidence: `screenshots/01-replication-status.png`, `screenshots/02-replication-works.png`

## 4. The replica is read-only
Writing to the replica fails with `cannot execute UPDATE in a read-only transaction`. All
writes must go to the primary, and reads can be spread across replicas.

Evidence: `screenshots/03-replica-readonly.png`

A read replica is a read-only copy of the database. In Netiks Store it serves traffic that
only reads data, such as browsing and searching products, so the primary is free to handle
writes like checkout and payments. It can also be promoted to become the primary if the
primary fails.

## 5. Replication lag, consistency and availability
Replay on the replica was paused to simulate a slow network. A change was then made on the
primary. The primary returned the new value (`Product 1 (new price list)`) while the replica
still returned the old one (`Product 1`), and `bytes_behind` was 57,616. After replay was
resumed the replica caught up and the copies agreed again.

Evidence: `screenshots/04-replication-lag.png`, `screenshots/05-replica-caught-up.png`

**What this shows.** While behind, the replica kept answering with out-of-date data instead
of refusing, so it favoured **availability** over **consistency**. The copies were only
*eventually* consistent. Under the CAP trade-off, when the network between servers fails, a
system must either keep answering (possibly stale) or refuse until it is sure (consistent).

| Part of Netiks Store | Reads from | Why |
|---|---|---|
| Browsing, search, reports | Replica | A slightly old value is acceptable |
| Checkout, payments, stock | Primary | Must be exact (see Portfolio 3) |

The replica uses asynchronous replication, so writes are fast, but changes not yet copied
would be lost if the primary failed. Synchronous replication avoids that at the cost of
slower writes.

## 6. Failover (availability)
The primary container was stopped. The replica still answered reads, so browsing continued,
but writes were refused. `pg_promote()` then turned the replica into a primary
(`pg_is_in_recovery()` returned `f`) and it accepted writes. Afterwards the replica was
rebuilt from the original primary to restore the setup.

Evidence: `screenshots/06-primary-down.png`, `07-replica-serves-reads.png`,
`08-promoted-and-writes.png`, `09-setup-restored.png`

**Points to note.**
- Promotion was manual. Production systems automate failure detection and promotion.
- A write made after promotion exists only on the promoted server. If the old primary came
  back while both accepted writes, the data would diverge (split-brain), so the old primary
  must be kept out. That is why the replica was rebuilt from scratch.
- Asynchronous replication can lose the last uncopied changes at failover.

## 7. Sharding (discussion)
Replication copies all the data; sharding splits it across servers so that each holds only
part. I would shard to spread data and write load so that no single server becomes overloaded.

| Data | Shard key | Reason | Trade-off |
|---|---|---|---|
| Orders, order items, payments | customer_id | "My orders" hits one shard | Vendor sales reports must ask every shard |
| Products | store_id | A vendor's data stays together | Very large stores become hotspots |
| Users, categories | Not sharded | Small and read everywhere | Copied to every shard |

**Challenges:** cross-shard queries, cross-shard transactions (the guarantees demonstrated in
Portfolio 3 are simple only within one server), and resharding when shards are added.

**Does Netiks Store need it?** Not yet. With about 200,000 orders and no overloaded server,
simpler steps come first: better indexes (Portfolio 2), read replicas (this portfolio), and a
larger server. Sharding adds complexity and is justified only when one primary can no longer
cope with the data size or the write load.

## 8. Cloud deployment (discussion)
Netiks Store was deployed on a single Azure virtual machine with Docker Compose, which is a
single point of failure.

| | Self-managed (VM with Docker) | Managed cloud database |
|---|---|---|
| Replicas and failover | Set up and promoted by hand, as in this portfolio | Provided as features, often automatic across availability zones |
| Backups and patching | Our responsibility | Handled by the provider |
| Control | Full | Limited |
| Cost | Lower service cost, more of our time | Usually higher |

A managed service adds automatic failover, backups, patching and availability zones, which I
had to set up and run by hand in this portfolio. The trade-off is that it usually costs more
and gives less control than a self-managed VM, and it can tie the system to one provider
(lock-in). Self-managed is usually cheaper in service cost and gives full control, but it
costs more of my own time and effort.

## 9. Reflection
- Under the CAP trade-off, a database cannot be fully consistent and fully available when
  the network between servers fails: it either serves possibly outdated data to stay
  available, or waits/refuses to stay consistent.
- A read replica cannot be written to; all writes go to the primary.
- Sharding suits servers that are genuinely overloaded, but it is complex, and small shared
  data such as users and categories is usually copied to every shard instead.
- Managed services give automatic failover and backups, but cost more and give less control
  than a self-managed VM, so they are not the right choice for everything.
- Credentials belong in a `.env` file that is never committed, with a `.env.example` listing
  the variable names. The file must also use `KEY=value` format, because the YAML style
  `KEY: value` cannot be read by the shell, which left the variables empty and broke the
  setup until I fixed it.
## 10. How to run
1. Fill in `.env` from `.env.example`.
2. Follow [01-replica-setup.md](01-replica-setup.md).
3. `bash portfolio-5-distributed-cloud/02-replication-demo.sh`
4. `bash portfolio-5-distributed-cloud/03-failover-demo.sh`

Each script pauses after every step so a screenshot can be taken.

## 11. Files
| File | Contents |
|---|---|
| 01-replica-setup.md | The replica service, primary preparation and verification |
| 02-replication-demo.sh | Replication, read-only and lag demos |
| 03-failover-demo.sh | Failover demo and restoring the setup |
| screenshots/ | Evidence (00 to 09) |