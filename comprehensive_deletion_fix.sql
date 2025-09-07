-- Comprehensive fix for account deletion cancellation issues
-- Run this in your Supabase SQL Editor

-- Step 1: Drop the problematic constraint if it exists
ALTER TABLE account_deletion_requests DROP CONSTRAINT IF EXISTS unique_active_deletion_request;

-- Step 2: Create a partial unique index that only applies to pending requests
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_pending_deletion_request 
ON account_deletion_requests(user_id) 
WHERE status = 'pending';

-- Step 3: Check and fix RLS policies for account_deletion_requests
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own deletion requests" ON account_deletion_requests;
DROP POLICY IF EXISTS "Users can create their own deletion requests" ON account_deletion_requests;
DROP POLICY IF EXISTS "Users can update their own pending deletion requests" ON account_deletion_requests;

-- Recreate RLS policies with proper permissions
CREATE POLICY "Users can view their own deletion requests" ON account_deletion_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own deletion requests" ON account_deletion_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own deletion requests" ON account_deletion_requests
  FOR UPDATE USING (auth.uid() = user_id);

-- Step 4: Verify the table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'account_deletion_requests' 
ORDER BY ordinal_position;

-- Step 5: Check existing constraints and indexes
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'account_deletion_requests'::regclass;

-- Step 6: Check indexes
SELECT 
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'account_deletion_requests';
