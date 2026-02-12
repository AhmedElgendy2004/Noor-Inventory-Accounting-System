-- 1. Create Profiles Table (Admin Approval System)
create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  phone text unique,
  is_approved boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (id)
);

-- Secure Profiles: Users can read their own profile.
alter table public.profiles enable row level security;

create policy "Users can view own profile"
on public.profiles for select
to authenticated
using ( auth.uid() = id );

-- Optional: Allow users to insert their own profile during signup trigger
-- Better approach: Use a Database Trigger on auth.users (See step 4)

-- 2. Add Multi-tenancy to Tables
-- Products
alter table public.products 
add column if not exists user_id uuid references auth.users(id) default auth.uid();

alter table public.products enable row level security;

-- Categories
alter table public.categories 
add column if not exists user_id uuid references auth.users(id) default auth.uid();

alter table public.categories enable row level security;

-- Sales Invoices
alter table public.sales_invoices 
add column if not exists user_id uuid references auth.users(id) default auth.uid();

alter table public.sales_invoices enable row level security;

-- Sale Items (Details)
alter table public.sale_items 
add column if not exists user_id uuid references auth.users(id) default auth.uid();

alter table public.sale_items enable row level security;

-- Suppliers
alter table public.suppliers 
add column if not exists user_id uuid references auth.users(id) default auth.uid();

alter table public.suppliers enable row level security;

-- Customers
alter table public.customers 
add column if not exists user_id uuid references auth.users(id) default auth.uid();

alter table public.customers enable row level security;

-- 3. RLS Policies (Strict Multi-tenancy + Approval Check)

-- Helper function to check if user is approved
create or replace function public.is_approved_user()
returns boolean as $$
declare
  approved boolean;
begin
  select is_approved into approved from public.profiles where id = auth.uid();
  return coalesce(approved, false);
end;
$$ language plpgsql security definer;

-- Policy Generator for common tables
-- Note: 'using' is for SELECT/UPDATE/DELETE filters. 'with check' is for INSERT/UPDATE new rows.

-- Products Policies
create policy "Enable all access for approved owners" on public.products
to authenticated
using ( (auth.uid() = user_id) AND is_approved_user() )
with check ( (auth.uid() = user_id) AND is_approved_user() );

-- Categories Policies
create policy "Enable all access for approved owners" on public.categories
to authenticated
using ( (auth.uid() = user_id) AND is_approved_user() )
with check ( (auth.uid() = user_id) AND is_approved_user() );

-- Sales Policies
create policy "Enable all access for approved owners" on public.sales_invoices
to authenticated
using ( (auth.uid() = user_id) AND is_approved_user() )
with check ( (auth.uid() = user_id) AND is_approved_user() );

create policy "Enable all access for approved owners" on public.sale_items
to authenticated
using ( (auth.uid() = user_id) AND is_approved_user() )
with check ( (auth.uid() = user_id) AND is_approved_user() );

-- 4. Auto-Profile Creation Trigger (Optional but recommended)
-- This ensures a profile exists when a user signs up via Auth API
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, phone, is_approved)
  values (new.id, new.phone, false); -- Default is Not Approved
  return new;
end;
$$ language plpgsql security definer;

-- Trigger logic needs to be attached to auth.users which is restricted in Supabase dashboard SQL mostly.
-- Pass the previous SQL manually.

-- 5. IMPORTANT: For existing data, you might want to assign it to a specific admin ID.
-- UPDATE public.products SET user_id = 'YOUR_ADMIN_UUID' WHERE user_id IS NULL;

-- 6. SECURE RPC: Update 'create_sale_transaction' to support Multi-tenancy
-- Original RPC was 'security definer' which bypasses RLS. We must manually enforce user_id checks.

create or replace function create_sale_transaction(
  p_invoice jsonb,
  p_items jsonb
) returns uuid
security definer
set search_path = public
as $$
declare
  v_invoice_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity int;
  v_price_at_sale numeric;
  v_price_type text;
  v_inv_num text;
  v_user_id uuid;
begin
  -- Get Current User
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not Authenticated';
  end if;

  -- Generate Invoice Number if not provided
  v_inv_num := p_invoice->>'invoice_number';
  if v_inv_num is null then
    -- Generate Text-based Invoice Number: YYYY-MM-DD-HHMMSS
    v_inv_num := to_char(now(), 'YYYY-MM-DD-HH24MISS');
  end if;

  -- Insert Invoice with user_id
  insert into sales_invoices (
    invoice_number,
    customer_id,
    payment_type,
    total_amount,
    paid_amount,
    user_id, -- Explicitly set owner
    created_at
  ) values (
    v_inv_num,
    (p_invoice->>'customer_id')::uuid,
    p_invoice->>'payment_type',
    (p_invoice->>'total_amount')::numeric,
    (p_invoice->>'paid_amount')::numeric,
    v_user_id,
    now()
  )
  returning id into v_invoice_id;

  -- Loop through items
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_product_id := (v_item->>'product_id')::uuid;
    v_quantity := (v_item->>'quantity')::int;
    v_price_at_sale := (v_item->>'price_at_sale')::numeric;
    v_price_type := v_item->>'price_type';

    -- Insert Sale Item with user_id
    insert into sale_items (
      invoice_id,
      product_id,
      quantity,
      price_at_sale,
      price_type,
      user_id
    ) values (
      v_invoice_id,
      v_product_id,
      v_quantity,
      v_price_at_sale,
      v_price_type,
      v_user_id
    );

    -- Decrement Stock (Securely: Only if product belongs to user)
    update products
    set stock_quantity = stock_quantity - v_quantity
    where id = v_product_id AND user_id = v_user_id;
    
    -- Optional: Check if update actually happened (row count) to detect access violation
    if not found then
       -- Either product doesn't exist or doesn't belong to user. 
       -- We might want to raise exception or ignore. 
       -- For data integrity, raising exception is safer.
       raise exception 'Product % not found or access denied', v_product_id;
    end if;
  end loop;

  return v_invoice_id;
end;
$$ language plpgsql;
