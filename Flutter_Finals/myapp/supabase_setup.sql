-- =============================================
-- ApliMart - Supabase Database Setup (v2)
-- Run this in Supabase → SQL Editor
-- =============================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Clear existing products so the table starts fresh
delete from public.products;

-- ─────────────────────────────────────────────
-- HELPER: check if current user is admin
-- ─────────────────────────────────────────────
-- Used in RLS policies so admins can see/update all rows.

-- ─────────────────────────────────────────────
-- TABLES
-- ─────────────────────────────────────────────

create table if not exists public.products (
  id             uuid          default uuid_generate_v4() primary key,
  name           text          not null,
  description    text,
  price          numeric(10,2) not null,
  original_price numeric(10,2),
  category       text          not null,
  image_url      text,
  rating         numeric(3,2)  default 0,
  review_count   integer       default 0,
  stock          integer       default 0,
  free_shipping  boolean       default false,
  is_featured    boolean       default false,
  sold_count     integer       default 0,
  created_at     timestamptz   default now()
);

create table if not exists public.profiles (
  id          uuid        references auth.users(id) primary key,
  name        text,
  phone       text,
  avatar_url  text,
  address     text,
  updated_at  timestamptz default now()
);

-- ── Orders (corrected schema matching the Flutter app) ────────────────────
-- The app inserts: id, user_id, total_amount, subtotal, shipping_fee,
--   status, address, payment_method, items (jsonb), created_at
-- Drop and recreate if you previously ran the old schema.

drop table if exists public.order_items;
drop table if exists public.orders;

create table public.orders (
  id                  uuid          default uuid_generate_v4() primary key,
  user_id             uuid          references auth.users(id) on delete cascade,
  total_amount        numeric(10,2) not null default 0,
  subtotal            numeric(10,2) not null default 0,
  shipping_fee        numeric(10,2) not null default 0,
  vat_amount          numeric(10,2) not null default 0,
  status              text          not null default 'pending',
  address             text          not null default '',
  payment_method      text          not null default 'Cash on Delivery',
  items               jsonb         not null default '[]',
  rider_id            uuid          references auth.users(id),
  cancellation_reason text,
  created_at          timestamptz   default now()
);

-- Add columns to existing orders table if upgrading from an older schema
alter table public.orders
  add column if not exists vat_amount numeric(10,2) not null default 0;
alter table public.orders
  add column if not exists rider_id uuid references auth.users(id);
alter table public.orders
  add column if not exists cancellation_reason text;

-- ── Notifications ─────────────────────────────────────────────────────────

create table if not exists public.notifications (
  id         uuid      default gen_random_uuid() primary key,
  user_id    uuid      not null references auth.users(id) on delete cascade,
  order_id   text      not null default '',
  type       text      not null,
  title      text      not null,
  body       text      not null,
  is_read    boolean   not null default false,
  created_at timestamptz default now()
);

-- ── Messages (customer support chat) ─────────────────────────────────────

create table if not exists public.messages (
  id         uuid      default gen_random_uuid() primary key,
  user_id    uuid      not null references auth.users(id) on delete cascade,
  user_name  text      not null default 'User',
  sender     text      not null default 'user',  -- 'user' or 'support'
  content    text      not null,
  created_at timestamptz default now()
);

-- ─────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ─────────────────────────────────────────────

alter table public.products      enable row level security;
alter table public.profiles      enable row level security;
alter table public.orders        enable row level security;
alter table public.notifications enable row level security;
alter table public.messages      enable row level security;

-- ── Products: public read, admin write ───────────────────────────────────

drop policy if exists "Products are viewable by everyone" on public.products;
create policy "Products are viewable by everyone"
  on public.products for select using (true);

