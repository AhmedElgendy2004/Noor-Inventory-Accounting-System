-- Fix missing column in product_pricing_tiers table
-- The code expects a 'price' column for the tier price.

CREATE TABLE IF NOT EXISTS product_pricing_tiers (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id uuid REFERENCES products(id) ON DELETE CASCADE,
    min_quantity integer NOT NULL,
    price numeric NOT NULL,
    tier_name text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- In case the table exists but is missing the column (e.g. named differently or forgotten)
ALTER TABLE product_pricing_tiers ADD COLUMN IF NOT EXISTS price numeric;
ALTER TABLE product_pricing_tiers ADD COLUMN IF NOT EXISTS tier_name text;
ALTER TABLE product_pricing_tiers ADD COLUMN IF NOT EXISTS min_quantity integer;
ALTER TABLE product_pricing_tiers ADD COLUMN IF NOT EXISTS product_id uuid REFERENCES products(id) ON DELETE CASCADE;

COMMENT ON COLUMN product_pricing_tiers.price IS 'The total price for the tier quantity (or unit price depending on business logic)';
