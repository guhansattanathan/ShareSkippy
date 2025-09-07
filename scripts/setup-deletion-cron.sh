#!/bin/bash

# Setup script for account deletion processing cron job
# This script helps you set up automated processing of account deletion requests

echo "Setting up account deletion processing cron job..."

# Check if CRON_SECRET_TOKEN is set
if [ -z "$CRON_SECRET_TOKEN" ]; then
    echo "⚠️  CRON_SECRET_TOKEN environment variable is not set."
    echo "Please set a secure random token for cron job authentication:"
    echo "export CRON_SECRET_TOKEN=$(openssl rand -hex 32)"
    echo ""
    echo "Add this to your .env.local file:"
    echo "CRON_SECRET_TOKEN=your_generated_token_here"
    exit 1
fi

# Get the base URL (you may need to adjust this)
BASE_URL=${BASE_URL:-"https://your-domain.com"}

echo "✅ CRON_SECRET_TOKEN is configured"
echo "📡 Base URL: $BASE_URL"
echo ""

# Create cron job entry
CRON_ENTRY="0 2 * * * curl -X POST -H \"Authorization: Bearer $CRON_SECRET_TOKEN\" \"$BASE_URL/api/cron/process-deletions\" >> /var/log/account-deletions.log 2>&1"

echo "Add this cron job entry to your crontab:"
echo "Run: crontab -e"
echo "Add this line:"
echo "$CRON_ENTRY"
echo ""
echo "This will run daily at 2 AM to process deletion requests."
echo ""

# Alternative: GitHub Actions or other CI/CD
echo "Alternative setup options:"
echo ""
echo "1. GitHub Actions (recommended for Vercel/Netlify):"
echo "   Create .github/workflows/process-deletions.yml with:"
echo "   - Schedule: cron: '0 2 * * *'"
echo "   - Call your API endpoint with the secret token"
echo ""
echo "2. Vercel Cron Jobs:"
echo "   Add to vercel.json:"
echo "   {"
echo "     \"crons\": ["
echo "       {"
echo "         \"path\": \"/api/cron/process-deletions\","
echo "         \"schedule\": \"0 2 * * *\""
echo "       }"
echo "     ]"
echo "   }"
echo ""
echo "3. External cron service (cron-job.org, etc.):"
echo "   URL: $BASE_URL/api/cron/process-deletions"
echo "   Method: POST"
echo "   Headers: Authorization: Bearer $CRON_SECRET_TOKEN"
echo "   Schedule: Daily at 2 AM"
echo ""

echo "🔍 To monitor the cron job:"
echo "GET $BASE_URL/api/cron/process-deletions"
echo "This will show pending deletion counts and system status."
echo ""

echo "✅ Setup complete! Remember to:"
echo "1. Set CRON_SECRET_TOKEN in your environment"
echo "2. Configure the cron job using one of the methods above"
echo "3. Test the endpoint manually first"
echo "4. Monitor the logs for any issues"

