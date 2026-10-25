
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: catalog; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA catalog;


--
-- Name: identity; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA identity;


--
-- Name: vendor; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vendor;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: catalog; Owner: -
--

CREATE TABLE catalog.categories (
    id character varying(36) NOT NULL,
    name character varying(120) NOT NULL,
    slug character varying(140) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: orders; Type: TABLE; Schema: catalog; Owner: -
--

CREATE TABLE catalog.orders (
    id character varying(36) NOT NULL,
    product_id character varying(36) NOT NULL,
    store_id character varying(36) NOT NULL,
    owner_id character varying(36) NOT NULL,
    buyer_name character varying(120) NOT NULL,
    buyer_email character varying(255) NOT NULL,
    buyer_phone character varying(40),
    shipping_address text NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    total_price numeric(10,2) NOT NULL,
    payment_method character varying(40) DEFAULT 'demo-card'::character varying NOT NULL,
    payment_reference character varying(80) NOT NULL,
    status character varying(40) DEFAULT 'paid'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: products; Type: TABLE; Schema: catalog; Owner: -
--

CREATE TABLE catalog.products (
    id character varying(36) NOT NULL,
    store_id character varying(36) NOT NULL,
    owner_id character varying(36) NOT NULL,
    category_id character varying(36) NOT NULL,
    name character varying(160) NOT NULL,
    slug character varying(180) NOT NULL,
    description text NOT NULL,
    price numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    stock_quantity integer DEFAULT 0 NOT NULL,
    sku character varying(80) NOT NULL,
    status character varying(40) DEFAULT 'draft'::character varying NOT NULL,
    featured_image_url character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    sold_quantity integer DEFAULT 0 NOT NULL
);


--
-- Name: auth_sessions; Type: TABLE; Schema: identity; Owner: -
--

CREATE TABLE identity.auth_sessions (
    id character varying(36) NOT NULL,
    user_id character varying(36) NOT NULL,
    refresh_token_hash character varying(64) NOT NULL,
    user_agent text,
    ip_address character varying(64),
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    last_used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: identity; Owner: -
--

CREATE TABLE identity.users (
    id character varying(36) NOT NULL,
    full_name character varying(120) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'vendor'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: catalog_alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: identity_alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identity_alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: vendor_alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: stores; Type: TABLE; Schema: vendor; Owner: -
--

CREATE TABLE vendor.stores (
    id character varying(36) NOT NULL,
    owner_id character varying(36) NOT NULL,
    name character varying(120) NOT NULL,
    slug character varying(140) NOT NULL,
    description character varying(500) NOT NULL,
    contact_email character varying(255) NOT NULL,
    phone character varying(40),
    logo_url character varying(255),
    banner_url character varying(255),
    status character varying(40) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: categories categories_slug_key; Type: CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.categories
    ADD CONSTRAINT categories_slug_key UNIQUE (slug);


--
-- Name: orders orders_payment_reference_key; Type: CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.orders
    ADD CONSTRAINT orders_payment_reference_key UNIQUE (payment_reference);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: products products_slug_key; Type: CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.products
    ADD CONSTRAINT products_slug_key UNIQUE (slug);


--
-- Name: auth_sessions auth_sessions_pkey; Type: CONSTRAINT; Schema: identity; Owner: -
--

ALTER TABLE ONLY identity.auth_sessions
    ADD CONSTRAINT auth_sessions_pkey PRIMARY KEY (id);


--
-- Name: auth_sessions auth_sessions_refresh_token_hash_key; Type: CONSTRAINT; Schema: identity; Owner: -
--

ALTER TABLE ONLY identity.auth_sessions
    ADD CONSTRAINT auth_sessions_refresh_token_hash_key UNIQUE (refresh_token_hash);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: identity; Owner: -
--

ALTER TABLE ONLY identity.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: identity; Owner: -
--

ALTER TABLE ONLY identity.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: catalog_alembic_version catalog_alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_alembic_version
    ADD CONSTRAINT catalog_alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: identity_alembic_version identity_alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identity_alembic_version
    ADD CONSTRAINT identity_alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: vendor_alembic_version vendor_alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_alembic_version
    ADD CONSTRAINT vendor_alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: vendor; Owner: -
--

ALTER TABLE ONLY vendor.stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (id);


--
-- Name: stores stores_slug_key; Type: CONSTRAINT; Schema: vendor; Owner: -
--

ALTER TABLE ONLY vendor.stores
    ADD CONSTRAINT stores_slug_key UNIQUE (slug);


--
-- Name: ix_catalog_categories_slug; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_categories_slug ON catalog.categories USING btree (slug);


--
-- Name: ix_catalog_orders_buyer_email; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_orders_buyer_email ON catalog.orders USING btree (buyer_email);


--
-- Name: ix_catalog_orders_owner_id; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_orders_owner_id ON catalog.orders USING btree (owner_id);


--
-- Name: ix_catalog_orders_payment_reference; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_orders_payment_reference ON catalog.orders USING btree (payment_reference);


--
-- Name: ix_catalog_orders_product_id; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_orders_product_id ON catalog.orders USING btree (product_id);


--
-- Name: ix_catalog_orders_store_id; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_orders_store_id ON catalog.orders USING btree (store_id);


--
-- Name: ix_catalog_products_category_id; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_products_category_id ON catalog.products USING btree (category_id);


--
-- Name: ix_catalog_products_owner_id; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_products_owner_id ON catalog.products USING btree (owner_id);


--
-- Name: ix_catalog_products_slug; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_products_slug ON catalog.products USING btree (slug);


--
-- Name: ix_catalog_products_store_id; Type: INDEX; Schema: catalog; Owner: -
--

CREATE INDEX ix_catalog_products_store_id ON catalog.products USING btree (store_id);


--
-- Name: ix_identity_auth_sessions_refresh_token_hash; Type: INDEX; Schema: identity; Owner: -
--

CREATE INDEX ix_identity_auth_sessions_refresh_token_hash ON identity.auth_sessions USING btree (refresh_token_hash);


--
-- Name: ix_identity_auth_sessions_user_id; Type: INDEX; Schema: identity; Owner: -
--

CREATE INDEX ix_identity_auth_sessions_user_id ON identity.auth_sessions USING btree (user_id);


--
-- Name: ix_identity_users_email; Type: INDEX; Schema: identity; Owner: -
--

CREATE INDEX ix_identity_users_email ON identity.users USING btree (email);


--
-- Name: ix_vendor_stores_owner_id; Type: INDEX; Schema: vendor; Owner: -
--

CREATE INDEX ix_vendor_stores_owner_id ON vendor.stores USING btree (owner_id);


--
-- Name: ix_vendor_stores_slug; Type: INDEX; Schema: vendor; Owner: -
--

CREATE INDEX ix_vendor_stores_slug ON vendor.stores USING btree (slug);


--
-- Name: orders orders_product_id_fkey; Type: FK CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.orders
    ADD CONSTRAINT orders_product_id_fkey FOREIGN KEY (product_id) REFERENCES catalog.products(id) ON DELETE RESTRICT;


--
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: catalog; Owner: -
--

ALTER TABLE ONLY catalog.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES catalog.categories(id) ON DELETE RESTRICT;


--
-- Name: auth_sessions auth_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: identity; Owner: -
--

ALTER TABLE ONLY identity.auth_sessions
    ADD CONSTRAINT auth_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES identity.users(id) ON DELETE CASCADE;

