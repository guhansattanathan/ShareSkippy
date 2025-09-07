import fs from 'fs';
import path from 'path';
import { sendEmail } from './resend.js';
import config from '@/config';

// Email template paths
const TEMPLATE_PATHS = {
  welcome: './email-templates/welcome-email.html',
  newMessage: './email-templates/new-message-notification.html',
  meetingScheduled: './email-templates/meeting-scheduled-confirmation.html',
  meetingReminder: './email-templates/meeting-reminder-1day.html',
  followUp: './email-templates/follow-up-1week.html',
};

/**
 * Load and process email template with variables
 * @param {string} templatePath - Path to the HTML template
 * @param {Object} variables - Variables to replace in the template
 * @returns {string} Processed HTML content
 */
function loadTemplate(templatePath, variables = {}) {
  try {
    const fullPath = path.resolve(templatePath);
    let html = fs.readFileSync(fullPath, 'utf8');
    
    // Replace variables in the template
    Object.entries(variables).forEach(([key, value]) => {
      const regex = new RegExp(`{{${key}}}`, 'g');
      html = html.replace(regex, value || '');
    });
    
    return html;
  } catch (error) {
    console.error(`Error loading template ${templatePath}:`, error);
    throw new Error(`Failed to load email template: ${templatePath}`);
  }
}

/**
 * Send welcome email to new users
 * @param {Object} params
 * @param {string} params.to - Recipient email
 * @param {string} params.userName - User's name
 * @param {string} params.appUrl - App URL
 */
export async function sendWelcomeEmail({ to, userName, appUrl = config.domainName }) {
  const html = loadTemplate(TEMPLATE_PATHS.welcome, {
    userName,
    appUrl: `https://${appUrl}`,
  });

  const text = `Welcome to ShareSkippy, ${userName}!

We're thrilled to have you join our community of dog lovers! ShareSkippy is all about connecting dog owners and dog enthusiasts to create amazing experiences together.

Here's what you can do on ShareSkippy:
- Schedule Playdates: Connect with other dog owners for fun meetups
- Chat & Connect: Message fellow dog lovers in your area
- Share Reviews: Rate experiences and help others find great connections
- Discover Places: Find dog-friendly spots and share your favorites
- Share Availability: Let others know when you're available for dog activities

Start exploring: https://${appUrl}

Happy tails and wagging adventures,
The ShareSkippy Team 🐕`;

  return await sendEmail({
    to,
    subject: `Welcome to ShareSkippy, ${userName}! 🐕`,
    html,
    text,
  });
}

/**
 * Send new message notification email
 * @param {Object} params
 * @param {string} params.to - Recipient email
 * @param {string} params.recipientName - Recipient's name
 * @param {string} params.senderName - Sender's name
 * @param {string} params.senderInitial - Sender's initial for avatar
 * @param {string} params.messagePreview - Preview of the message
 * @param {string} params.messageTime - When the message was sent
 * @param {string} params.messageUrl - URL to view the message
 * @param {string} params.appUrl - App URL
 */
export async function sendNewMessageNotification({
  to,
  recipientName,
  senderName,
  senderInitial,
  messagePreview,
  messageTime,
  messageUrl,
  appUrl = config.domainName,
}) {
  const html = loadTemplate(TEMPLATE_PATHS.newMessage, {
    recipientName,
    senderName,
    senderInitial,
    messagePreview,
    messageTime,
    messageUrl,
    appUrl: `https://${appUrl}`,
  });

  const text = `New message from ${senderName} on ShareSkippy!

Hi ${recipientName},

You've received a new message on ShareSkippy:

"${messagePreview}"

View and reply: ${messageUrl}

Happy chatting,
The ShareSkippy Team 🐕`;

  return await sendEmail({
    to,
    subject: `New message from ${senderName} on ShareSkippy 💬`,
    html,
    text,
  });
}

/**
 * Send meeting scheduled confirmation email
 * @param {Object} params
 * @param {string} params.to - Recipient email
 * @param {string} params.userName - User's name
 * @param {string} params.userDogName - User's dog name
 * @param {string} params.otherUserName - Other user's name
 * @param {string} params.otherUserDogName - Other user's dog name
 * @param {string} params.meetingDate - Meeting date
 * @param {string} params.meetingTime - Meeting time
 * @param {string} params.meetingLocation - Meeting location
 * @param {string} params.meetingNotes - Optional meeting notes
 * @param {string} params.meetingUrl - URL to view meeting details
 * @param {string} params.messageUrl - URL to message the other user
 * @param {string} params.appUrl - App URL
 */
