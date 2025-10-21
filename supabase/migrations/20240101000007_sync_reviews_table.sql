-- Migration: Sync reviews table with current Supabase schema
-- Update reviews table structure to match the actual database

-- Add missing fields to reviews table
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS conversation_id uuid;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS availability_id uuid;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS meeting_date date;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS meeting_location text;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS is_pending boolean DEFAULT false;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS review_trigger_date timestamp with time zone;

-- Add reviewed_role column (different from reviewer_role)
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS reviewed_role text;

-- Add foreign key constraints
ALTER TABLE reviews ADD CONSTRAINT reviews_conversation_id_fkey 
FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);

ALTER TABLE reviews ADD CONSTRAINT reviews_availability_id_fkey 
FOREIGN KEY (availability_id) REFERENCES public.availability(id);

-- Update reviewer_role constraint to match Supabase schema (owner, walker instead of requester, recipient)
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_reviewer_role_check;
ALTER TABLE reviews ADD CONSTRAINT reviews_reviewer_role_check 
CHECK (reviewer_role = ANY (ARRAY['owner'::text, 'walker'::text]));

-- Add constraint for status
ALTER TABLE reviews ADD CONSTRAINT reviews_status_check 
CHECK (status = ANY (ARRAY['active'::text, 'hidden'::text, 'deleted'::text]));

-- Update existing records to have proper reviewer_role and reviewed_role values
-- This is a best-effort mapping - you may need to adjust based on your data
UPDATE reviews SET 
    reviewer_role = CASE 
        WHEN reviewer_role = 'requester' THEN 'owner'
        WHEN reviewer_role = 'recipient' THEN 'walker'
        ELSE reviewer_role
    END,
    reviewed_role = CASE 
        WHEN reviewer_role = 'requester' THEN 'walker'
        WHEN reviewer_role = 'recipient' THEN 'owner'
        ELSE 'owner'
    END
WHERE reviewer_role IN ('requester', 'recipient');

-- Make reviewed_role NOT NULL after populating
ALTER TABLE reviews ALTER COLUMN reviewed_role SET NOT NULL;

-- Add comments to describe the new columns
COMMENT ON COLUMN reviews.conversation_id IS 'Reference to the conversation this review is about';
COMMENT ON COLUMN reviews.availability_id IS 'Reference to the availability post this review is about';
COMMENT ON COLUMN reviews.meeting_date IS 'Date when the meeting took place';
COMMENT ON COLUMN reviews.meeting_location IS 'Location where the meeting took place';
COMMENT ON COLUMN reviews.status IS 'Status of the review (active, hidden, deleted)';
COMMENT ON COLUMN reviews.is_pending IS 'Whether this review is pending completion';
COMMENT ON COLUMN reviews.review_trigger_date IS 'When the review was triggered';
COMMENT ON COLUMN reviews.reviewed_role IS 'Role of the person being reviewed (owner, walker)';

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_conversation_id ON reviews(conversation_id);
CREATE INDEX IF NOT EXISTS idx_reviews_availability_id ON reviews(availability_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);
CREATE INDEX IF NOT EXISTS idx_reviews_is_pending ON reviews(is_pending);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewed_role ON reviews(reviewed_role);
CREATE INDEX IF NOT EXISTS idx_reviews_meeting_date ON reviews(meeting_date);

-- Verify the migration
SELECT 
    'Reviews table sync completed successfully' as status,
    COUNT(*) as total_reviews,
    COUNT(CASE WHEN conversation_id IS NOT NULL THEN 1 END) as reviews_with_conversation,
    COUNT(CASE WHEN availability_id IS NOT NULL THEN 1 END) as reviews_with_availability,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_reviews,
    COUNT(CASE WHEN is_pending = true THEN 1 END) as pending_reviews
FROM reviews;
