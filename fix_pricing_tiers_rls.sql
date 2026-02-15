-- Enable Row Level Security (RLS) for the table
ALTER TABLE product_pricing_tiers ENABLE ROW LEVEL SECURITY;

-- Policy to allow all authenticated users to View pricing tiers
CREATE POLICY "Enable read access for authenticated users" 
ON product_pricing_tiers FOR SELECT 
TO authenticated 
USING (true);

-- Policy to allow all authenticated users to Insert pricing tiers
CREATE POLICY "Enable insert access for authenticated users" 
ON product_pricing_tiers FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- Policy to allow all authenticated users to Update pricing tiers
CREATE POLICY "Enable update access for authenticated users" 
ON product_pricing_tiers FOR UPDATE 
TO authenticated 
USING (true) 
WITH CHECK (true);

-- Policy to allow all authenticated users to Delete pricing tiers
CREATE POLICY "Enable delete access for authenticated users" 
ON product_pricing_tiers FOR DELETE 
TO authenticated 
USING (true);

-- Optional: If you are testing without login (public access), un-comment below:
-- CREATE POLICY "Enable public access" ON product_pricing_tiers FOR ALL USING (true) WITH CHECK (true);