export async function sendMeetingScheduledConfirmation({
  to,
  userName,
  userDogName,
  otherUserName,
  otherUserDogName,
  meetingDate,
  meetingTime,
  meetingLocation,
  meetingNotes = '',
  meetingUrl,
  messageUrl,
  appUrl = config.domainName,
}) {
  const html = loadTemplate(TEMPLATE_PATHS.meetingScheduled, {
    userName,
    userDogName,
    otherUserName,
    otherUserDogName,
    meetingDate,
    meetingTime,
    meetingLocation,
    meetingNotes,
    meetingUrl,
    messageUrl,
    appUrl: `https://${appUrl}`,
  });

  const text = `Meeting Confirmed! Your dog playdate is scheduled.

Hi ${userName},

Great news! Your meeting with ${otherUserName} has been successfully scheduled.

Meeting Details:
- Date: ${meetingDate}
- Time: ${meetingTime}
- Location: ${meetingLocation}
- With: ${otherUserName} & ${otherUserDogName}
${meetingNotes ? `- Notes: ${meetingNotes}` : ''}

View meeting details: ${meetingUrl}
Message ${otherUserName}: ${messageUrl}

Happy tails and wagging adventures,
The ShareSkippy Team 🐕`;

  return await sendEmail({
    to,
    subject: `Meeting Confirmed! Playdate with ${otherUserName} 🎉`,
    html,
    text,
  });
}

/**
 * Send meeting reminder email (1 day before)
 * @param {Object} params
 * @param {string} params.to - Recipient email
 * @param {string} params.userName - User's name
 * @param {string} params.userDogName - User's dog name
 * @param {string} params.otherUserName - Other user's name
 * @param {string} params.otherUserDogName - Other user's dog name
 * @param {string} params.meetingDate - Meeting date
 * @param {string} params.meetingTime - Meeting time
 * @param {string} params.meetingLocation - Meeting location
 * @param {string} params.meetingNotes - Optional meeting notes
 * @param {string} params.meetingUrl - URL to view meeting details
 * @param {string} params.messageUrl - URL to message the other user
 * @param {string} params.appUrl - App URL
 */
export async function sendMeetingReminder({
  to,
  userName,
  userDogName,
  otherUserName,
  otherUserDogName,
  meetingDate,
  meetingTime,
  meetingLocation,
  meetingNotes = '',
  meetingUrl,
  messageUrl,
  appUrl = config.domainName,
}) {
  const html = loadTemplate(TEMPLATE_PATHS.meetingReminder, {
    userName,
    userDogName,
    otherUserName,
    otherUserDogName,
    meetingDate,
    meetingTime,
    meetingLocation,
    meetingNotes,
    meetingUrl,
    messageUrl,
    appUrl: `https://${appUrl}`,
  });

  const text = `Reminder: Your dog playdate is tomorrow!

Hi ${userName},

Just a friendly reminder that your meeting with ${otherUserName} is scheduled for tomorrow.

Meeting Details:
- Date: ${meetingDate} (Tomorrow!)
- Time: ${meetingTime}
- Location: ${meetingLocation}
- With: ${otherUserName} & ${otherUserDogName}
${meetingNotes ? `- Notes: ${meetingNotes}` : ''}

View meeting details: ${meetingUrl}
Message ${otherUserName}: ${messageUrl}

Excited for tomorrow's adventure,
The ShareSkippy Team 🐕`;

  return await sendEmail({
    to,
    subject: `Reminder: Playdate with ${otherUserName} tomorrow! ⏰`,
    html,
    text,
  });
}

/**
 * Send follow-up email (1 week after signup)
 * @param {Object} params
 * @param {string} params.to - Recipient email
 * @param {string} params.userName - User's name
 * @param {string} params.userDogName - User's dog name
 * @param {number} params.profileViews - Number of profile views
 * @param {number} params.messagesReceived - Number of messages received
 * @param {number} params.meetingsScheduled - Number of meetings scheduled
 * @param {number} params.connectionsMade - Number of connections made
 * @param {string} params.appUrl - App URL
 */
export async function sendFollowUpEmail({
  to,
  userName,
  userDogName,
  profileViews = 0,
  messagesReceived = 0,
  meetingsScheduled = 0,
  connectionsMade = 0,
  appUrl = config.domainName,
}) {
  const html = loadTemplate(TEMPLATE_PATHS.followUp, {
    userName,
    userDogName,
    profileViews,
    messagesReceived,
    meetingsScheduled,
    connectionsMade,
    appUrl: `https://${appUrl}`,
  });

  const text = `How's ShareSkippy going? - 1 Week Check-in

Hey ${userName},

It's been a week since you joined our community! Here's how you're doing:

- Profile Views: ${profileViews}
- Messages: ${messagesReceived}
- Meetings: ${meetingsScheduled}
- Connections: ${connectionsMade}

Continue exploring: https://${appUrl}
Update your profile: https://${appUrl}/profile/edit

We'd love to hear from you! Reply to this email and let us know how your first week has been.

Wagging tails and happy adventures,
The ShareSkippy Team 🐕`;

  return await sendEmail({
    to,
    subject: `How's ShareSkippy going? - 1 Week Check-in 📅`,
    html,
    text,
  });
}

// Export all email functions
export const emailTemplates = {
  sendWelcomeEmail,
  sendNewMessageNotification,
  sendMeetingScheduledConfirmation,
  sendMeetingReminder,
  sendFollowUpEmail,
};
