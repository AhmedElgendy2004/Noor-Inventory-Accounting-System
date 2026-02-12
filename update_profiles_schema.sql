-- 1. Add columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS full_name text,
ADD COLUMN IF NOT EXISTS shop_name text;

-- 2. Update the Trigger Function to handle metadata
-- This function runs automatically when a new user signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, is_approved, full_name, shop_name)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'phone', 
    false, -- Default is Not Approved
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'shop_name'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-attach the trigger (just in case it wasn't attached or needs refreshing)
-- Note: Dropping a trigger on auth.users usually requires superuser or special perms in dashboard.
-- If this fails, user must copy the function definition above into Dashboard SQL Editor.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
