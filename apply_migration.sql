-- Apply account deletion requests migration to remote Supabase
-- Copy and paste this into your Supabase SQL Editor

-- Create account_deletion_requests table
CREATE TABLE IF NOT EXISTS account_deletion_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  scheduled_deletion_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'cancelled', 'processing', 'completed')) NOT NULL,
  reason TEXT,
  admin_notes TEXT,
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- No constraint here - we'll use a partial unique index instead
);

-- Add index for efficient queries
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_user_id ON account_deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_status ON account_deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_scheduled_date ON account_deletion_requests(scheduled_deletion_date);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_requested_at ON account_deletion_requests(requested_at);

-- Ensure only one pending deletion request per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_pending_deletion_request 
ON account_deletion_requests(user_id) 
WHERE status = 'pending';

-- Enable Row Level Security
ALTER TABLE account_deletion_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own deletion requests" ON account_deletion_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own deletion requests" ON account_deletion_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pending deletion requests" ON account_deletion_requests
  FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

-- Create function to automatically set scheduled_deletion_date to 30 days from now
CREATE OR REPLACE FUNCTION set_deletion_schedule_date()
RETURNS TRIGGER AS $$
BEGIN
  -- Set scheduled deletion date to 30 days from now
  NEW.scheduled_deletion_date = NOW() + INTERVAL '30 days';
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set scheduled deletion date
CREATE OR REPLACE TRIGGER on_deletion_request_insert
  BEFORE INSERT ON account_deletion_requests
  FOR EACH ROW EXECUTE FUNCTION set_deletion_schedule_date();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_deletion_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE OR REPLACE TRIGGER on_deletion_request_update
  BEFORE UPDATE ON account_deletion_requests
  FOR EACH ROW EXECUTE FUNCTION update_deletion_request_updated_at();

