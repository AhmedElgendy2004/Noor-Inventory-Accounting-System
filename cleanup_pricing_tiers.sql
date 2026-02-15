-- Fix column discrepancies in product_pricing_tiers
-- The Dart code now uses 'total_price' to match the database constraint.
-- This script ensures 'price' is not mandatory if it exists, avoiding double constraints.

DO $$
BEGIN
    -- Check if 'price' column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_pricing_tiers' AND column_name = 'price') THEN
        -- Make it nullable so we don't need to send it
        ALTER TABLE product_pricing_tiers ALTER COLUMN price DROP NOT NULL;
    END IF;
END $$;
