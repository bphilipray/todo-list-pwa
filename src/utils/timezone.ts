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
  if (!dueDate) return false;

  // Use default timezone if not provided
  const tz = timezone || detectTimezone();

  try {
    const taskDueDate = new Date(dueDate);
    const now = new Date();

    // If time is set, check if due within the next hour
    if (dueTime) {
      const [hours, minutes] = dueTime.split(':');
      const taskDateTime = new Date(taskDueDate);
      taskDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);

      const diffMs = taskDateTime.getTime() - now.getTime();
      const diffMinutes = Math.floor(diffMs / 60000);

      // Due within next 60 minutes and not in the past
      return diffMinutes > 0 && diffMinutes <= 60;
    }

    // If no time set, check if due today and it's past noon (reminder for end of day)
    const isToday = taskDueDate.toDateString() === now.toDateString();
    const isPastNoon = now.getHours() >= 12;

    return isToday && isPastNoon;
  } catch (error) {
    console.error('Error checking if task is due soon:', error);
    return false;
  }
}

// Check if a task is overdue
export function isTaskOverdue(dueDate?: number, dueTime?: string, timezone?: string): boolean {
  if (!dueDate) return false;

  try {
    const taskDate = new Date(dueDate);
    const now = new Date();

    if (dueTime) {
      const [hours, minutes] = dueTime.split(':');
      taskDate.setHours(parseInt(hours), parseInt(minutes), 0, 0);
      return taskDate.getTime() < now.getTime();
    }

    // If no time set, check if the date has passed (compare dates only)
    const taskDateOnly = new Date(taskDate.getFullYear(), taskDate.getMonth(), taskDate.getDate());
    const nowDateOnly = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    return taskDateOnly.getTime() < nowDateOnly.getTime();
  } catch (error) {
    return false;
  }
}