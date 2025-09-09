import { NextResponse } from 'next/server';
import { createClient } from '@/libs/supabase/server';

export async function POST(request) {
  try {
    const { email } = await request.json();
    
    if (!email) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 });
    }

    const supabase = createClient();
    
    // Find user by email
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('email', email)
      .single();

    if (profileError || !profile) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Send welcome email
    const emailResponse = await fetch(`${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/emails/welcome`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: profile.id })
    });

    const emailResult = await emailResponse.json();

    if (emailResponse.ok) {
      return NextResponse.json({ 
        success: true, 
        message: 'Welcome email sent successfully',
        emailResult 
      });
    } else {
      return NextResponse.json({ 
        error: 'Failed to send welcome email',
        emailResult 
      }, { status: 500 });
    }

  } catch (error) {
    console.error('Error in test welcome email:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
