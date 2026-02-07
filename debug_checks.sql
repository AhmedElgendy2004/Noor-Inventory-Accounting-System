// Temporary script to debug permissions and table existence
/*
DO $$
BEGIN
   -- 1. Check if tables exist
   IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename  = 'sales_invoices') THEN
      RAISE EXCEPTION 'Table sales_invoices is missing!';
   END IF;
   
   IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename  = 'sale_items') THEN
      RAISE EXCEPTION 'Table sale_items is missing!';
   END IF;

   -- 2. Check if RPC function exists and takes correct parameters
   IF NOT EXISTS (
       SELECT FROM pg_proc 
       WHERE proname = 'create_sale_transaction'
   ) THEN
      RAISE EXCEPTION 'Function create_sale_transaction is missing!';
   END IF;
   
   RAISE NOTICE 'All checks passed. Tables and Function exist.';
END $$;
*/