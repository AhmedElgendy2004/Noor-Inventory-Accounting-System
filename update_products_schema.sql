-- Add new columns for Product properties
ALTER TABLE products ADD COLUMN IF NOT EXISTS color text;
ALTER TABLE products ADD COLUMN IF NOT EXISTS size_volume text;

-- Optional: Add comments to describe columns
COMMENT ON COLUMN products.color IS 'Color of the product (e.g., Red, Blue)';
COMMENT ON COLUMN products.size_volume IS 'Size or Volume of the product (e.g., XL, 500ml)';