drop policy if exists "Admins can insert products" on public.products;
create policy "Admins can insert products"
  on public.products for insert
  with check (
    (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products"
  on public.products for update
  using (
    (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

drop policy if exists "Admins can delete products" on public.products;
create policy "Admins can delete products"
  on public.products for delete
  using (
    (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

-- ── Profiles: own row only ────────────────────────────────────────────────

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- ── Orders: users see own, admins see all ────────────────────────────────

drop policy if exists "Users can view own orders" on public.orders;
create policy "Users can view own orders"
  on public.orders for select
  using (
    auth.uid() = user_id
    or (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

drop policy if exists "Users can create orders" on public.orders;
create policy "Users can create orders"
  on public.orders for insert
  with check (auth.uid() = user_id);

drop policy if exists "Admins can update order status" on public.orders;
create policy "Admins can update order status"
  on public.orders for update
  using (
    (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

-- ── Orders: riders see available + their own assigned orders ─────────────

drop policy if exists "Riders view available orders" on public.orders;
create policy "Riders view available orders"
  on public.orders for select
  using (
    status = 'processing' and rider_id is null
  );

drop policy if exists "Riders view assigned orders" on public.orders;
create policy "Riders view assigned orders"
  on public.orders for select
  using (
    rider_id = auth.uid()
  );

drop policy if exists "Riders update assigned orders" on public.orders;
create policy "Riders update assigned orders"
  on public.orders for update
  using (
    rider_id = auth.uid()
    or (rider_id is null and status = 'processing')
  )
  with check (
    rider_id = auth.uid()
  );

-- ── Notifications: users read own, service can insert ────────────────────

drop policy if exists "users read own notifications" on public.notifications;
create policy "users read own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

drop policy if exists "service insert notifications" on public.notifications;
create policy "service insert notifications"
  on public.notifications for insert
  with check (true);

drop policy if exists "users mark notifications read" on public.notifications;
create policy "users mark notifications read"
  on public.notifications for update
  using (auth.uid() = user_id);

drop policy if exists "admins read all notifications" on public.notifications;
create policy "admins read all notifications"
  on public.notifications for select
  using (
    (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

-- ── Messages: users read own, admins read all ────────────────────────────

drop policy if exists "users read own messages" on public.messages;
create policy "users read own messages"
  on public.messages for select
  using (
    auth.uid() = user_id
    or (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

drop policy if exists "users send messages" on public.messages;
create policy "users send messages"
  on public.messages for insert
  with check (auth.uid() = user_id or
    (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

-- ─────────────────────────────────────────────
-- STORAGE BUCKET: product-images
-- ─────────────────────────────────────────────

insert into storage.buckets (id, name, public)
  values ('product-images', 'product-images', true)
  on conflict (id) do nothing;

drop policy if exists "Public read product images" on storage.objects;
create policy "Public read product images"
  on storage.objects for select
  using (bucket_id = 'product-images');

drop policy if exists "Admins upload product images" on storage.objects;
create policy "Admins upload product images"
  on storage.objects for insert
  with check (
    bucket_id = 'product-images'
    and (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

drop policy if exists "Admins delete product images" on storage.objects;
create policy "Admins delete product images"
  on storage.objects for delete
  using (
    bucket_id = 'product-images'
    and (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true
  );

-- ── Product Ratings (one row per user per product) ───────────────────────

create table if not exists public.product_ratings (
  id            uuid          default uuid_generate_v4() primary key,
  user_id       uuid          not null references auth.users(id) on delete cascade,
  product_id    uuid          not null references public.products(id) on delete cascade,
  rating        numeric(2,1)  not null check (rating >= 1 and rating <= 5),
  review_text   text          default '',
  reviewer_name text          default 'Anonymous',
  created_at    timestamptz   default now(),
  unique (user_id, product_id)
);

-- Upgrade existing table (if already created without these columns)
alter table public.product_ratings
  add column if not exists review_text   text default '',
  add column if not exists reviewer_name text default 'Anonymous';

alter table public.product_ratings enable row level security;

-- Public read: anyone can see ratings (needed for product review display)
drop policy if exists "Users view own ratings" on public.product_ratings;
drop policy if exists "Public view all ratings" on public.product_ratings;
create policy "Public view all ratings"
  on public.product_ratings for select
  using (true);

drop policy if exists "Users insert ratings" on public.product_ratings;
create policy "Users insert ratings"
  on public.product_ratings for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users update own ratings" on public.product_ratings;
create policy "Users update own ratings"
  on public.product_ratings for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Add rating_breakdown column to products if upgrading from older schema
alter table public.products
  add column if not exists rating_breakdown jsonb default '{}'::jsonb;

-- ─────────────────────────────────────────────
-- GRANT ADMIN ACCESS
-- After setting up, go to Supabase → Auth → Users → find your admin
-- user → Edit → raw_user_meta_data and add:  {"is_admin": true}
-- ─────────────────────────────────────────────

-- Products table starts empty.
-- Use the Admin → Products tab in the app to add products.
