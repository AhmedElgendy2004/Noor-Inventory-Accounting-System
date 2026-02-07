-- ⚠️ IMPORTANT: Run this entire script in the Supabase SQL Editor to fix the schema and function

-- 1. FIX SCHEMA: Change invoice_number from INTEGER to TEXT
-- This is required because we generate formatted invoice numbers like "20260207-1234"
DO $$ 
BEGIN 
    -- Try to alter the column type
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales_invoices' AND column_name = 'invoice_number') THEN
        ALTER TABLE sales_invoices ALTER COLUMN invoice_number TYPE text;
    END IF;
END $$;

-- 2. CREATE/UPDATE FUNCTION
create or replace function create_sale_transaction(
  p_invoice jsonb,
  p_items jsonb
) returns uuid
security definer -- RUNS WITH ADMIN PERMISSIONS (Bypasses RLS)
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
begin
  -- Generate Invoice Number if not provided
  v_inv_num := p_invoice->>'invoice_number';
  if v_inv_num is null then
    -- Generate Text-based Invoice Number: YYYY-MM-DD-HHMMSS (e.g., 2026-02-07-103005)
    -- Added dashes (-) between date parts for readability
    v_inv_num := to_char(now(), 'YYYY-MM-DD-HH24MISS');
  end if;

  -- Insert Invoice
  insert into sales_invoices (
    invoice_number,
    customer_id,
    payment_type,
    total_amount,
    paid_amount,
    created_at
  ) values (
    v_inv_num, -- This is TEXT, so column must be TEXT
    (p_invoice->>'customer_id')::uuid,
    p_invoice->>'payment_type',
    (p_invoice->>'total_amount')::numeric,
    (p_invoice->>'paid_amount')::numeric,
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

    -- Insert Sale Item
    insert into sale_items (
      invoice_id,
      product_id,
      quantity,
      price_at_sale,
      price_type
    ) values (
      v_invoice_id,
      v_product_id,
      v_quantity,
      v_price_at_sale,
      v_price_type
    );

    -- Decrement Stock
    update products
    set stock_quantity = stock_quantity - v_quantity
    where id = v_product_id;
  end loop;

  return v_invoice_id;
end;
$$ language plpgsql;
