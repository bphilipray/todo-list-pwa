export type Quadrant = 
  | 'urgent-important'
  | 'not-urgent-important'
  | 'urgent-not-important'
  | 'not-urgent-not-important';

export interface Task {
  id: string;
  title: string;
  description?: string;
  quadrant: Quadrant;
  completed: boolean;
  createdAt: number;
  dueDate?: number;
  dueTime?: string; // Format: "HH:mm"
  timezone?: string; // IANA timezone (e.g., "America/New_York")
}