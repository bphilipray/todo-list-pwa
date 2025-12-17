// Get user's current timezone
export function detectTimezone(): string {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}

// Common timezones for manual selection
export const COMMON_TIMEZONES = [
  { value: 'America/New_York', label: 'Eastern Time (ET)' },
  { value: 'America/Chicago', label: 'Central Time (CT)' },
  { value: 'America/Denver', label: 'Mountain Time (MT)' },
  { value: 'America/Los_Angeles', label: 'Pacific Time (PT)' },
  { value: 'America/Anchorage', label: 'Alaska Time (AKT)' },
  { value: 'Pacific/Honolulu', label: 'Hawaii Time (HT)' },
  { value: 'Europe/London', label: 'London (GMT/BST)' },
  { value: 'Europe/Paris', label: 'Paris (CET/CEST)' },
  { value: 'Europe/Berlin', label: 'Berlin (CET/CEST)' },
  { value: 'Asia/Dubai', label: 'Dubai (GST)' },
  { value: 'Asia/Kolkata', label: 'India (IST)' },
  { value: 'Asia/Singapore', label: 'Singapore (SGT)' },
  { value: 'Asia/Tokyo', label: 'Tokyo (JST)' },
  { value: 'Asia/Shanghai', label: 'Shanghai (CST)' },
  { value: 'Australia/Sydney', label: 'Sydney (AEDT/AEST)' },
  { value: 'Pacific/Auckland', label: 'Auckland (NZDT/NZST)' },
];

// Format time with timezone
export function formatTimeWithTimezone(time: string, timezone: string): string {
  const [hours, minutes] = time.split(':');
  const date = new Date();
  date.setHours(parseInt(hours), parseInt(minutes), 0, 0);
  
  try {
    return new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      timeZone: timezone,
      hour12: true,
    }).format(date);
  } catch (error) {
    return time;
  }
}

// Get timezone abbreviation
export function getTimezoneAbbreviation(timezone: string): string {
  try {
    const date = new Date();
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone,
      timeZoneName: 'short',
    });
    const parts = formatter.formatToParts(date);
    const timeZonePart = parts.find(part => part.type === 'timeZoneName');
    return timeZonePart?.value || timezone;
  } catch (error) {
    return timezone;
  }
}

// Check if a task is due soon (within next hour)
export function isTaskDueSoon(dueDate?: number, dueTime?: string, timezone?: string): boolean {
  if (!dueDate || !dueTime || !timezone) return false;
  
  try {
    // Parse the task's due date and time in the task's timezone
    const taskDueDate = new Date(dueDate);
    const [hours, minutes] = dueTime.split(':');
    
    // Create a date string in ISO format for the task's timezone
    const year = taskDueDate.getFullYear();
    const month = String(taskDueDate.getMonth() + 1).padStart(2, '0');
    const day = String(taskDueDate.getDate()).padStart(2, '0');
    const timeStr = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;
    
    // Parse this as a date string in the task's timezone
    const dateTimeStr = `${year}-${month}-${day}T${timeStr}`;
    
    // Convert to a timestamp using the Intl API to respect the timezone
    // Create a date in the task's timezone
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false
    });
    
    // Create the task datetime by combining date and time
    const taskDateTime = new Date(taskDueDate);
    taskDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);
    
    const now = new Date();
    const diffMs = taskDateTime.getTime() - now.getTime();
    const diffMinutes = Math.floor(diffMs / 60000);
    
    console.log('Task Due Soon Check:', {
      taskTitle: 'checking',
      taskDateTime: taskDateTime.toISOString(),
      now: now.toISOString(),
      diffMinutes,
      timezone
    });
    
    // Due within next 60 minutes and not in the past
    return diffMinutes > 0 && diffMinutes <= 60;
  } catch (error) {
    console.error('Error checking if task is due soon:', error);
    return false;
  }
}

// Check if a task is overdue
export function isTaskOverdue(dueDate?: number, dueTime?: string, timezone?: string): boolean {
  if (!dueDate || !dueTime || !timezone) return false;
  
  try {
    const [hours, minutes] = dueTime.split(':');
    const taskDate = new Date(dueDate);
    taskDate.setHours(parseInt(hours), parseInt(minutes), 0, 0);
    
    const now = new Date();
    return taskDate.getTime() < now.getTime();
  } catch (error) {
    return false;
  }
}